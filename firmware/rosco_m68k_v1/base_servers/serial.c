/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2019 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * This is the asynchronous serial driver for the MFP UART.
 * This driver expects that the basic setup of the UART is 
 * done during bootstrap. It does however take care of 
 * registering exception handlers and unmasking the appropriate
 * vectors in the MFP.
 *
 * Once this driver is loaded, the UART should not be used
 * synchronously (i.e. don't call EARLY_PRINT and related
 * bootstrap routines).
 * ------------------------------------------------------------
 */
#include <stdint.h>
#include <stdbool.h>

#include "rosco_m68k.h"
#include "machine.h"
#include "critical.h"
#include "servers/serial.h"
#include "3rdparty/printf.h"

// If these are changed they *must* also be changed in serial_isr.S!
// TODO find a way to not repeat these...
#define BUF_SIZE 4096
#define BUF_MASK ((BUF_SIZE - 1))

static volatile uint8_t * const mfp_rsr = (uint8_t * const)MFP_RSR;
static volatile uint8_t * const mfp_tsr = (uint8_t * const)MFP_TSR;
static volatile uint8_t * const mfp_udr = (uint8_t * const)MFP_UDR;
static volatile uint8_t * const mfp_iera = (uint8_t * const)MFP_IERA;
static volatile uint8_t * const mfp_imra = (uint8_t * const)MFP_IMRA;

volatile uint8_t tx_buffer[BUF_SIZE];
volatile uint8_t rx_buffer[BUF_SIZE];

volatile uint16_t tx_read_pointer = 0;
volatile uint16_t tx_write_pointer = 0;
volatile uint16_t rx_read_pointer = 0;
volatile uint16_t rx_write_pointer = 0;

volatile uint8_t tx_enabled;

static Serial serial;

extern void INIT_SERIAL_HANDLERS();
extern void ENABLE_XMIT();
extern void DISABLE_XMIT();
extern void ENABLE_RECV();
extern void DISABLE_RECV();

static void SendCharImpl(unsigned char ch) {
  CRITICAL_BEGIN();

  if (!tx_enabled) {
    // Just enable transmitter and send character
    ENABLE_XMIT();
    *mfp_udr = ch;
  } else {
    // Buffer this character
    uint16_t wp = tx_write_pointer;
    uint16_t nwp = (wp + 1) & BUF_MASK;
    tx_buffer[wp] = ch;
    tx_write_pointer = nwp;
  }

  CRITICAL_END();
}

static unsigned char BlockingReadCharImpl() {
  ENABLE_RECV();

  while (rx_read_pointer == rx_write_pointer) {
    // spin
  }

  uint16_t ptr = rx_read_pointer;
  
  unsigned char c = rx_buffer[ptr++];

  ptr &= BUF_MASK;
  rx_read_pointer = ptr;
  
  DISABLE_RECV();
  return c;
}

static unsigned char AsyncReadCharImpl() {
  ENABLE_RECV();
  
  unsigned char c;

  if ((*mfp_rsr & 128) == 0) {
    c = 0;
  } else {
    c = *mfp_udr;
  }

  DISABLE_RECV();

  return c;
}

void handleRxError(uint8_t data, uint8_t status) {
  printf("Receiver error: 0x%02x\n", status);
}

void __initializeSerialServer() {
  INIT_SERIAL_HANDLERS();

  // Wait for buffer to empty...
  while ((*mfp_tsr & 128) != 0) { }

  // Start off disabled
  DISABLE_XMIT();
  DISABLE_RECV();
  
  // Enable and unmask USART exceptions (TODO no tx error handler yet!)
  *mfp_iera |= 0x1C;    // bits 2,3,4
  *mfp_imra |= 0x1C;

  serial.SendChar = SendCharImpl;
  serial.BlockingReadChar = BlockingReadCharImpl;
  serial.AsyncReadChar = AsyncReadCharImpl;

  // Register this driver
  KernelApi *api = GetKernelApi();
  api->RegisterLibrary("serial0", ROSCOM68K_SERIAL_MAGIC, &serial);
}


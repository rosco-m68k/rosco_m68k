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
#include "servers/serial.h"

// If these are changed they *must* also be changed in serial_isr.S!
// TODO find a way to not repeat these...
#define BUF_SIZE 4096
#define BUF_MASK ((BUF_SIZE - 1))

static volatile uint8_t * const mfp_tsr = (uint8_t * const)MFP_TSR;
static volatile uint8_t * const mfp_iera = (uint8_t * const)MFP_IERA;
static volatile uint8_t * const mfp_imra = (uint8_t * const)MFP_IMRA;

uint8_t tx_buffer[BUF_SIZE];
uint16_t read_pointer = 0;
uint16_t write_pointer = 0;

static Serial serial;

extern void INIT_SERIAL_HANDLERS();
extern void ENABLE_XMIT();
extern void DISABLE_XMIT();

static void SendCharImpl(unsigned char ch) {
  // N.B Order is important here - can't change write_pointer until valid data in buffer!
  uint16_t wp = write_pointer;
  uint16_t nwp = (wp + 1) & BUF_MASK;
  tx_buffer[wp] = ch;
  write_pointer = nwp;

  // Enable transmitter (if it isn't already)
  ENABLE_XMIT();
}

void __initializeSerialServer() {
  INIT_SERIAL_HANDLERS();

  // Wait for buffer to empty...
  while ((*mfp_tsr & 128) != 0) { }

  // Start off disabled
  DISABLE_XMIT();
  
  // Enable and unmask buffer empty exception
  *mfp_iera |= 4;
  *mfp_imra |= 4;

  serial.SendChar = SendCharImpl;

  // Register this driver
  KernelApi *api = GetKernelApi();
  api->RegisterLibrary("serial0", ROSCOM68K_SERIAL_MAGIC, &serial);
}


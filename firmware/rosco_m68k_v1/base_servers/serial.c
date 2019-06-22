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

typedef void (*buf_empty_func)();

extern buf_empty_func TX_EMPTY_HANDLER;

static volatile uint8_t * const mfp_tsr = (uint8_t * const)MFP_TSR;
static volatile uint8_t * const mfp_iera = (uint8_t * const)MFP_IERA;
static volatile uint8_t * const mfp_imra = (uint8_t * const)MFP_IMRA;

uint8_t tx_buffer[BUF_SIZE];
uint32_t read_pointer = 0;
uint32_t write_pointer = 0;

static Serial serial;

void INIT_SERIAL_HANDLERS();

static void SendCharImpl(unsigned char ch) {
  // N.B Order is important here - can't change write_pointer until valid data in buffer!
  uint32_t wp = write_pointer;
  uint32_t nwp = (wp + 1) & BUF_MASK;
  tx_buffer[wp] = ch;
  write_pointer = nwp;

  // Enable transmitter (if it isn't already)
  ENABLE_XMIT();
}

void __initializeSerialServer() {
  EARLY_PRINT_C("in __initializeSerialServer...\r\n");

  if (write_pointer != 0 || read_pointer != 0) {
    EARLY_PRINT_C("\x1b[1;31mSEVERE\x1b[0m: Write pointers not initialised; BSS not zeroed; Halting.\r\n");
    HALT();
  }

  EARLY_PRINT_C("Setting up buffer handler vector\r\n");

  INIT_SERIAL_HANDLERS();

  EARLY_PRINT_C("Clearing buffer...\r\n");
  // Wait for buffer to empty...
  while ((*mfp_tsr & 128) != 0) { }
  EARLY_PRINT_C("Cleared...\r\n");

  // Enable and unmask buffer empty exception
  EARLY_PRINT_C("Enabling interrupt...\r\n");
  
  *mfp_iera |= 4;
  *mfp_imra |= 4;

  serial.SendChar = SendCharImpl;

  // Register this driver
  KernelApi *api = GetKernelApi();
  api->RegisterLibrary("serial0", ROSCOM68K_SERIAL_MAGIC, &serial);
  
  SendCharImpl('Y');
  SendCharImpl('o');
  SendCharImpl('L');
  SendCharImpl('o');
}



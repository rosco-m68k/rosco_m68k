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
#include "rosco_m68k.h"

void __initializeSerialServer() {
  // KernelApi *api = GetKernelApi();

  // TODO register self
}



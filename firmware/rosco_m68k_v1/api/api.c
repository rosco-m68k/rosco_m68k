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
 * Implementations of the standard Kernel API functions.
 * These should be accessed via the pointer at address 0x4!
 * ------------------------------------------------------------
 */

#include "rosco_m68k.h"
#include "servers/serial.h"

static Serial *serial;

KernelApi* GetKernelApi() {
  return (KernelApi*)0x04;
}

static void* FindLibraryImpl(char *name, uint32_t magic) {
  return serial;
}

static void RegisterLibraryImpl(char *name, uint32_t magic, void *library) {
  serial = library;
}

static KernelApi __kernelApi;

void __initializeKernelApiPtr() {
  __kernelApi.FindLibrary = FindLibraryImpl;
  __kernelApi.RegisterLibrary = RegisterLibraryImpl;

  KernelApi* ptr = (KernelApi*)0x04;
  *ptr = __kernelApi;
}



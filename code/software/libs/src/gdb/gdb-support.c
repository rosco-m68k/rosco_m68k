/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2023 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * GDB debug stub support routines
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <machine.h>

typedef void (*ExceptionHook)(int);

ExceptionHook exceptionHook;

static CharDevice device;
static uint32_t *vector_table = (uint32_t*)0;

void set_debug_traps(void);

bool start_debugger(void) {
    if (!mcCheckDeviceSupport()) {
        return false;
    }

    if (mcGetDeviceCount() < 2) {
        return false;
    }

    if (!mcGetDevice(1, &device)) {
        return false;
    }

    set_debug_traps();
}

int getDebugChar(void) {
    return mcReadDevice(&device);
}

void putDebugChar(int chr) {
    mcSendDevice((char)chr, &device);
}

void exceptionHandler(int exception_number, void *exception_address) {
    vector_table[exception_number] = (uint32_t)exception_address;
}
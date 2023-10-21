/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|         libraries
 * ------------------------------------------------------------
 * Copyright (c)2023 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * GDB debug stub support routines
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <stdbool.h>
#include <machine.h>

typedef void (*ExceptionHook)(int);

ExceptionHook exceptionHook;

static CharDevice device;
static uint32_t *vector_table = (uint32_t*)0;

void set_debug_traps(void);

extern int remote_debug;

bool start_debugger(void) {
    // Set this to 1 for a lot of noisy output that helps debug stuff...
    remote_debug = 0;

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
    return true;
}

int getDebugChar(void) {
    return mcReadDevice(&device);
}

void putDebugChar(int chr) {
    mcSendDevice((char)chr, &device);
}

void exceptionHandler(int exception_number, void (*handler)(void)) {
    if (remote_debug) {
        printf("Set vector 0x%02x to 0x%08lx\n", exception_number, (uint32_t)handler);
    }
    vector_table[exception_number] = (uint32_t)handler;
}
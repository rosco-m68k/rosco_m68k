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
#include <buffered_uart.h>

typedef void (*ExceptionHook)(int);

ExceptionHook exceptionHook;

static CharDevice device;
static uint32_t *vector_table = (uint32_t*)0;

void set_debug_traps(void);

extern int remote_debug;
static RingBuffer uart_b;

bool start_debugger(void) {
    // Set this to 1 for a lot of noisy output that might help debug stuff...
    remote_debug = 0;

    vector_table = (uint32_t*)mcGetVecBase();
    
    if (!mcCheckDeviceSupport()) {
        return false;
    }

    if (mcGetDeviceCount() < 2) {
        return false;
    }

    if (!mcGetDevice(1, &device)) {
        return false;
    }

    CharDevice duart_b;
    mcGetDevice(1, &duart_b);

    duart_install_interrupt(&duart_b, NULL, &uart_b);

    mcGetDevice(1, &duart_b);

    set_debug_traps();
    return true;
}

void cleanup_debugger(void) {
    duart_remove_interrupt();
}

int getDebugChar(void) {
    uint8_t n, buf;

    // Weirdness... Interrupts are disabled while suspended, so check
    // first if we've any buffered input from when we _weren't_ suspended...
    //
    // We _probably_ never do (or maybe should ignore it if we do?) but 
    // for completeness, I'm checking... 
    //
    // If we decide we don't care about input received while not suspended,
    // we can _significantly_ simplify this whole thing (the interrupt handler
    // would just need to yank breakpoint on ctrl-C and ignore everything else).
    //
    n = duart_unbuffer_one(&uart_b, &buf);

    // **************
    // Race Condition Here - _seems_ unlikely to hit, since if we're in this
    // function at all the system is _already_ suspended (i.e. interrupts are
    // disabled) but we really ought to do analysis to ensure this is **always**
    // the case before calling this "good"...

    // if not, just do a normal (blocking) read
    if (n == 0) {
        buf = mcReadDevice(&device);
    }

    return buf;
}

void putDebugChar(int chr) {
    mcSendDevice((char)chr, &device);
}

void exceptionHandler(int exception_number, void (*handler)(void)) {
    vector_table[exception_number] = (uint32_t)handler;
}
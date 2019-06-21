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
 * C prototypes for routines implemented in assembly.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_MACHINE_H
#define _ROSCOM68K_MACHINE_H

/* 
 * Idle the processor.
 *
 * Issues a STOP instruction, keeping the CPU in supervisor mode
 * and setting interrupt priority to 3.
 *
 * Does not stop the system tick.
 *
 * Requires the CPU to be in supervisor mode.
 */
noreturn void IDLE();

/*
 * Halt the processor.
 *
 * Issues a STOP instruction, keeping the CPU in supervisor mode,
 * masking all interrupts (priority to 7) and disabling the MFP interrupts.
 *
 * The only way to come back from this is via the wetware!
 *
 * Requires the CPU to be in supervisor mode.
 */
noreturn void HALT();

/*
 * Start the system tick (MFP Timer C).
 *
 * Note that this cannot be done until we've finished using polled
 * (synchronous) IO on the UART (i.e. the EARLY_PRINT routines).
 * Otherwise, timing issues will cause garbage on the serial port. 
 */
void START_HEART();

/*
 * Stop the system tick (MFP Timer C)
 */
void STOP_HEART();

/*
 * Set m68k interrupt priority level (0-7).
 *
 * Requires the CPU to be in supervisor mode.
 */
void SET_INTR(uint8_t priority);

/*
 * Early print null-terminated string.
 *
 * Don't use this after START_HEART has been called. 
 */
void EARLY_PRINT_C(char *str);

#endif


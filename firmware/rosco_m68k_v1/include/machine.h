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

#include <stdnoreturn.h>
#include <stdint.h>

// DEFINEs for MFP registers
#define MFP_GPDR      0xf80001
#define MFP_AER       0xf80021
#define MFP_DDR       0xf80011
#define MFP_IERA      0xf80031
#define MFP_IERB      0xf80009
#define MFP_IPRA      0xf80029
#define MFP_IPRB      0xf80019
#define MFP_ISRA      0xf80039
#define MFP_ISRB      0xf80005
#define MFP_IMRA      0xf80025
#define MFP_IMRB      0xf80015
#define MFP_VR        0xf80035
#define MFP_TACR      0xf8000D
#define MFP_TBCR      0xf8002D
#define MFP_TCDCR     0xf8001D
#define MFP_TADR      0xf8003D
#define MFP_TBDR      0xf80003
#define MFP_TCDR      0xf80023
#define MFP_TDDR      0xf80013
#define MFP_SCR       0xf80033
#define MFP_UCR       0xf8000B
#define MFP_RSR       0xf8002B
#define MFP_TSR       0xf8001B
#define MFP_UDR       0xf8003B

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


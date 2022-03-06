/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2019-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * C prototypes for system routines implemented in assembly.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_MACHINE_H
#define _ROSCOM68K_MACHINE_H

#include <stdnoreturn.h>
#include <stdint.h>

#ifdef REVISION1X
#define MFP_GPDR      0xf80001
#define MFP_AER       0xf80003
#define MFP_DDR       0xf80005
#define MFP_IERA      0xf80007
#define MFP_IERB      0xf80009
#define MFP_IPRA      0xf8000B
#define MFP_IPRB      0xf8000D
#define MFP_ISRA      0xf8000F
#define MFP_ISRB      0xf80011
#define MFP_IMRA      0xf80013
#define MFP_IMRB      0xf80015
#define MFP_VR        0xf80017
#define MFP_TACR      0xf80019
#define MFP_TBCR      0xf8001B
#define MFP_TCDCR     0xf8001D
#define MFP_TADR      0xf8001F
#define MFP_TBDR      0xf80021
#define MFP_TCDR      0xf80023
#define MFP_TDDR      0xf80025
#define MFP_SCR       0xf80027
#define MFP_UCR       0xf80029
#define MFP_RSR       0xf8002B
#define MFP_TSR       0xf8002D
#define MFP_UDR       0xf8002F
#else
#define DUART_BASE              0xf00001
#define DUART_RW_MODE_A         DUART_BASE+0x0  // RW register 0

#define DUART_R_STATUS_A        DUART_BASE+0x2  // R register 1
#define DUART_W_CLKSEL_A        DUART_BASE+0x2  // W register 1

// R is DO NOT READ on MC part, MISR on XR68C681
#define DUART_R_MISR            DUART_BASE+0x4  // R register 2
#define DUART_W_COMMAND_A       DUART_BASE+0x4  // W register 2

#define DUART_R_RXBUF_A         DUART_BASE+0x6  // R register 3
#define DUART_W_TXBUF_A         DUART_BASE+0x6  // W register 3

#define DUART_R_INPORTCHG       DUART_BASE+0x8  // R register 4
#define DUART_W_AUXCTLREG       DUART_BASE+0x8  // W register 4

#define DUART_R_ISR             DUART_BASE+0xa  // R register 5
#define DUART_W_IMR             DUART_BASE+0xa  // W register 5

#define DUART_R_COUNTERMSB      DUART_BASE+0xc  // R register 6
#define DUART_W_COUNTERMSB      DUART_BASE+0xc  // W register 6

#define DUART_R_COUNTERLSB      DUART_BASE+0xe  // R register 7
#define DUART_W_COUNTERLSB      DUART_BASE+0xe  // W register 7

#define DUART_RW_MODE_B         DUART_BASE+0x10 // RW register 8

#define DUART_R_STATUS_B        DUART_BASE+0x12 // R register 9
#define DUART_W_CLKSEL_B        DUART_BASE+0x12 // W register 9

// R is DO NOT ACCESS on both legacy and modern parts
#define DUART_W_COMMAND_B       DUART_BASE+0x14 // W register 10

#define DUART_R_RXBUF_B         DUART_BASE+0x16 // R register 11
#define DUART_W_TXBUF_B         DUART_BASE+0x16 // W register 11

#define DUART_RW_IVR            DUART_BASE+0x18 // RW register 12

#define DUART_R_INPUTPORT       DUART_BASE+0x1a // R register 13
#define DUART_W_OUTPORTCFG      DUART_BASE+0x1a // W register 13

#define DUART_R_STARTCNTCMD     DUART_BASE+0x1c // R register 14
#define DUART_W_OPR_SETCMD      DUART_BASE+0x1c // W register 14

#define DUART_R_STOPCNTCMD      DUART_BASE+0x1e // R register 15
#define DUART_W_OPR_RESETCMD    DUART_BASE+0x1e // W register 15

//
// For convenience, also define the mnemonics used in the datasheet...
//
// These are *not* defined (by the datasheet) for all registers!
//
#define DUART_MR1A    RW_MODE_A
#define DUART_MR2A    RW_MODE_A
#define DUART_SRA     R_STATUS_A
#define DUART_CSRA    W_CLKSEL_A
#define DUART_MISR    R_MISR
#define DUART_CRA     W_COMMAND_A
#define DUART_RBA     R_RXBUF_A
#define DUART_TBA     W_TXBUF_A
#define DUART_IPCR    R_INPORTCHG
#define DUART_ACR     W_AUXCTLREG
#define DUART_ISR     R_ISR
#define DUART_IMR     W_IMR
#define DUART_CUR     R_COUNTERMSB
#define DUART_CTUR    W_COUNTERMSB
#define DUART_CLR     R_COUNTERLSB
#define DUART_CTLR    W_COUNTERLSB
#define DUART_MR1B    RW_MODE_B
#define DUART_MR2B    RW_MODE_B
#define DUART_SRB     R_STATUS_B
#define DUART_CSRB    W_CLKSEL_B
#define DUART_CRB     W_COMMAND_B
#define DUART_RBB     R_RXBUF_B
#define DUART_TBB     W_TXBUF_B
#define DUART_IVR     RW_IVR
#define DUART_OPCR    W_OUTPORTCFG
#endif

// Define addresses used by the temporary bus error handler.
// N.B. These are duplicated in equates.asm, and must be kept in sync!
#define BERR_SAVED                  0x1180
#define BERR_FLAG                   0x1184

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

/*
 * Firmware PRINT function (uses pointer at $414)
 */
void FW_PRINT_C(char *str);

/*
 * Firmware PRINTLN function (uses pointer at $418)
 */
void FW_PRINTLN_C(char *str);

/*
 * Busywait for a while. The actual time is wholly dependent
 * on CPU (i.e. clock) speed!
 */
void BUSYWAIT_C(uint32_t ticks);

/*
 * Install temporary bus error handler that will set a flag if an error
 * occurs, and not retry the instruction.
 *
 * Saves the existing handler for use by a subsequent RESTORE_BERR_HANDLER.
 *
 * Supports various m68k models.
 *
 * The flag will be set at BERR_FLAG (defined above). The flag will
 * be zeroed when this function is called.
 */
extern void INSTALL_TEMP_BERR_HANDLER(void);

/*
 * Restore original bus error handler, saved by a prior call to
 * INSTALL_TEMP_BERR_HANDLER.
 */
extern void RESTORE_BERR_HANDLER(void);


#endif


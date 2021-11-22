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
 * C prototypes for system routines implemented in assembly.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_MACHINE_H
#define _ROSCOM68K_MACHINE_H

#include <stdint.h>
#include <stdbool.h>
#include <stdnoreturn.h>

#ifdef REVISION_0
// DEFINEs for MFP registers on Revision 0 board
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
#else
// DEFINEs for MFP registers on "fixed" (r1.x) boards
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
#endif

// DEFINEs for DUART registers on r2.x boards
#ifndef REVISION1X
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
#define DUART_MR1A    DUART_RW_MODE_A
#define DUART_MR2A    DUART_RW_MODE_A
#define DUART_SRA     DUART_R_STATUS_A
#define DUART_CSRA    DUART_W_CLKSEL_A
#define DUART_MISR    DUART_R_MISR
#define DUART_CRA     DUART_W_COMMAND_A
#define DUART_RBA     DUART_R_RXBUF_A
#define DUART_TBA     DUART_W_TXBUF_A
#define DUART_IPCR    DUART_R_INPORTCHG
#define DUART_ACR     DUART_W_AUXCTLREG
#define DUART_ISR     DUART_R_ISR
#define DUART_IMR     DUART_W_IMR
#define DUART_CUR     DUART_R_COUNTERMSB
#define DUART_CTUR    DUART_W_COUNTERMSB
#define DUART_CLR     DUART_R_COUNTERLSB
#define DUART_CTLR    DUART_W_COUNTERLSB
#define DUART_MR1B    DUART_RW_MODE_B
#define DUART_MR2B    DUART_RW_MODE_B
#define DUART_SRB     DUART_R_STATUS_B
#define DUART_CSRB    DUART_W_CLKSEL_B
#define DUART_CRB     DUART_W_COMMAND_B
#define DUART_RBB     DUART_R_RXBUF_B
#define DUART_TBB     DUART_W_TXBUF_B
#define DUART_IVR     DUART_RW_IVR
#define DUART_OPCR    DUART_W_OUTPORTCFG
#endif

/*
 * The firmware contains a RomVersionInfo at _FIRMWARE_REV.
 */
typedef struct {
    bool is_snapshot: 1;
    bool is_extdata: 1;
    bool is_huge: 1;
    uint16_t reserved: 13;
    uint8_t major;
    uint8_t minor;
} __attribute__((packed)) RomVersionInfo;

/*
 * The SystemDataBlock is a global reserved structure at _SDB.
 */
typedef struct {
  uint32_t      magic;                /* Magic number B105DA7A */
  uint32_t      oshi_code;            /* OSHI code, only valid in OSHI condition */
  uint16_t      heartbeat_counter;    /* Counter used to flash I0 */
  uint16_t      heartbeat_frequency;  /* Value used to reset heartbeat counter (100 = ~1 beat per second) */
  uint32_t      upticks;              /* Running counter of the number of ticks the system has been up */
  uint32_t      e68k_reserved;        /* Reserved for Easy68k */
  uint32_t      memsize;              /* Size of first contiguous block of RAM */
  uint32_t      uartbase;             /* Base address of default UART */
  uint32_t      cpu_model:3;          /* CPU type */
  uint32_t      cpu_speed:29;         /* CPU speed */
} __attribute__ ((packed)) SystemDataBlock;

/*
 * Absolute symbols defined in linker script
 */
extern uint32_t       _INITIAL_STACK;     // firmware stack top (mem top)
extern void           (*_WARM_BOOT)();      // firmware warm boot address

extern void           (*_MFP_VECTORS[16])();  // MFP interrupt vectors

extern uint32_t       _SDB_MAGIC;           // SDB magic number
extern uint32_t       _SDB_STATUS;          // SDB status code
extern volatile uint32_t _TIMER_100HZ;      // 100Hz timer counter
extern uint8_t        _EASY68K_ECHOON;      // Easy68k 'echo on' flag
extern uint8_t        _EASY68K_PROMPT;      // Easy68k 'prompt on' flag 
extern uint8_t        _EASY68K_SHOWLF;      // Easy68k 'LF display' flag
extern uint32_t       _SDB_MEM_SIZE;        // contiguous memory size
extern uint32_t       _SDB_UART_BASE;       // Default UART base address
extern uint32_t       _SDB_CPU_INFO;        // CPU info (high 3 bits = model, rest of bits = speed).

// NOTE: These are not generally callable from C
extern void           (*_EFP_PRINT)();        // ROM EFP vectors
extern void           (*_EFP_PRINTLN)();   
extern void           (*_EFP_PRINTCHAR)(); 
extern void           (*_EFP_HALT)();      
extern void           (*_EFP_SENDCHAR)();  
extern void           (*_EFP_RECVCHAR)();  
extern void           (*_EFP_CLRSCR)();    
extern void           (*_EFP_MOVEXY)();    
extern void           (*_EFP_SETCURSOR)(); 
extern void           (*_EFP_CHECKCHAR)();  
extern void           (*_EFP_PROGLOADER)();

extern char           _FIRMWARE[];          // ROM firmware start address
extern uint32_t       _FIRMWARE_REV;        // rosco ROM firmware revision
extern char           _LOAD_ADDRESS[];      // firmware load address

/*
 * Print null-terminated string on default console/UART  (may block)
 */
void mcPrint(char *str);

/*
 * Print null-terminated string on default console/UART with newline  (may block)
 */
void mcPrintln(char *str);

/*
 * Print character on default console/UART with newline (may block)
 */
void mcPrintchar(char c);

/*
 * Show or hide cursor (on devices where possible, otherwise no-op)
 */
void mcSetcursor(bool showcursor);

/*
 * Print character on default UART (may block)
 */
void mcSendchar(char c);

/*
 * Read character on default UART  (may block)
 */
char mcReadchar();

/*
 * Check if character waiting on default UART
 */
bool mcCheckchar(); // returns true if char waiting

/*
 * Busywait for a while. The actual time is wholly dependent
 * on CPU (i.e. clock) speed!
 * About 18 CPU cycles per "tick" (plus small overhead per call)
 *   ~2.25 usec per-tick with  8MHz CPU
 *   ~1.80 usec per tick with 10Mhz CPU
 */
void mcBusywait(uint32_t ticks);

/*
 * Delay for n 10ms ticks (using 100Hz timer interrupt)
 */
void mcDelaymsec10(uint32_t ticks10ms);

/*
 * Disable all interrupts (except NMI) and return existing priority mask.
 */
uint8_t mcDisableInterrupts();

/*
 * Enable interrupts according to priority mask.
 */
void mcEnableInterrupts(uint8_t mask);

/*
 * Disable interrupts and halt the machine. The only way to
 * recover from this is via wetware intervention.
 */
noreturn void mcHalt();

#endif


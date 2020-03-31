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
// DEFINEs for MFP registers on "fixed" boards
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

/*
 * Early print null-terminated string.
 */
void mcPrint(char *str);

/*
 * Early print null-terminated string.
 */
void mcPrintln(char *str);

void mcSendchar(char c);
char mcReadchar();

/*
 * Busywait for a while. The actual time is wholly dependent
 * on CPU (i.e. clock) speed!
 */
void mcBusywait(uint32_t ticks);

#endif


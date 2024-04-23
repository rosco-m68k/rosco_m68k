/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 *  __ __
 * |  |  |___ ___ ___ ___ ___
 * |-   -| . |_ -| -_|  _| .'|
 * |__|__|___|___|___|_| |__,|
 *
 * ------------------------------------------------------------
 * Copyright (c) 2021 Xark & contributors
 * MIT License
 *
 * rosco_m68k + Xosera VT100/ANSI terminal driver
 * Based on info from:
 *  https://vt100.net/docs/vt100-ug/chapter3.html#S3.3.6.1
 *  https://misc.flogisoft.com/bash/tip_colors_and_formatting
 *  (and various other sources)
 * ------------------------------------------------------------
 */

#define XANSI_TERMINAL_REVISION 3        // increment when XANSI feature/bugfix applied

// external terminal functions
bool         XANSI_HAVE_XOSERA(void);                    // sanity check if HW responds at Xosera address (vs BUS error)
bool         XANSI_CON_INIT(void);                       // initialize xansiterm and set EFP functions
bool         xansiterm_INIT(void);                       // initialize xansiterm (called from XANSI_CON_INIT)
const char * xansiterm_PRINT(const char * str);          // EFP output NUL terminated string routine
const char * xansiterm_PRINTLN(const char * str);        // EFP output NUL terminated string ending with "\r\n"
void         xansiterm_PRINTCHAR(char c);                // EFP output char routine
void         xansiterm_CLRSCR(void);                     // EFP clear screen
void         xansiterm_SETCURSOR(bool enable);           // EFP enable/disable cursor
bool         xansiterm_CHECKCHAR(void);                  // EFP check input for character ready (wrapper cursor/queries)
char         xansiterm_RECVCHAR(void);                   // EFP block for input character (wrapper cursor/queries)

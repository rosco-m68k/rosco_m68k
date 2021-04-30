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
 * Virtual consoles for firmware. This allows the console to 
 * be set up dynamically based on what hardware is present.
 * ------------------------------------------------------------
 */
#ifndef __ROSCO_M68K_CONSOLE_H
#define __ROSCO_M68K_CONSOLE_H

#include <stdbool.h>

typedef void (PutCharFunc*)(char c);
typedef char (GetCharFunc*)();
typedef char (GetCharNonBlockFunc*)();
typedef bool (IsCharAvailableFunc*)();
typedef void (ClrScrFunc*)();
typedef void (GotoXYFunc*)(uint8_t x, uint8_t y);

typedef struct _Console {
  PutCharFunc           PutChar;
  GetCharFunc           GetChar;
  GetCharNonBlockFunc   GetCharNonBlock;
  IsCharAvailableFunc   IsCharAvailable;
  ClrScrFunc            ClrScr;
  GotoXYFunc            GotoXY;

  // private
  uint8_t               priority;
  struct _Console       _nextcon;
} Console;

void InstallConsole(uint8_t priority, Console *con);
Console* GetConsole(uint8_t priority);
Console* GetDefaultConsole();

void DefaultPutChar(char c);
char DefaultGetChar();
char DefaultGetCharNonBlock();
bool DefaultIsCharAvailable();
void DefaultClrScr();
void DefaultGotoXY(uint8_t x, uint8_t y);

#endif //  __ROSCO_M68K_CONSOLE_H


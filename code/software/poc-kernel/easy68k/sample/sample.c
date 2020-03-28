/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Example of using Easy68K functions from C.
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdbool.h>
#include "easy68k/easy68k.h"

static char readline_buf[1024];

void easy68k_example() {
  e68PrintlnLen("Hello, Easy68K World", 20);
 
  e68SetDisplayOpt(E68K_DISPLAY_PROMPT_OFF);
  e68Print("Type something (this is a custom prompt with no CR): ");
  uint16_t len = e68ReadlnStr(readline_buf);
  e68SetDisplayOpt(E68K_DISPLAY_PROMPT_ON);

  e68Print("Readline returned: ");
  e68PrintlnLen(readline_buf, len);

  e68Print("Unsigned number, base 10: ");
  e68DisplayNumUnsigned(123456789, 10);
  e68Println("");
  e68Print("Signed number: ");
  e68DisplayNumSigned(-1234);
  e68Println("");

  e68Print("Positive number, fixed width of 8: ");
  e68PrintNumSignedWidth(1234,8);
  e68Println("");
  
  e68Print("Negative number, fixed width of 8: ");
  e68PrintNumSignedWidth(-1234,8);
  e68Println("");

  e68Print("Moving to 10,30, and doing standard numeric input with prompt!");

  e68MoveXY(10,30);
  uint32_t num = e68ReadlnNum();

  e68Println("");
  e68Print("CLRSCR: ");
  e68ClearScr();

  e68Print("Screen cleared; Number you entered: ");
  e68DisplayNumUnsigned(num, 10);
  e68Print(" (0x");
  e68DisplayNumUnsigned(num, 16);
  e68Println(")");

  e68Println("Text input; standard prompt and echo on");
  len = e68ReadlnStr(readline_buf);
  e68PrintlnLen(readline_buf, len);

  e68Println("Text input; standard prompt and echo off");
  e68SetEcho(false);

  len = e68ReadlnStr(readline_buf);
  e68PrintlnLen(readline_buf, len);

  e68Println("Easy68K compatibility example done");
}


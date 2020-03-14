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
 * Stdlib-like routines for POC kernel.
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include "machine.h"

void print(char *str) {
  mcPrint(str);
}

void println(char *str) {
  mcPrintln(str);
}

void delay(uint32_t ticks) {
  mcBusywait(ticks);
}

static void print_digit(uint8_t digit) {
  switch (digit & 0xF) {
    case 0: 
      mcPrint("0");
      break;
    case 1: 
      mcPrint("1");
      break;
    case 2: 
      mcPrint("2");
      break;
    case 3: 
      mcPrint("3");
      break;
    case 4: 
      mcPrint("4");
      break;
    case 5: 
      mcPrint("5");
      break;
    case 6: 
      mcPrint("6");
      break;
    case 7: 
      mcPrint("7");
      break;
    case 8: 
      mcPrint("8");
      break;
    case 9: 
      mcPrint("9");
      break;
    case 0xA: 
      mcPrint("A");
      break;
    case 0xB: 
      mcPrint("B");
      break;
    case 0xC: 
      mcPrint("C");
      break;
    case 0xD: 
      mcPrint("D");
      break;
    case 0xE: 
      mcPrint("E");
      break;
    case 0xF: 
      mcPrint("F");
      break;
  }
}

void printuint(uint32_t num) {
  print_digit((num & 0xF0000000) >> 28);
  print_digit((num & 0xF000000) >> 24);
  print_digit((num & 0xF00000) >> 20);
  print_digit((num & 0xF0000) >> 16);
  print_digit((num & 0xF000) >> 12);
  print_digit((num & 0xF00) >> 8);
  print_digit((num & 0xF0) >> 4);
  print_digit(num & 0xF);
}

void printushort(uint16_t num) {
  print_digit((num & 0xF000) >> 12);
  print_digit((num & 0xF00) >> 8);
  print_digit((num & 0xF0) >> 4);
  print_digit(num & 0xF);
}

void printuchar(uint8_t num) {
  print_digit((num & 0xF0) >> 4);
  print_digit(num & 0xF);
}


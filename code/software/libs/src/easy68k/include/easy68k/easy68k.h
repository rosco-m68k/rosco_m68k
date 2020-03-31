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

#ifndef _ROSCOM68K_EASY68K_H
#define _ROSCOM68K_EASY68K_H

// Options for e68SetDisplayOpt
#define E68K_DISPLAY_PROMPT_OFF   0
#define E68K_DISPLAY_PROMPT_ON    1
#define E68K_LINEFEED_OFF         2
#define E68K_LINEFEED_ON          3

#include <stdint.h>
#include <stdbool.h>
#include <stdnoreturn.h>

/**
 * Easy68K TRAP #15, Task 0
 * PRINTLN_LEN 
 */ 
void e68PrintlnLen(char *str, uint16_t len);

/**
 * Easy68K TRAP #15, Task 1
 * PRINT_LEN
 */ 
void e68PrintLen(char *str, uint16_t len);

/**
 * Easy68K TRAP #15, Task 2
 * READLN_STR
 */ 
uint16_t e68ReadlnStr(char *buf);

/**
 * Easy68K TRAP #15, Task 3
 * DISPLAYNUM_SIGNED
 */ 
void e68DisplayNumSigned(int32_t num);

/**
 * Easy68K TRAP #15, Task 4
 * READLN_NUM
 */ 
uint32_t e68ReadlnNum();

/**
 * Easy68K TRAP #15, Task 5
 * READ_CHAR
 */ 
uint8_t e68ReadChar();

/**
 * Easy68K TRAP #15, Task 6
 * SEND_CHAR
 */ 
void e68SendChar(uint8_t chr);

/**
 * Easy68K TRAP #15, Task 7
 * CHECK_RECV
 *
 * N.B. See README - This is potentially dangerous!
 */ 
bool e68CheckRecv();

/**
 * Easy68K TRAP #15, Task 8
 * GET_TICKS
 *
 * N.B. See README - This doesn't do what you think it does!
 */ 
uint32_t e68GetTicks();

/**
 * Easy68K TRAP #15, Task 9
 * HALT
 */ 
noreturn void e68Halt();

/**
 * Easy68K TRAP #15, Task 11 (subtask 1)
 * MOVE_X_Y
 *
 * N.B. This requires ANSI support on the receiving terminal.
 */ 
void e68MoveXY(uint8_t x, uint8_t y);

/**
 * Easy68K TRAP #15, Task 11 (subtask 2)
 * CLEARSCR
 *
 * N.B. This requires ANSI support on the receiving terminal.
 */ 
void e68ClearScr();

/**
 * Easy68K TRAP #15, Task 12
 * SET_ECHO
 */ 
void e68SetEcho(bool echo_on);

/**
 * Easy68K TRAP #15, Task 13
 * PRINTLN_SZ
 */ 
void e68Println(char *sz);

/**
 * Easy68K TRAP #15, Task 14
 * PRINT_SZ
 */ 
void e68Print(char *sz);

/*
 * Easy68K TRAP #15, Task 15
 * DISPLAYNUM_UNSIGNED
 */ 
void e68DisplayNumUnsigned(uint32_t num, uint8_t base);

/*
 * Easy68K TRAP #15, Task 16
 * SET_DISPLAY_OPTS
 */ 
void e68SetDisplayOpt(uint8_t option);

/*
 * Easy68K TRAP #15, Task 17
 * PRINT_SZ_PRINT_NUM
 */ 
void e68PrintStrNumSigned(char *str, uint32_t num);

/*
 * Easy68K TRAP #15, Task 18
 * PRINT_SZ_READ_NUM
 */ 
uint32_t e68PrintStrReadNumSigned(char *str);

/*
 * Easy68K TRAP #15, Task 20
 * DISPLAYNUM_SIGNED_WIDTH
 */ 
void e68PrintNumSignedWidth(uint32_t num, uint8_t width);

#endif


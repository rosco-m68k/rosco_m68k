/*
 *-------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v1
*/

/*
 * ------------------------------------------------------------
 * Copyright (c) 2020 Xark MIT License
 *
 * Debug stub to catch CPU exceptions to aid debugging.
 *
 * USE:  Include this header, call debug_stub() at program startup and link
 * your program with -ldebug_stub.  After that, CPU exceptions (i.e., program
 * crashes) will be caught and instead of the default rosco_m68k red LED blink
 * code, CPU state information will be printed to the default output device
 * and the program will warm-reset back to the loader.
 *
 * As an example, an "address error" exception might look like this:
 * 
 * *** 🤯 m68k: Address error (fault addr 1BADADD1)
 * PC=0000115A op=001C     SR=2004    USP=FFFFFFFF
 * d0=00000000 d1=00000001 d2=000FFF8E d3=00000000
 * d4=00000010 d5=FFFFFFFF d6=FFFFFFFF d7=FFFFFFFF
 * a0=000016FC a1=00000030 a2=000012DE a3=000012CC
 * a4=0000152A a5=000012F0 a6=000FFF42 a7=000FFF8E
 *
 * NOTE: On 68000 CPUs (vs 68010+) the fault addr and PC will be reversed!
 * "fault addr" is the faulting address (only for bus or address error)
 * "PC" is the program counter address where the excpetion occurred
 * "USP" is the user stack pointer (not normally used on "bare" rosco)
 * "op" is the opcode executing when the excpetion occurred (word at PC)
 * The rest are all the normal 68k CPU registers contents at the time
 * of the exception.
 *
 * If you have a rosco_m68k elf file, generated with debug information (-g)
 * then you can usually get the C source line of the code that caused the
 * exception (or close to it, often the line after) using m68k-elf-addr2line,
 * the "-e" option followed by your program elf file and the PC address from
 * the debug information printed (preceeded with "0x" for hex).  For example,
 * for the crash above:
 *
 * m68k-elf-addr2line -e example.elf 0x115A
 *
 * NOTE: On 68010/12 CPUs the PC counter (and "op") may be up to five words
 * ahead of the actual location where the exception occurred on a bus or
 * address error (due to additional prefetch mechanisms in those CPUs).
 * However, the "fault addr" should remain accurate.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_DEBUGSTUB_H
#define _ROSCOM68K_DEBUGSTUB_H

void debug_stub();  // initialize debug exception handlers in debug_stub.a

#endif


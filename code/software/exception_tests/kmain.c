/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v1
 * ------------------------------------------------------------
 * Copyright (c) 2021 Ross Bamford (roscopeco <at> gmail <dot> com).
 * See top-level LICENSE.md for licence information.
 *
 * This is an example of using the ExceptionFrame structure in a 
 * C exception handler (called by an ASM stub to make the stack 
 * right) to handle a bus error from C code.
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <machine/exception.h>

extern void INSTALL_HANDLER();
extern void UNINSTALL_HANDLER();

static volatile bool berr_hit = false;
static volatile uint16_t fmt = 0x1234;
static volatile uint16_t sr = 0x1234;
static volatile uint32_t pc = 0x12341234;
static volatile uint16_t vec_ofs = 0x1234;
static volatile uint8_t cpuver = 0;

static uint32_t *bad = (uint32_t*)0x00f00000;

/* 
 * Example of a C Bus Error handler. Note that this is *not* directly an 
 * exception handler (attribute interrupt) function - instead, it is called
 * by an assembler stub using JSR (to set up the stack correctly). 
 *
 * It's also worth noting that this is manipulating the passed in frame
 * directly, which is re-read by the CPU when the handler is done and 
 * (in this case) causes it to consider the bus error as handled in software.
 */
void berr_handler_c(CPUExceptionFrame *frame) {
  // indicate to the main code that the bus error handler has been run
  berr_hit = true;

  // Set some data for the main code to read after the exception
  fmt = frame->format;
  sr = frame->sr;
  pc = frame->pc;
  vec_ofs = frame->vec_ofs;

  // Handle the bus error appropriately for the CPU type (determined by the format code).
  switch (frame->format) {
  case EX_FMT_010_BERR:
    // 68010 - Set bit 15 in SSW
    cpuver = 1;
    frame->fmt010.ssw |= EX_M010_SSW_RR_MASK;  /* Set the Rerun flag, indicating that we handled the re-run */
    frame->fmt010.data_in_buffer = 0xF00D;     /* Make the faulting read return 0xF00D (only 16-bit on 68010) */
    break;
  case EX_FMT_020_BERR_SHORT:
  case EX_FMT_020_BERR_LONG:
    // 68020 - Clear bit 8 in SSW
    cpuver = 2;
    frame->fmt020.ssw &= ~EX_M020_SSW_DF_MASK; /* Clear the Data Fault flag, indicating we don't want re-run */
    frame->fmt020.data_in_buffer = 0x2BADF00D; /* Instead, make it seem that the read returned 0x2BADF00D */
    break;
  default:
    // Unknown / 68000
    break;
  }
}

/* Simple kmain to demonstrate the bus error handler */
void kmain() {
  INSTALL_HANDLER();

  // Generate a bus fault
  printf("Bad is 0x%08x\r\n", *bad);

  if (berr_hit) {
    printf("\nBus Error occurred:\r\n");
    printf("    Format was 0b%04b     (Indicating 680%d0 CPU)\r\n", fmt, cpuver);
    printf("    VecOfs was 0x%06x   (Exception #%d)\r\n", vec_ofs, vec_ofs / 4);
    printf("    SR     was 0x%04x\r\n", sr);
    printf("    PC     was 0x%08x\r\n", pc);
  } else {
    printf("Bus Error did not occur.\r\n");
  }

  UNINSTALL_HANDLER();
}


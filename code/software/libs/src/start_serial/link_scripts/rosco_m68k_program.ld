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
 * Link script for code that is loaded by the serial-receive
 * boot loader.
 * ------------------------------------------------------------
 */

OUTPUT_FORMAT("binary")
ENTRY(START)
kram = 0x00001000;
phys = 0x00F00000;      /* "high" address for pos-ind. init   */
MEMORY
{
  INIT : org = phys, l = 0xBEFFF   /* init -> top of ram (767KB) */ 
  KRAM : org = kram, l = 0xFEFFF   /* Allow located code to use all of RAM > 4k */
}

PROVIDE(_STACK_TOP   = 0x00100000);  /* default stack at 1MB base RAM top */
PROVIDE(_MFP_VECBASE = 0x00000040);  /* handy vector base, useable from C */
SECTIONS
{
  .text.init : AT(0)
  {
    _init = .;
    *(.init)
    _init_end = .;
  } > INIT
  
  .text.postinit : AT(SIZEOF(.text.init))
  {
    _postinit = .;
    KEEP(*(.postinit))  /* KEEP() needed to "anchor" kmain reference for gc-sections */
    _postinit_end = .;
  } > KRAM

  .text ALIGN(4) :
  {
    _code = .;
    *(.text*)
    *(.rodata*)
    _code_end = .;
  } > KRAM
  
  .data ALIGN(4) :
  {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } > KRAM

  .bss ALIGN(4) :
  {
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    _bss_end = .;
  } > KRAM

  _end = .;
}

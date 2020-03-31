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
phys = 0x00028000;
MEMORY
{
  INIT : org = phys, l = 0xd7fff   /* init -> top of ram (863KB) */ 
  KRAM : org = kram, l = 0xFEFFF   /* Allow located code to use all of RAM > 4k */
}

SECTIONS
{
  .text.init : AT(0)
  {
    _init = .;
    *(.init)
    . = ALIGN(2);
    _init_end = .;
  } > INIT

  .text ALIGN(2) : AT(SIZEOF(.text.init))
  {
    _code = .;
    *(.text)
    *(.rodata)
    . = ALIGN(2);
    _code_end = .;
  } > KRAM
  
  .data ALIGN(2) : /*AT(SIZEOF(.text.init) + SIZEOF(.text))*/
  {
    _data_start = .;
    *(.data)
    _data_end = .;
    . = ALIGN(2);
  } > KRAM

  .bss ALIGN(2) : /*AT(SIZEOF(.text.init) + SIZEOF(.text) + SIZEOF(.data))*/
  {
    _bss_start = .;
    *(.bss)
    _bss_end = .;
    . = ALIGN(2);
  } > KRAM

  _end = .;
}



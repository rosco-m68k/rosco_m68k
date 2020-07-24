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
  INIT : org = phys, l = 0xBEFFF   /* init -> top of ram (767KB) */ 
  KRAM : org = kram, l = 0xFEFFF   /* Allow located code to use all of RAM > 4k */
}

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
    *(.postinit)
    _postinit_end = .;
  } > KRAM

  .text ALIGN(2) :
  {
    _code = .;
    *(.text)
    *(.rodata)
    _code_end = .;
  } > KRAM
  
  .data ALIGN(2) :
  {
    _data_start = .;
    *(.data)
    _data_end = .;
  } > KRAM

  .bss ALIGN(2) :
  {
    _bss_start = .;
    *(.bss)
    _bss_end = .;
  } > KRAM

  _end = .;
}



/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|     firmware v1.2
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

ram  = 0x00001000;          /* start of user memory                     */

MEMORY
{
  RAM  : org = ram,  l = 0x00FFEFFF     /* program can use all RAM > 4K */
}

/* program configuration symbols that may be useful to override */
/* using linker option: --defsym=<symbol_name>=<value>          */
PROVIDE(_RAM_SIZE     = 1M);            /* default to 1MB of RAM        */
PROVIDE(_STACK_TOP    = _RAM_SIZE);     /* default stack at top of RAM  */
PROVIDE(_STACK_SIZE   = 0x00004000);    /* 16KB default stack size      */
PROVIDE(_HEAP_END     = _STACK_TOP - _STACK_SIZE); /* heap end at stack */

/* firware absolute addresses (generally not useful to override)  */
PROVIDE(_MFP_VECTORS    = 0x00000100);  /* MFP interrupt vector base    */
PROVIDE(_TIMER_100HZ    = 0x0000040C);  /* firmware 100Hz timer counter */
PROVIDE(_EASY68K_ECHOON = 0x00000410);  /* Easy68k 'echo on' flag       */
PROVIDE(_EASY68K_PROMPT = 0x00000411);  /* Easy68k 'prompt on' flag     */
PROVIDE(_EASY68K_SHOWLF = 0x00000412);  /* Easy68k 'LF display' flag    */

/* NOTE: These need to be kept in sync with firmware equates.S! */
PROVIDE(_EFP_TABLE      = 0x00000420);  /* Extension function ptr table */

PROVIDE(_EFP_PRINT      = 0x00000420);  /* Print string to console      */
PROVIDE(_EFP_PRINTLN    = 0x00000424);  /* Print string with CR+LF      */
PROVIDE(_EFP_PRINTCHAR  = 0x00000428);  /* Print a character            */
PROVIDE(_EFP_HALT       = 0x0000042C);  /* Disable interrupts and halt  */
PROVIDE(_EFP_SENDCHAR   = 0x00000430);  /* Send a character via UART    */
PROVIDE(_EFP_RECVCHAR   = 0x00000434);  /* Receive a character via UART */
PROVIDE(_EFP_CLRSCR     = 0x00000438);  /* Clear screen (optional)      */
PROVIDE(_EFP_MOVEXY     = 0x0000043C);  /* Set cursor position (opt.)   */
PROVIDE(_EFP_SETCURSOR  = 0x00000440);  /* Enbable/disable cursor (opt.)*/

/* ROM absolute addresses */
PROVIDE(_FIRMWARE_REV   = 0x00FC0400);  /* firmware revision code       */

/* NOTE: rev1.1 used 0x00028000 (but init now position independent)     */
PROVIDE(_LOAD_ADDRESS   = 0x00040000);  /* firmware KERNEL_LOAD_ADDRESS */
PROVIDE(_RUN_ADDRESS    = ORIGIN(RAM)); /* start of user memory         */

SECTIONS
{
  .text.init :
  {
    _init = .;
    KEEP(*(.init))      /* KEEP() "anchors" section for gc-sections */
    _init_end = .;
  } > RAM

  .text.postinit :
  {
    _postinit = .;
    KEEP(*(.postinit))  /* KEEP() "anchors" section for gc-sections */
    . = ALIGN(4);       /* long align for init.S copying */
    _postinit_end = .;
  } > RAM

  .text ALIGN(4) :
  {
    _code = .;
    *(.text*)
    *(.rodata*)
    _code_end = .;
  } > RAM

  .data ALIGN(4) :
  {
    _data_start = .;
    *(.data*)
    . = ALIGN(4);       /* long align for init.S copying */
    _data_end = .;
  } > RAM

  .bss ALIGN(4) :
  {
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);       /* long align for kinit clearing */
    _bss_end = .;
  } > RAM

  /* verify end of program BSS leaves room for mimimum stack size */
  ASSERT(_bss_end < _HEAP_END,
    "program too large (use e.g. --defsym=_RAM_SIZE=2M for 2MiB RAM)")

  _end = .;
}

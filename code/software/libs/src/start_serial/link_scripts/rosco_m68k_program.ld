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

ram  = 0x00002000;          /* start of user memory                     */

MEMORY
{
  RAM  : org = ram,  l = 0x00f7e000     /* program can use all RAM > 8K */
}

/* program configuration symbols that may be useful to override */
/* using linker option: --defsym=<symbol_name>=<value>          */
PROVIDE(_STACK_SIZE     = 0x00004000);  /* 16KB default stack size      */

/* firmware absolute addresses (generally not useful to override)  */
PROVIDE(_INITIAL_STACK  = 0x00000000);  /* firmware stack top (mem top) */
PROVIDE(_WARM_BOOT      = 0x00000004);  /* firmware warm boot address   */

PROVIDE(_MFP_VECTORS    = 0x00000100);  /* MFP interrupt vector base    */

/* system data block */
PROVIDE(_SDB            = 0x00000400);  /* System Data Block            */
PROVIDE(_SDB_MAGIC      = 0x00000400);  /* SDB magic number             */
PROVIDE(_SDB_STATUS     = 0x00000404);  /* SDB status code              */
PROVIDE(_SDB_RSRVD_408  = 0x00000408);  /* SDB reserved                 */
PROVIDE(_TIMER_100HZ    = 0x0000040C);  /* 100Hz timer counter          */
PROVIDE(_EASY68K_ECHOON = 0x00000410);  /* Easy68k 'echo on' flag       */
PROVIDE(_EASY68K_PROMPT = 0x00000411);  /* Easy68k 'prompt on' flag     */
PROVIDE(_EASY68K_SHOWLF = 0x00000412);  /* Easy68k 'LF display' flag    */
PROVIDE(_SDB_RSRVD_413  = 0x00000413);  /* SDB reserved                 */
PROVIDE(_SDB_MEM_SIZE   = 0x00000414);  /* contiguous memory size       */
PROVIDE(_SDB_UART_BASE  = 0x00000418);  /* UART base address            */
PROVIDE(_SDB_CPU_INFO   = 0x0000041C);  /* CPU Info (model and speed)   */

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
PROVIDE(_EFP_SETCURSOR  = 0x00000440);  /* Enable/disable cursor (opt.) */
PROVIDE(_EFP_CHECKCHAR  = 0x00000444);  /* Check char ready from UART   */
PROVIDE(_EFP_PROGLOADER = 0x00000448);  /* Initial program loader       */
PROVIDE(_EFP_SD_INIT    = 0x0000044C);  /* SD Card init                 */
PROVIDE(_EFP_SD_READ    = 0x00000450);  /* SD Card read                 */
PROVIDE(_EFP_SD_WRITE   = 0x00000454);  /* SD Card write                */
PROVIDE(_EFP_SD_REG     = 0x00000458);  /* SD Card register read        */
PROVIDE(_EFP_SPI_INIT   = 0x0000045C);  /* SPI init                     */
PROVIDE(_EFP_SPI_CS_A   = 0x00000460);  /* SPI CS assert                */
PROVIDE(_EFP_SPI_CS_D   = 0x00000464);  /* SPI CS deassert              */
PROVIDE(_EFP_SPI_XFER_B = 0x00000468);  /* SPI transfer byte            */
PROVIDE(_EFP_SPI_XFER_M = 0x0000046C);  /* SPI transfer multiple        */
PROVIDE(_EFP_SPI_RECV_B = 0x00000470);  /* SPI recv byte                */
PROVIDE(_EFP_SPI_RECV_M = 0x00000474);  /* SPI recv multiple            */
PROVIDE(_EFP_SPI_SEND_B = 0x00000478);  /* SPI send byte                */
PROVIDE(_EFP_SPI_SEND_M = 0x0000047C);  /* SPI send multiple            */
PROVIDE(_EFP_ATA_INIT   = 0x00000480);  /* ATA init                     */
PROVIDE(_EFP_ATA_READ   = 0x00000484);  /* ATA read                     */
PROVIDE(_EFP_ATA_WRITE  = 0x00000488);  /* ATA write                    */
PROVIDE(_EFP_ATA_IDENT  = 0x0000048C);  /* ATA identify                 */

/* ROM absolute addresses */
PROVIDE(_FIRMWARE       = 0x00FC0000);  /* firmware address             */
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
  
  .ctors ALIGN(4) : 
  {
      _ctors = .;
      KEEP(*(.ctors))           /* Run in reverse order, so non-priority ones go first  */
      KEEP(*(SORT(.ctors.*)))   /* followed by ctors with priority */
      _ctors_end = .;
  } > RAM

  .dtors ALIGN(4) : 
  {
      _dtors = .;
      KEEP(*(SORT(.dtors.*)))   /* dtors with priority go first, highest to lowest */
      KEEP(*(.dtors))           /* Followed by non-priority ones */
      _dtors_end = .;
  } > RAM

  .data ALIGN(4) :
  {
    _data_start = .;
    *(.data*)
    . = ALIGN(4);       /* long align for init.S copying */
    _data_end = .;
  } > RAM

  .bss(NOLOAD):
  {
    . = ALIGN(4);       /* Not strictly needed, but here in case we rearrange things */
    _bss_start = .;
    *(.bss*)
    *(COMMON)
    . = ALIGN(4);       /* long align for kinit clearing */
    _bss_end = .;
  } > RAM

  _end = .;
}

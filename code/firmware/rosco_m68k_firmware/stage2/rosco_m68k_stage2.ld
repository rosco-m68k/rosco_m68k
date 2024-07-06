OUTPUT_FORMAT("elf32-m68k")
ENTRY(STAGE2_START)
kermit_buffers = 0x2000;
MEMORY
{
  BASERAM : org = 0x00000000, l = 1M
}

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

SECTIONS
{
  .kermit kermit_buffers (NOLOAD) :
  {
    _kermit_start = .;
    *(.kermit)
    _kermit_end = .;
    ASSERT(_kermit_end <= 0x40000, "Error: No room left for kernel load region");
  } >BASERAM

  .text STAGE2_LOAD :
  {
    _code = .;
    *(.text*)
      _ctors        = .;
    KEEP(*(.ctors))           /* Run in reverse order, so non-priority ones go first  */
    KEEP(*(SORT(.ctors.*)))   /* followed by ctors with priority */
      _ctors_end     = .;

      _dtors         = .;
    KEEP(*(SORT(.dtors.*)))   /* dtors with priority go first */
    KEEP(*(.dtors))           /* Followed by non-priority ones */
      _dtors_end     = .;

    . = ALIGN(4);
    *(.rodata .rodata.*)

    . = ALIGN(4);
    KEEP(*(.gcc_except_table))

    . = ALIGN(4);
    KEEP(*(.init*))     /* maybe we should keep these in their sections 🤔... */
    KEEP(*(.fini*))
    _code_end = .;
  } >BASERAM

  . = DATA_SEGMENT_ALIGN(CONSTANT(MAXPAGESIZE), CONSTANT(COMMONPAGESIZE));

  .data ALIGN(4) :
  {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } >BASERAM
  
  .bss ALIGN(4) :
  {
    _bss_start = .;
    *(COMMON)
    *(.bss*)
    _bss_end = .;
  } >BASERAM

  . = DATA_SEGMENT_END(.);

  _end = .;
}

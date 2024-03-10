OUTPUT_FORMAT("binary")
ENTRY(START)
kermit_buffers = 0x2000;
MEMORY
{
  BASERAM : org = 0x00000000, l = 1M
}

PROVIDE(STAGE2_LOAD     = 0x000F0000);

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
    *(.text.init)
    *(.text)
    *(.text.unlikely)
    *(.rodata*)
    _code_end = .;
  } >BASERAM

  .data : ALIGN(4)
  {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } >BASERAM
  
  .bss : ALIGN(4)
  {
    _bss_start = .;
    *(COMMON)
    *(.bss*)
    _bss_end = .;
  } >BASERAM

  _end = .;
}

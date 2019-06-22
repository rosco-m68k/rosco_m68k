OUTPUT_FORMAT("binary")
ENTRY(START)
kram = 0x00000500;
phys = 0x00FC0000;
MEMORY
{
  KRAM : org = 0x00000500, l = 0x3B00   /* KRAM up to 16K mark */
  ROM : org = 0x00FC0000, l = 16K
}

SECTIONS
{
  .bss kram :
  {
    _bss_start = .;
    *(.bss)
    _bss_end = .;
    . = ALIGN(2);
  } > KRAM

  .data : AT(_code_end)
  {
    _data_start = .;
    *(.data)
    _data_end = .;
    . = ALIGN(2);
  } > KRAM
  
  .text phys :
  {
    _code = .;
    *(.text)
    *(.rodata)
    . = ALIGN(2);
    _code_end = .;
  } > ROM

  _end = .;
}



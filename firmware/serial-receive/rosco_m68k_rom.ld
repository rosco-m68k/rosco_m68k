OUTPUT_FORMAT("binary")
ENTRY(START)
kram = 0x00000500;
phys = 0x00FC0000;
MEMORY
{
  KRAM : org = kram, l = 0xF7FFFF   /* KRAM up to 16K mark */
  ROM : org = phys, l = 16K
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



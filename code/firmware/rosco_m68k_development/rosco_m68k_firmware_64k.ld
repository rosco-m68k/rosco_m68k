OUTPUT_FORMAT("binary")
ENTRY(START)
kram = 0x00001800;
phys = 0x00FC0000;
MEMORY
{
  KRAM : org = kram, l = 2K
  ROM : org = phys, l = 64K
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
    *(.rodata*)
    _zip_start = .;
    *(.zipdata)
    _zip_end = .;
    . = ALIGN(2);
    _code_end = .;
  } > ROM

  _end = .;
}



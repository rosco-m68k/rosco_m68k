OUTPUT_FORMAT("binary")
ENTRY(START)
stage2 = 0xF0000;
MEMORY
{
  RAM : org = 0x00000, l = 0x100000
}

SECTIONS
{
  .text stage2 :
  {
    _code = .;
    *(.text.init)
    *(.text)
    *(.text.unlikely)
    *(.rodata*)
    _code_end = .;
  } > RAM

  .data ALIGN(4) :
  {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } > RAM
  
  .bss ALIGN(4) :
  {
    _bss_start = .;
    *(COMMON)
    *(.bss*)
    _bss_end = .;
  } > RAM
  _end = .;
  
}



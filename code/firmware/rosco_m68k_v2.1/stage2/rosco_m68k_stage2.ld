OUTPUT_FORMAT("binary")
ENTRY(START)
phys = 0x2000;
MEMORY
{
  RAM : org = phys, l = 0xFDFFF   /* Allow loader to use all of RAM */
}

SECTIONS
{
  .text : AT(0)
  {
    _code = .;
    *(.text.init)
    *(.text)
    *(.text.unlikely)
    *(.rodata*)
    _code_end = .;
  } > RAM

  .data : ALIGN(2) 
  {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } > RAM
  
  .bss : ALIGN(2)
  {
    _bss_start = .;
    *(COMMON)
    *(.bss*)
    _bss_end = .;
  } > RAM
  _end = .;
  
}



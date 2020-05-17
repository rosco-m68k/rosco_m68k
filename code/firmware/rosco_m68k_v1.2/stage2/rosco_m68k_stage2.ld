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
    . = ALIGN(2);
    _code_end = .;
  } > RAM

  .data : 
  {
    _data_start = .;
    *(.data*)
    _data_end = .;
  } > RAM
  
  .bss :
  { 
    _bss_start = .;
    *(.bss*)
    _bss_end = .;
  } > RAM
  
  _end = .;
}



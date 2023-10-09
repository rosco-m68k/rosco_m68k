OUTPUT_FORMAT("binary")
ENTRY(START)
kermit_buffers = 0x2000;
stage2 = 0xF0000;
MEMORY
{
  RAM : org = 0x00000, l = 0x100000
}

SECTIONS
{
  .kermit kermit_buffers (NOLOAD) :
  {
    _kermit_start = .;
    *(.kermit)
    _kermit_end = .;
    ASSERT(_kermit_end < 0x40000, "Error: No room left for kernel load region");
  } > RAM

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



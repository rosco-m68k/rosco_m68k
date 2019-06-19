OUTPUT_FORMAT("binary")
ENTRY(START)
phys = 0x00FC0000;
SECTIONS
{
  .text phys : AT(phys) {
    code = .;
    *(.text)
    *(.rodata)
    . = ALIGN(2);
  }
  .data : AT(phys + (data - code - 2))
  {
    data = .;
    *(.data)
    . = ALIGN(2);
  }
  end = .;
}



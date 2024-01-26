OUTPUT_FORMAT("elf32-m68k")
ENTRY(START)
kram = 0x00001800;
phys = 0x00E00000;
MEMORY
{
  KRAM : org = kram, l = 2K
  ROM : org = phys, l = 1M
}

PROVIDE(STAGE2_LOAD     = 0x000F0000);
PROVIDE(RAMBASE         = 0x00000000);
PROVIDE(RAMLIMIT        = 0x00100000);
PROVIDE(EXPTOP          = phys);

/* minimal items for XANSI in C */
PROVIDE(_EFP_INPUTCHAR  = 0x00000494);  /* Receive a character via input */
PROVIDE(_EFP_CHECKINPUT = 0x00000498);  /* Check char ready from input   */
PROVIDE(XANSI_CON_DATA  = 0x00000500);  /* XANSI data ($0500-$057F)      */

PROVIDE(_FIRMWARE_REV   = 0x00E00400);  /* firmware revision code       */

SECTIONS
{
  .text : 
  {
    _code = .;
    *(.text*)
    . = ALIGN(2);
    *(.rodata*)
    . = ALIGN(2);
    _zip_start = .;
    *(.zipdata)
    _zip_end = .;
    . = ALIGN(2);
    _code_end = .;
  } > ROM

  .data :
  {
    *(.early_data*)
    _data_start = .;
    . = ALIGN(2);
    *(.data*)
    _data_end = .;
    . = ALIGN(2);
  } > KRAM AT > ROM

   .bss (NOLOAD) : 
  {
    _bss_start = .;
    *(.bss*)
    _bss_end = .;
    . = ALIGN(2);
  } > KRAM
 
  _end = .;
}



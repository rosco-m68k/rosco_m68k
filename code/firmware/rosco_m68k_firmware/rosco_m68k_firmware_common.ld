ENTRY(START)

/* Firmware RAM map */
MEMORY
{
  VECTS   : org = 0x00000000, l = 0x000400
  SDB     : org = 0x00000400, l = 0x000020
  EFPT    : org = 0x00000420, l = 0x0000E0
  VDA     : org = 0x00000500, l = 0x000C80
  KRES1   : org = 0x00001180, l = 0x000680
  KRES2   : org = 0x00001800, l = 0x000800
  UMEM    : org = 0x00002000, l = LENGTH(BASERAM) - ORIGIN(BASERAM) - ORIGIN(UMEM)
}

PROVIDE(STAGE2_LOAD     = 0x000F0000);
PROVIDE(RAMBASE         = ORIGIN(BASERAM));
PROVIDE(RAMLIMIT        = ORIGIN(UMEM)    + LENGTH(UMEM));
PROVIDE(EXPTOP          = ORIGIN(EXPRAM)  + LENGTH(EXPRAM));

/* Minimal items for XANSI in C */
PROVIDE(_EFP_INPUTCHAR  = ORIGIN(EFPT)  + 0x074); /* Receive a character via input  */
PROVIDE(_EFP_CHECKINPUT = ORIGIN(EFPT)  + 0x078); /* Check char ready from input    */
PROVIDE(XANSI_CON_DATA  = ORIGIN(VDA)   + 0x000); /* XANSI data ($0500-$057F)       */

PROVIDE(_FIRMWARE_REV   = ORIGIN(FLASH) + 0x400); /* Firmware revision code         */

SECTIONS
{
  .text : ALIGN(4)
  {
    _code = .;
    *(.text*)
    *(.rodata*)
    _zip_start = .;
    *(.zipdata)
    _zip_end = .;
    _code_end = .;
  } >FLASH

  .data : ALIGN(4)
  {
    *(.early_data*)
    _data_start = .;
    _data_load_start = _data_start - ADDR(.data) + LOADADDR(.data);
    *(.data*)
    _data_end = .;
    _data_load_end = _data_end - ADDR(.data) + LOADADDR(.data);
  } >KRES2 AT>FLASH

   .bss (NOLOAD) : ALIGN(4)
  {
    _bss_start = .;
    *(.bss*)
    _bss_end = .;
  } >KRES2
 
  _end = .;
}

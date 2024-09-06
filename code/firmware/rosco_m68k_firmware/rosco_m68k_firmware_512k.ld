OUTPUT_FORMAT("elf32-m68k")

/* Board memory map */
MEMORY
{
  BASERAM : org = 0x00000000, l = 1M
  EXPRAM  : org = 0x00100000, l = 13M
  ROMSPC  : org = 0x00E00000, l = 1M
  IOSPC   : org = 0x00F00000, l = 1M
}

/* Installed flash memory map */
MEMORY
{
  FLASH   : org = ORIGIN(ROMSPC), l = 512K  /* Minimum flash chip size */
}

INCLUDE rosco_m68k_firmware_common.ld

SECTIONS {  
  .romfs 0x00E26000 : ALIGN(4)
  {
    ASSERT(_zip_end <= 0x26000, "Error: No room left for ROMFS region");
    _romfs = .;
    *(.romfs*)
    _romfs_end = .;
  } >FLASH
}


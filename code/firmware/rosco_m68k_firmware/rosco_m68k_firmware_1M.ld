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
  FLASH   : org = ORIGIN(ROMSPC), l = 1024K /* Minimum flash chip size */
}

INCLUDE rosco_m68k_firmware_common.ld

SECTIONS {  
  .romfs _ROMFS_BASE : ALIGN(4)
  {
    ASSERT(ABSOLUTE(_zip_end) <= _ROMFS_BASE, "Error: No room left for ROMFS region");
    _romfs = .;
    *(.romfs*)
    _romfs_end = .;
  } >FLASH
}


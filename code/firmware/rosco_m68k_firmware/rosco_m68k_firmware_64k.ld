/* Board memory map */
MEMORY
{
  BASERAM : org = 0x00000000, l = 1M
  EXPRAM  : org = 0x00100000, l = 14M + 512K
  IOSPC   : org = 0x00F80000, l = 256K
  ROMSPC  : org = 0x00FC0000, l = 256K
}

/* Installed flash memory map */
MEMORY
{
  FLASH   : org = ORIGIN(ROMSPC), l = 64K
}

INCLUDE rosco_m68k_firmware_common.ld

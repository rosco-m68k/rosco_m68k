/*
 * Copyright (c) 2020 Xark https://hackaday.io/Xark
 */

#include <machine.h>
#include <stdint.h>
#include <stdio.h>
#include <debug_stub.h>

static uint32_t * rom_reset_vector = (uint32_t *)&_FIRMWARE[4];

#define RESIDENT_MAGIC  0xc0de0042
extern void resident_init();

void kmain()
{
  debug_stub();
  mcDelaymsec10(250);
  printf("Example/test of rosco_m68k warm reboot.\n\n");

  printf("rosco_m68k config (firmware: 0x%08X)\n", _FIRMWARE_REV);
  printf("------------------------------------\n");
  printf(" Total memory     : 0x%08x (%d KiB)\n", _SDB_MEM_SIZE, _SDB_MEM_SIZE / 1024);
  printf(" Available memory : 0x%08x (%d KiB)\n", _INITIAL_STACK, _INITIAL_STACK / 1024);
  int32_t reserved = _SDB_MEM_SIZE - _INITIAL_STACK;
  if (reserved > 0)
  {
    printf("  (0x%08x bytes reserved)\n", reserved);
  }
  else if (reserved < 0)
  {
    printf("  (ERROR: initial stack > memory size?)\n");
  }
  printf(" ROM reset vector : 0x%08x\n", *rom_reset_vector);
  printf(" Warm-boot vector : 0x%08x\n", _WARM_BOOT);
  printf("\n");

  printf(" EFP_PRINT        : 0x%08x\n", _EFP_PRINT);
  printf(" EFP_PRINTLN      : 0x%08x\n", _EFP_PRINTLN);
  printf(" EFP_PRINTCHAR    : 0x%08x\n", _EFP_PRINTCHAR);
  printf(" EFP_HALT         : 0x%08x\n", _EFP_HALT);
  printf(" EFP_SENDCHAR     : 0x%08x\n", _EFP_SENDCHAR);
  printf(" EFP_RECVCHAR     : 0x%08x\n", _EFP_RECVCHAR);
  printf(" EFP_CLRSCR       : 0x%08x\n", _EFP_CLRSCR);
  printf(" EFP_MOVEXY       : 0x%08x\n", _EFP_MOVEXY);
  printf(" EFP_SETCURSOR    : 0x%08x\n", _EFP_SETCURSOR);
  printf(" EFP_PROGLOADER   : 0x%08x\n", _EFP_PROGLOADER);
  printf("\n");

  if (reserved <= 0 || *(uint32_t *)_INITIAL_STACK != RESIDENT_MAGIC)
  {
    printf("*** Resident test signature not detected, installing test.\n");
    printf(" ... Initializing resident test.\n");
    uint32_t a7_before;
    __asm__ __volatile__ ("move.l %%a7,%[a7_before]\n" : [a7_before] "=d" (a7_before) : : );
    resident_init();
    uint32_t a7_after;
    __asm__ __volatile__ ("move.l %%a7,%[a7_after]\n" : [a7_after] "=d" (a7_after) : : );
    int32_t reserved = a7_before - a7_after;
    printf(" ... Completed.\n");
    printf(" Test reserved 0x%08x bytes memory.\n", reserved);
  }
  else
  {
    printf("*** Resident signature detected, test already installed.\n");
    printf(" ... Test signature @ 0x%08x = 0x%08x\n", _INITIAL_STACK, *(uint32_t *)_INITIAL_STACK);
  }

  printf("\nResident test loader completed.\n\n");

  for (int d = 3; d != 0; d--)
  {
    printf("Warm reboot coming up...%d\n", d);
    mcDelaymsec10(100);
  }
  mcDelaymsec10(100);
  printf("\nExit...\n");
  mcDelaymsec10(10);
}

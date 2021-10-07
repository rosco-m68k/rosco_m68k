/*
 * Copyright (c) 2020 Xark
 */

#include <stdint.h>
#include <stdio.h>

#include <machine.h>
#include <basicio.h>

static uint32_t * rom_reset_vector = (uint32_t *)&_FIRMWARE[4];

#define RESIDENT_MAGIC  0xc0de0042
extern void resident_init();

int main(int argc, char **argv)
{
  (void)argc;
  (void)argv;

  if (checkchar())
  {
    readchar();
  }

  mcDelaymsec10(250);
  printf("\033c");
  printf("Example/test of rosco_m68k warm reboot.\n\n");

  printf("rosco_m68k config (firmware: 0x%08lX)\n", _FIRMWARE_REV);
  printf("------------------------------------\n");
  printf(" Total memory     : 0x%08lx (%ld KiB)\n", _SDB_MEM_SIZE, _SDB_MEM_SIZE / 1024);
  printf(" Available memory : 0x%08lx (%ld KiB)\n", _INITIAL_STACK, _INITIAL_STACK / 1024);
  int32_t reserved = _SDB_MEM_SIZE - _INITIAL_STACK;
  if (reserved > 0)
  {
    printf("  (0x%08lx bytes reserved)\n", reserved);
  }
  else if (reserved < 0)
  {
    printf("  (ERROR: initial stack > memory size?)\n");
  }
  printf(" ROM reset vector : 0x%08lx\n", *rom_reset_vector);
  printf(" Warm-boot vector : 0x%08lx\n", (uint32_t)_WARM_BOOT);
  printf("\n");

  printf(" EFP_PRINT        : 0x%08lx\n", (uint32_t)_EFP_PRINT);
  printf(" EFP_PRINTLN      : 0x%08lx\n", (uint32_t)_EFP_PRINTLN);
  printf(" EFP_PRINTCHAR    : 0x%08lx\n", (uint32_t)_EFP_PRINTCHAR);
  printf(" EFP_HALT         : 0x%08lx\n", (uint32_t)_EFP_HALT);
  printf(" EFP_SENDCHAR     : 0x%08lx\n", (uint32_t)_EFP_SENDCHAR);
  printf(" EFP_RECVCHAR     : 0x%08lx\n", (uint32_t)_EFP_RECVCHAR);
  printf(" EFP_CLRSCR       : 0x%08lx\n", (uint32_t)_EFP_CLRSCR);
  printf(" EFP_MOVEXY       : 0x%08lx\n", (uint32_t)_EFP_MOVEXY);
  printf(" EFP_SETCURSOR    : 0x%08lx\n", (uint32_t)_EFP_SETCURSOR);
  printf(" EFP_CHECKCHAR    : 0x%08lx\n", (uint32_t)_EFP_CHECKCHAR);
  printf(" EFP_PROGLOADER   : 0x%08lx\n", (uint32_t)_EFP_PROGLOADER);
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
    printf(" Test reserved 0x%08lx bytes memory.\n", reserved);
  }
  else
  {
    printf("*** Resident signature detected, test already installed.\n");
    printf(" ... Test signature @ 0x%08lx = 0x%08lx\n", _INITIAL_STACK, *(uint32_t *)_INITIAL_STACK);
  }

  printf("Test prints a message on warm boot and toggles red LED on input.\n");
  printf("\nResident test loader completed.  Press a key: ");
  readchar();

  mcDelaymsec10(100);
  printf("\nExit...\n");

  return 0;
}

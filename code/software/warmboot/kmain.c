/*
 * Copyright (c) 2020 Xark https://hackaday.io/Xark
 */

#include <machine.h>
#include <stdint.h>
#include <stdio.h>
#include <debug_stub.h>

static uint32_t * rom_init_stack = (uint32_t *)&_FIRMWARE[0];
static uint32_t * rom_reset_vector = (uint32_t *)&_FIRMWARE[4];

static uint32_t * init_stack = (uint32_t *)0x0;
static uint32_t * reset_vector = (uint32_t *)0x4;
//static uint32_t * efp_program_loader = (uint32_t *)0x448;

extern void resident_init();

void kmain()
{
  debug_stub();
  mcDelaymsec10(250);
  printf("Simple test/example of rosco_m68k warm reboot\n\n");


  printf("rosco_m68k firmware code: %08X\n", _FIRMWARE_REV);
  
  printf("Default configuration (from ROM)\n");
  printf("--------------------------------\n");
  printf(" Stack will reset to: 0x%08x (%d KiB main RAM)\n", *rom_init_stack, *rom_init_stack / 1024);
  printf("  Reset vector is at: 0x%08x (full reset)\n", *rom_reset_vector);
  printf("\n");
  printf("Current runtime configuration (from RAM)\n");
  printf("----------------------------------------\n");
  printf(" Stack will reset to: 0x%08x (%d KiB main RAM)\n", *init_stack, *init_stack / 1024);
  int32_t reserved = *rom_init_stack - *init_stack;
  if (reserved > 0)
  {
    printf("  (0x%08x bytes reserved)\n", reserved);
  }
  else if (reserved < 0)
  {
    printf("  (%d KiB expansion memory detected)\n", (-reserved) / 1024);
  }
  printf("  Reset vector is at: 0x%08x (soft reset)\n", *reset_vector);

  printf("Program loader is at: 0x%08x\n", (uint32_t)_EFP_PROGLOADER);
  printf("\n");

  // NOTE: This could access past actual RAM (bus error hazard)?
  uint32_t signature = *(uint32_t *)(*init_stack + 0x000);
  if (signature != 0xc0de0042)
  {
    printf("*** Resident signature not detected, installing resident test.\n");
    printf(" ... Initializing resident test.\n");
    uint32_t a7_before;
    __asm__ __volatile__ ("move.l %%a7,%[a7_before]\n" : [a7_before] "=d" (a7_before) : : );
    resident_init();
    uint32_t a7_after;
    __asm__ __volatile__ ("move.l %%a7,%[a7_after]\n" : [a7_after] "=d" (a7_after) : : );
    int32_t reserved = a7_before - a7_after;
    printf(" ... Completed.\n");
    printf("     Reserved 0x%08x bytes memory for resident test.\n", reserved);
  }
  else
  {
    printf("*** Resident signature detected, already installed.\n");
    printf(" ... Test signature @ 0x%08x = 0x%08x\n", *init_stack + 0x000, *(uint32_t *)(*init_stack + 0x000));
  }

  printf("\nResident loader completed.\n\n");

  for (int d = 3; d != 0; d--)
  {
    printf("Warm reboot coming up...%d\n", d);
    mcDelaymsec10(100);
  }
  mcDelaymsec10(100);
  printf("Exit...\n");
  mcDelaymsec10(10);
}

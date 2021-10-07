/*
*------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c)2019 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Memory checker / mapper for rosco_m68k
 * ------------------------------------------------------------
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdnoreturn.h>
#include <machine.h>
#include <basicio.h>

#define RAMBLOCK_FLAG_ONBOARD     0x1
#define RAMBLOCK_FLAG_EXPANSION   0x2
#define RAMBLOCK_FLAG_READONLY    0x4
#define RAMBLOCK_FLAG_SUPERVISOR  0x8
#define RAMBLOCK_FLAG_MAPPEDIO    0x10
#define RAMBLOCK_FLAG_SYSTEM      0x20
#define RAMBLOCK_FLAG_KERNEL      0x40
#define RAMBLOCK_FLAG_SHADOW      0x80

#define MAX_RAMBLOCKS             32

volatile uint8_t BERRFLAG = 0;

typedef struct __MEMBLOCK {
  uint32_t    block_start;
  uint32_t    block_size;
  uint32_t    flags;
} __attribute__ ((packed)) MEMBLOCK;

typedef struct {
  uint32_t    ram_total;
  uint32_t    ram_free;
  MEMBLOCK    blocks[MAX_RAMBLOCKS];
} __attribute__ ((packed)) MEMINFO;

typedef uint32_t KRESULT;

#define KRESULT_SUCCESS           0x0000

#define KRESULT_FAILURE           0x1000
#define KFAILURE_NORESOURCE       0x1001
#define KFAILURE_NOMEM            0x1002

#define IS_KFAILURE(result)   (((result & KRESULT_FAILURE) != 0))

static uint32_t* VERSION = (uint32_t*)&_FIRMWARE_REV;
static uint32_t* FW_MEMSIZE = (uint32_t*)0x414;

extern uint32_t GET_CPU_ID();
extern void INSTALL_BERR_HANDLER();
extern void RESTORE_BERR_HANDLER();

static void zeromeminfo(volatile MEMINFO *header) {
  uint8_t *ptr = (uint8_t*)header;
  for (size_t i = 0; i < sizeof(MEMINFO) + sizeof(MEMBLOCK) * MAX_RAMBLOCKS; i++) {
    *ptr++ = 0;
  }
}

static uint32_t count_rom_size() {
  uint32_t* rom_start = (uint32_t*)&_FIRMWARE;
  uint32_t* current = rom_start + 4;
  uint8_t compare_idx = 0;

  while (((uint32_t)current) < 0x1000000) {
// NOTE: the OK/X display is not right
//    bool match = false;
    if (*current++ == rom_start[compare_idx]) {
//      match = true;
      if (compare_idx == 3) {
        // we have a match - current -  16 (the match) bytes of ROM
        return (uint32_t)current - (((uint32_t)&_FIRMWARE) + 0x10);
      }
      compare_idx++;
    } else {
      compare_idx = 0;
    }
    if (((uint32_t)current) % 4096 == 0) {
      printf("\rScanning for ROM: %ldK/%ldK %s",
          ((uint32_t)current) / 1024,
          ((uint32_t)0x1000000) / 1024,
          "");
// TODO:          match ? "[\033[1;32mOK\033[0m]" : "[\033[1;31mX\033[0m]");
    }
  }

  printf("\rScanning for ROM: %ldK/%ldK [\033[1;32mDone\033[0m]\033[K\n",
      ((uint32_t)current) / 1024,
      ((uint32_t)0x1000000) / 1024);

  // Wow, maximum ROM!
  if (((uint32_t)&_FIRMWARE) == 0x00e00000) {
      return 1024 << 10;
  } else {
      return 256 << 10;
  }
}

static KRESULT build_memory_map(volatile MEMINFO *header) {
  volatile MEMBLOCK * blocks = header->blocks;
  bool block_started = false;

  zeromeminfo(header);

  // Firstly, create blocks for the board ram (known to be 1MB
  // with fixed layout).
  //
  // ISRs and SDB - 0x00000000 - 0x000004FF
  blocks[0].block_start = 0;
  blocks[0].block_size = 0x1000;
  blocks[0].flags = RAMBLOCK_FLAG_ONBOARD | RAMBLOCK_FLAG_SYSTEM;

  // Onboard user RAM - 0x00002000 - 0x0001FFFF
  blocks[1].block_start = 0x1000;
  blocks[1].block_size = 0xFF000;
  blocks[1].flags = RAMBLOCK_FLAG_ONBOARD;

  header->ram_total = 0x100000;
  volatile uint32_t *current = (uint32_t*)0x100000;
  uint8_t current_block = 2;

  uint32_t ending_addr = (uint32_t)_FIRMWARE < (uint32_t)0xF80000 ? (uint32_t)_FIRMWARE : (uint32_t)0xF80000;

  while (true) {
    uint32_t current_addr = (uint32_t)((uint8_t*)current);

    if (current_addr >= ending_addr) {
      current_addr = ending_addr;
      // Reached IO space, end of RAM. Are we in a block?
      if (block_started) {
        blocks[current_block].block_size =
            current_addr - blocks[current_block].block_start;

        header->ram_total += blocks[current_block].block_size;
        current_block++;

        if (current_block == MAX_RAMBLOCKS) {
          printf("\r");
          return KFAILURE_NORESOURCE;
        }
      }

      // Quit loop
      break;
    }

    *current = (uint32_t)current;

    // Just using ram_free as a check variable to avoid phantom bus reads...
    // It's not being used yet anyway.
    header->ram_free = 0xaaaaaaaa;

    if (*current != (uint32_t)current) {
      // Write failed; No usable RAM here. If we're currently in a block...
      if (block_started) {
        // ... then finish it and get ready to start next one.
        blocks[current_block].block_size =
            current_addr - blocks[current_block].block_start;

        block_started = false;
        header->ram_total += blocks[current_block].block_size;
        current_block++;

        if (current_block == MAX_RAMBLOCKS) {
          // Uh-oh, no more blocks :(
          printf("\r");
          return KFAILURE_NORESOURCE;
        }
      }
      current += 16; // skip by 64 bytes to speed scanning
    } else if (!block_started) {
      // There is RAM here and we don't have a current block - start one
      blocks[current_block].block_start = (uint32_t)current;
      blocks[current_block].flags = RAMBLOCK_FLAG_EXPANSION;
      block_started = true;
      current++;
    }

  // NOTE: the OK/X display is not right
    if (current_addr % 65536 == 0) {
      printf("\rScanning for RAM: %ldK/%ldK %s ",
          current_addr / 1024,
          ending_addr / 1024,
          "");
// TODO:          block_started ? "[\033[1;32mOK\033[0m]" : "[\033[1;31mX\033[0m]");
    }
  }
  printf("\rScanning for RAM: %ldK/%ldK [\033[1;32mDone\033[0m]\033[K\n",
      ending_addr / 1024,
      ending_addr / 1024);

  if (current_block == MAX_RAMBLOCKS - 1) {  // We need at least two more blocks
    printf("\r");
    return KFAILURE_NORESOURCE;
  }

  // MAP IO - Just create a block for this...
  // Create a block for IO space
  blocks[current_block].block_start = 0xF80000;
  blocks[current_block].block_size = 0x40000;
  blocks[current_block].flags = RAMBLOCK_FLAG_MAPPEDIO;

  current_block++;

  // MAP ROM
  uint32_t rom_size = count_rom_size();

  blocks[current_block].block_start = (uint32_t)_FIRMWARE;
  blocks[current_block].block_size = rom_size;
  blocks[current_block].flags =
      RAMBLOCK_FLAG_ONBOARD   |
      RAMBLOCK_FLAG_READONLY  |
      RAMBLOCK_FLAG_SYSTEM;

  if (rom_size < (256 << 10)) {
    // We have some shadow ROM, need a block for that..
    if (current_block == MAX_RAMBLOCKS - 1) {  // We need to create 2 at least more blocks
      printf("\r");
      return KFAILURE_NORESOURCE;
    }

    current_block++;

    blocks[current_block].block_start = 0xFC0000 + rom_size;
    blocks[current_block].block_size = (256 << 10) - rom_size;
    blocks[current_block].flags =
        RAMBLOCK_FLAG_ONBOARD   |
        RAMBLOCK_FLAG_READONLY  |
        RAMBLOCK_FLAG_SYSTEM    |
        RAMBLOCK_FLAG_SHADOW;
  }

  printf("\r");
  return KRESULT_SUCCESS;
}

static void print_flags(uint32_t flags) {
  if ((flags & RAMBLOCK_FLAG_READONLY) != 0) {
    printf("[ROM] ");
  }
  else if ((flags & RAMBLOCK_FLAG_MAPPEDIO) != 0) {
    printf("[I/O] ");
  }
  else {
    printf("[RAM] ");
  }
  if ((flags & RAMBLOCK_FLAG_ONBOARD) != 0) {
    printf("[Onboard]");
  }
  if ((flags & RAMBLOCK_FLAG_EXPANSION) != 0) {
    printf("[Expansion]");
  }
  if ((flags & RAMBLOCK_FLAG_SUPERVISOR) != 0) {
    printf("[Supervisor]");
  }
  if ((flags & RAMBLOCK_FLAG_SYSTEM) != 0) {
    printf("[System]");
  }
  if ((flags & RAMBLOCK_FLAG_KERNEL) != 0) {
    printf("[Kernel]");
  }
  if ((flags & RAMBLOCK_FLAG_SHADOW) != 0) {
    printf("[Shadow]");
  }
}

static void print_block(uint8_t i, MEMBLOCK *block) {

  if (block->block_size >= 65536) {

    printf("%02d: 0x%08lx - 0x%08lx (%5ld KiB  ) ",
        i,
        block->block_start,
        block->block_start + block->block_size - 1,
        block->block_size / 1024);
  } else {

    printf("%02d: 0x%08lx - 0x%08lx (%5ld bytes) ",
        i,
        block->block_start,
        block->block_start + block->block_size - 1,
        block->block_size);
  }

  print_flags(block->flags);
  printf("\n");
}

char* get_cpu_display_name(uint32_t cpu_id) {
  switch (cpu_id) {
    case 0:
      return "MC68000";
    case 1:
      return "MC68010";
    case 2:
      return "MC68020";
    case 3:
      return "MC68030";
    case 4:
      return "MC68040";
    case 6:
      return "MC68060";
    default:
      return "<WEIRD>";
  }
}

static void show_banner() {
  bool snapshot = (*VERSION) & 0x80000000;
  uint16_t wver = (*VERSION) * 0x0000FFFF;
  uint8_t major = ((*VERSION) & 0x0000FF00) >> 8;
  uint8_t minor = (*VERSION) & 0x000000FF;
  char *cpu_name = get_cpu_display_name(GET_CPU_ID());

  if (major == 0x07 && minor == 0x00) {
    // special case - 1.0 didn't include version
    major = 0x01;
    minor = 0x01;
  }

  printf("\033[H\033[2J");
  printf("***********************************************************\n");
  printf("*                                                         *\n");
  printf("*          \033[93mrosco_m68k\033[m SysInfo & MemCheck utility          *\n");
  printf("*        %s CPU with Firmware ", cpu_name);
  printf("%d.%-2d", major, minor);
  if (snapshot) {
    printf(" [SNAPSHOT]");
  } else {
    printf(" [RELEASE ]");
  }
  printf("        *\n");
  if (wver >= 0x0120) {
    printf("* Firmware reports %8ld bytes total contiguous memory *\n", *FW_MEMSIZE);
  }
  printf("*                                                         *\n");
  printf("***********************************************************\n");
  printf("\n");
}

/* Build a memory map at _end (start of 'heap').
 *
 * This map always consists of one MEMINFO header,
 * followed by MAX_RAMBLOCKS blocks.
 *
 * The blocks are kept in order of their starting
 * address. Blocks with zero start and size are
 * unused.
 */
extern const void* _end;
static MEMINFO* header = (MEMINFO*)&_end;

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;

  show_banner();

  INSTALL_BERR_HANDLER();

  printf("Building memory map, please wait this may take a while...\n\n");
  KRESULT result = build_memory_map(header);

  if (IS_KFAILURE(result)) {
    printf("Failed to build memory map (0x%04lx)\n", result);
  } else {
    printf("Map built successfully\033[K\n\033[K\n");

    for (uint8_t i = 0; i < MAX_RAMBLOCKS; i++) {
      if (header->blocks[i].block_size == 0) {
        break;
      }
      print_block(i, &header->blocks[i]);
    }

    RESTORE_BERR_HANDLER();

    printf("\nComplete; Found a total of %ld bytes of writeable RAM\n\n", header->ram_total);
  }

  printf("(Press a key)\n");
  readchar();

  return 0;
}

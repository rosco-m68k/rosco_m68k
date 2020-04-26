/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
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

#define RAMBLOCK_FLAG_ONBOARD     0x1
#define RAMBLOCK_FLAG_EXPANSION   0x2
#define RAMBLOCK_FLAG_READONLY    0x4
#define RAMBLOCK_FLAG_SUPERVISOR  0x8
#define RAMBLOCK_FLAG_MAPPEDIO    0x10
#define RAMBLOCK_FLAG_SYSTEM      0x20
#define RAMBLOCK_FLAG_KERNEL      0x40
#define RAMBLOCK_FLAG_SHADOW      0x80

#define MAX_RAMBLOCKS             32 

typedef struct __MEMBLOCK {
  uint32_t    block_start;
  uint32_t    block_size;
  uint32_t    flags;
} __attribute__ ((packed)) MEMBLOCK;
  
typedef struct {
  uint32_t    ram_total;
  uint32_t    ram_free;
} __attribute__ ((packed)) MEMINFO;

typedef uint32_t KRESULT;

#define KRESULT_SUCCESS           0x0000

#define KRESULT_FAILURE           0x1000
#define KFAILURE_NORESOURCE       0x1001
#define KFAILURE_NOMEM            0x1002

#define IS_KFAILURE(result)   (((result & KRESULT_FAILURE) != 0))

static void zeromeminfo(MEMINFO *header) {
  uint8_t *ptr = (uint8_t*)header;
  for (int i = 0; i < sizeof(MEMINFO) + sizeof(MEMBLOCK) * MAX_RAMBLOCKS; i++) {
    *ptr++ = 0;
  }
}

static uint32_t count_rom_size() {
  uint32_t* rom_start = (uint32_t*)0xFC0000;
  uint32_t* current = rom_start + 4;
  uint8_t compare_idx = 0;

  while (((uint32_t)current) < 0x1000000) {
    if (*current++ == rom_start[compare_idx]) {
      if (compare_idx == 3) {
        // we have a match - current -  16 (the match) bytes of ROM
        return (uint32_t)current - 0xFC0010;
      }

      if (((uint32_t)current) % 4096 == 0) {
        printf("\033[20DROM: %dK %s", 
            ((uint32_t)current) / 1024, "[\033[1;32m✔\033[0m]");
      }

      compare_idx++;
    } else {
      compare_idx = 0;
    }
  }
  
  // Wow, 256KB of ROM!
  return 256 << 10;
}

static KRESULT build_memory_map(MEMINFO *header) {
  MEMBLOCK * volatile blocks = (MEMBLOCK*)(((uint8_t*)header) + sizeof(MEMINFO));
  bool block_started = false;

  zeromeminfo(header);

  // Firstly, create blocks for the board ram (known to be 1MB
  // with fixed layout).
  // 
  // ISRs and SDB - 0x00000000 - 0x000004FF
  blocks[0].block_start = 0;
  blocks[0].block_size = 0x500;
  blocks[0].flags = RAMBLOCK_FLAG_ONBOARD | RAMBLOCK_FLAG_SYSTEM;

  // Kernel bss, data and (old) stack - 0x00000500 - 0x00001FFF
  blocks[1].block_start = 0x500;
  blocks[1].block_size = 0x1B00;
  blocks[1].flags = RAMBLOCK_FLAG_ONBOARD | RAMBLOCK_FLAG_KERNEL;

  // Onboard user RAM - 0x00002000 - 0x0001FFFF
  blocks[2].block_start = 0x2000;
  blocks[2].block_size = 0xFE000;
  blocks[2].flags = RAMBLOCK_FLAG_ONBOARD;

  header->ram_total = 0x100000;
  uint32_t *current = (uint32_t*)0x100000;
  uint8_t current_block = 3;

  while (true) {
    uint32_t current_addr = (uint32_t)((uint8_t*)current);

    if (current_addr >= 0xF80000) {
      // Reached IO space, end of RAM. Are we in a block?
      if (block_started) {
        blocks[current_block].block_size = 
            current_addr - blocks[current_block].block_start;

        header->ram_total += blocks[current_block].block_size;
        current_block++;
        
        if (current_block == MAX_RAMBLOCKS) {
          printf("\033[20D");
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
          printf("\033[20D");
          return KFAILURE_NORESOURCE;
        }
      }
    } else if (!block_started) {
      // There is RAM here and we don't have a current block - start one
      blocks[current_block].block_start = (uint32_t)current;
      blocks[current_block].flags = RAMBLOCK_FLAG_EXPANSION;
      block_started = true;
    }

    current++;

    if (current_addr % 65536 == 0) {
      printf("\033[20DRAM: %dK %s", 
          current_addr / 1024, 
          block_started ? "[\033[1;32m✔\033[0m]" : "[\033[1;31m✗\033[0m]");
    }
  }

  if (current_block == MAX_RAMBLOCKS - 1) {  // We need at least two more blocks
    printf("\033[20D");
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

  blocks[current_block].block_start = 0xFC0000;
  blocks[current_block].block_size = rom_size;
  blocks[current_block].flags = 
      RAMBLOCK_FLAG_ONBOARD   | 
      RAMBLOCK_FLAG_READONLY  | 
      RAMBLOCK_FLAG_SYSTEM;

  if (rom_size < (256 << 10)) {
    // We have some shadow ROM, need a block for that..
    if (current_block == MAX_RAMBLOCKS - 1) {  // We need to create 2 at least more blocks
      printf("\033[20D");
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
  
  printf("\033[20D");
  return KRESULT_SUCCESS;
}

static void print_flags(uint32_t flags) {
  if ((flags & RAMBLOCK_FLAG_ONBOARD) != 0) {
    printf("[Onboard]");
  }
  if ((flags & RAMBLOCK_FLAG_EXPANSION) != 0) {
    printf("[Expansion]");
  }
  if ((flags & RAMBLOCK_FLAG_READONLY) != 0) {
    printf("[Readonly]");
  }
  if ((flags & RAMBLOCK_FLAG_SUPERVISOR) != 0) {
    printf("[Supervisor]");
  }
  if ((flags & RAMBLOCK_FLAG_MAPPEDIO) != 0) {
    printf("[MappedIO]");
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
  
    printf("%02d: 0x%08x - 0x%08x (%5d KiB  ) ", 
        i, 
        block->block_start, 
        block->block_start + block->block_size - 1, 
        block->block_size / 1024);
  } else {
  
    printf("%02d: 0x%08x - 0x%08x (%5d bytes) ", 
        i, 
        block->block_start, 
        block->block_start + block->block_size - 1, 
        block->block_size);
  }

  print_flags(block->flags);
  printf("\r\n");
}

/* System-wide memory map. Stored in SDB at 0x410.
 *
 * This map always consists of one MEMINFO header,
 * followed by MAX_RAMBLOCKS blocks.
 *
 * The blocks are kept in order of their starting
 * address. Blocks with zero start and size are 
 * unused.
 */
MEMINFO * volatile header = (MEMINFO*)0x410;

noreturn void kmain() {
  MEMBLOCK * volatile blocks = (MEMBLOCK*)(((uint8_t*)header) + sizeof(MEMINFO));

  printf("Building memory map...\r\n");
  KRESULT result = build_memory_map(header);

  if (IS_KFAILURE(result)) {
    printf("Failed to build memory map (0x%04x)\r\n", result);
  } else {
    printf("Map build successfully 😃\r\n");

    uint8_t current_block = 0;

    while(blocks[current_block].block_size > 0) {
      print_block(current_block, &blocks[current_block]);
      current_block++;
    }

    printf("Complete; Found a total of %d bytes of writeable RAM\r\n\r\n", header->ram_total);
  }

  mcHalt();
}


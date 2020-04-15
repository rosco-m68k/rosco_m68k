/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

#define RAMBLOCK_FLAG_ONBOARD     0x1
#define RAMBLOCK_FLAG_EXPANSION   0x2
#define RAMBLOCK_FLAG_READONLY    0x4
#define RAMBLOCK_FLAG_SUPERVISOR  0x8
#define RAMBLOCK_FLAG_MAPPEDIO    0x10
#define RAMBLOCK_FLAG_SYSTEM      0x20
#define RAMBLOCK_FLAG_KERNEL      0x40

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

  // Kernel bss, data and stack - 0x00000500 - 0x00001FFF
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
        blocks[current_block].block_size = current_addr - blocks[current_block].block_start;
        header->ram_total += blocks[current_block].block_size;
        current_block++;
        
        if (current_block == MAX_RAMBLOCKS) {
          return KFAILURE_NORESOURCE;
        }
      }

      printf("\033[20D");

      // Quit loop
      break;
    }

    *current = (uint32_t)current;

    // Just using ram_free as a check variable to avoid phantom bus reads...
    // It's not being used yet anyway. 
    header->ram_free = 0xaaaaaaaa;

    if (*current != (uint32_t)current) {
      // Write failed; No usable RAM here. Are we currently in a block?
      if (block_started) {
        // yes - finish it and get ready to start next one.
        blocks[current_block].block_size = current_addr - blocks[current_block].block_start;
        block_started = false;
        header->ram_total += blocks[current_block].block_size;
        current_block++;
  
        if (current_block == MAX_RAMBLOCKS) {
          return KFAILURE_NORESOURCE;
        }
      }
    } else {
      // There is RAM here - are we currently in a block?
      if (!block_started) {
        // No - start one
        blocks[current_block].block_start = (uint32_t)current;
        blocks[current_block].flags = RAMBLOCK_FLAG_EXPANSION;
        block_started = true;
      }
    }

    current++;

    if (current_addr % 65536 == 0) {
      printf("\033[20D%dK %s", current_addr / 1024, block_started ? "[\033[1;32m✔\033[0m]" : "[\033[1;31m✗\033[0m]");
    }
  }

  // Create a block for IO space
  blocks[current_block].block_start = 0xF80000;
  blocks[current_block].block_size = 0x40000;
  blocks[current_block].flags = RAMBLOCK_FLAG_MAPPEDIO;

  current_block++;

  if (current_block == MAX_RAMBLOCKS) {
    return KFAILURE_NORESOURCE;
  }

  // Create a block for ROM space
  blocks[current_block].block_start = 0xFC0000;
  blocks[current_block].block_size = 0x40000;
  blocks[current_block].flags = RAMBLOCK_FLAG_ONBOARD | RAMBLOCK_FLAG_READONLY | RAMBLOCK_FLAG_SYSTEM;
  
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
}

static void print_block(uint8_t i, MEMBLOCK *block) {
  if (block->block_size >= 65536) {
    printf("%02d: 0x%08x - 0x%08x (%5d KiB  ) ", i, block->block_start, block->block_start + block->block_size - 1, block->block_size / 1024);
  } else {
    printf("%02d: 0x%08x - 0x%08x (%5d bytes) ", i, block->block_start, block->block_start + block->block_size - 1, block->block_size);
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

void kmain() {
  MEMBLOCK * volatile blocks = (MEMBLOCK*)(((uint8_t*)header) + sizeof(MEMINFO));
//  __asm__ __volatile__ ("or.w   #0x2700,%sr");

  printf("Building memory map...\r\n");
//  uint32_t result;

//  while (true) {
//    *direct = 0xaaaaaaaa;
//    result = *direct;
//  }

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

  while (true) {
    // nothing
  }
}


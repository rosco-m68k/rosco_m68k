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
  MEMBLOCK    blocks[MAX_RAMBLOCKS];
} __attribute__ ((packed)) MEMINFO;

typedef uint32_t KRESULT;

#define KRESULT_SUCCESS           0x0000

#define KRESULT_FAILURE           0x1000
#define KFAILURE_NORESOURCE       0x1001
#define KFAILURE_NOMEM            0x1002

#define IS_KFAILURE(result)   (((result & KRESULT_FAILURE) != 0))

static uint32_t* VERSION = (uint32_t*)0xfc0400;
static uint32_t* FW_MEMSIZE = (uint32_t*)0x414;

extern uint32_t GET_CPU_ID();

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
        printf("\rROM: %dK %s", 
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
  MEMBLOCK * blocks = header->blocks;
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
  uint32_t *current = (uint32_t*)0x100000;
  uint8_t current_block = 2;

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
    } else if (!block_started) {
      // There is RAM here and we don't have a current block - start one
      blocks[current_block].block_start = (uint32_t)current;
      blocks[current_block].flags = RAMBLOCK_FLAG_EXPANSION;
      block_started = true;
    }

    current++;

    if (current_addr % 65536 == 0) {
      printf("\rRAM: %dK %s", 
          current_addr / 1024, 
          block_started ? "[\033[1;32m✔\033[0m]" : "[\033[1;31m✗\033[0m]");
    }
  }

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

  blocks[current_block].block_start = 0xFC0000;
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
  printf("\n");
}

char* get_cpu_display_name(uint32_t cpu_id) {
  switch (GET_CPU_ID()) {
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

  printf("\n\n"); 
  printf("***********************************************************\n");
  printf("*                                                         *\n");
  printf("*          rosco_m68k SysInfo & MemCheck utility          *\n");
  printf("*        %s CPU with Firmware ", cpu_name);
  printf("%x.%x", major, minor);
  if (snapshot) {
    printf(" [SNAPSHOT]");
  } else { 
    printf(" [RELEASE ]");
  }
  printf("        *\n");
  if (wver >= 0x0120) {
    printf("* Firmware reports %8d bytes total contiguous memory *\n", *FW_MEMSIZE);
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

void kmain() {
  show_banner();

  printf("Building memory map, please wait...\n");
  KRESULT result = build_memory_map(header);

  if (IS_KFAILURE(result)) {
    printf("Failed to build memory map (0x%04x)\n", result);
  } else {
    printf("Map built successfully\n");

    for (uint8_t i = 0; i < MAX_RAMBLOCKS; i++) {
      if (header->blocks[i].block_size == 0) {
        break;
      }
      print_block(i, &header->blocks[i]);
    }

    printf("Complete; Found a total of %d bytes of writeable RAM\n\n", header->ram_total);
  }
}

// Use custom __kinit (called by serial_start init.S before kmain) to set juggle stack around
// and call main. Workaround for #135.
extern uint32_t _data_start, _data_end, _code_end, _bss_start, _bss_end;

// The aforementioned Dragons! the subql #4,%sp mirrors what GCC does with -fomit-frame-pointer,
// which is why that option is necessary. Without it, the postamble (?) of the function
// won't clean up the (new) stack correctly...
void __kinit()
{
    __asm__ __volatile__(" move.l  #100000,%%sp\n"
                         " move.l  4.w,-(%%sp)\n"
                         " subql   #4,%%sp"
                         :
                         :
                         :);
    // zero .bss
    for (uint32_t * dst = &_bss_start; dst < &_bss_end; dst++)
    {
        *dst = 0;
    }

    kmain();      // call kmain here

    // Returning here will go to the reset vector we pushed earlier...
}


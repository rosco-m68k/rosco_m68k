/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2022 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Kernel loader for stage 2
 * ------------------------------------------------------------
 */

#include <stdbool.h>
#include <stdint.h>
#include <string.h>
#include "load.h"
#include "elf.h"
#include "fat_filelib.h"
#include "machine.h"
#include "part.h"
#include "system.h"

extern void print_unsigned(uint32_t num, uint8_t base);

extern uint8_t *kernel_load_ptr;
extern KMain kernel_entry;
static volatile SystemDataBlock * const sdb = (volatile SystemDataBlock * const)0x400;

extern char STAGE2_LOAD[];
extern char _end[];

static const char FILENAME_BIN[] = "/ROSCODE1.BIN";
static const char FILENAME_ELF[] = "/ROSCODE1.ELF";

static const size_t BLOCK_SIZE = 512;
static const unsigned BLOCKS_PER_DOT = 8;
static const unsigned BYTES_PER_DOT = BLOCKS_PER_DOT * BLOCK_SIZE;

static PartHandle *load_part;
static uint8_t load_part_num;

static int media_read(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    return Part_read(load_part, load_part_num, buffer, sector, sector_count) == sector_count ? 1 : 0;
}

static int media_write(uint32_t sector, uint8_t *buffer, uint32_t sector_count) {
    return 0;
}

bool load_kernel_bin(void *file) {
    uint32_t start = sdb->upticks;

    int c;
    uint8_t *current_load_ptr = kernel_load_ptr;
    uint8_t b = 0;
    while ((c = fl_fread(current_load_ptr, BLOCK_SIZE, 1, file)) > 0) {
        current_load_ptr += c;
        if (++b == BLOCKS_PER_DOT) {
            FW_PRINT_C(".");
            b = 0;
        }
    }
    FW_PRINT_C("\r\n");

    if (c != EOF) {
        FW_PRINT_C("*** Kernel load error\r\n");

        return false;
    } else {
        uint32_t total_ticks = sdb->upticks - start;
        uint32_t total_secs = (total_ticks + 50) / 100;
        uint32_t load_size = current_load_ptr - kernel_load_ptr;
        FW_PRINT_C("Loaded ");
        print_unsigned(load_size, 10);
        FW_PRINT_C(" bytes in ~");
        print_unsigned(total_secs ? total_secs : 1, 10);
        FW_PRINT_C(" sec.\r\n");

        return true;
    }
}

static bool load_range_allowed(uintptr_t start, size_t size) {
    if (size == 0) {
        // If there's nothing to load, we don't care, allow it
        return true;
    }

    // Use last instead of `end = start + size` to avoid overflowing
    const size_t offset_last = size - 1;
    if (start > UINTPTR_MAX - offset_last) {
        // Last byte address would overflow
        return false;
    }
    const uintptr_t last = start + offset_last;

    const size_t page_size = 0x1000;
    const uintptr_t page_mask = ~(uintptr_t) (page_size - 1);
    // Dummy variable to get stack pointers
    volatile char dummy;
    const uintptr_t dummy_addr = (uintptr_t) &dummy;
    // Leave at least one full page below the dummy on the stack
    const uintptr_t stack_guard_start = (dummy_addr - page_size) & page_mask;

    // Check for overlaps with reserved memory
    if (last >= 0 && start < 0x2000) {
        // Is in the exception vectors, SDB, EFPT, VDA, or firmware-reserved areas
        return false;
    } else if (last >= (uintptr_t) &STAGE2_LOAD && start < (uintptr_t) &_end) {
        // Is in stage2
        return false;
    } else if (last >= stack_guard_start && start < sdb->memsize) {
        // Is in the stack
        return false;
    }

    return true;
}

static long load_kernel_elf_phdr_load(void *file, Elf32_Phdr *phdr) {
    // TODO: Validate other fields
    if (phdr->p_align > 0) {
        if (phdr->p_vaddr % phdr->p_align != phdr->p_offset % phdr->p_align) {
            FW_PRINT_C("\r\n*** Invalid loadable segment alignment\r\n");
            return -1;
        }
    }

    // Don't allow overwriting firmware-reserved areas, stage2, or stack
    if (!load_range_allowed(phdr->p_vaddr, phdr->p_memsz)) {
            FW_PRINT_C("\r\n*** Segment would overwrite firmware memory\r\n");
            return -1;
    }

    if (fl_fseek(file, phdr->p_offset, SEEK_SET) != 0) {
        FW_PRINT_C("\r\n*** Failed to seek to loadable segment\r\n");
        return -1;
    }

    // Load bytes from segment file image
    size_t this_count;
    for (size_t count_done = 0; count_done < phdr->p_filesz; count_done += this_count) {
        size_t count_to_do = phdr->p_filesz - count_done;
        this_count = count_to_do > BYTES_PER_DOT ? BYTES_PER_DOT : count_to_do;

        if (fl_fread((void *) (phdr->p_vaddr + count_done), 1, this_count, file) != this_count) {
            FW_PRINT_C("\r\n*** Couldn't read loadable segment\r\n");
            return -1;
        }

        FW_PRINT_C(".");
    }

    // Clear remaining bytes in segment memory image
    memset((void *) (phdr->p_vaddr + phdr->p_filesz), 0, phdr->p_memsz - phdr->p_filesz);

    return phdr->p_filesz;
}

bool load_kernel_elf(void *file) {
    uint32_t start = sdb->upticks;

    // Load ELF header
    Elf32_Ehdr ehdr;
    if (fl_fread(&ehdr, sizeof(ehdr), 1, file) != sizeof(ehdr)) {
        FW_PRINT_C("\r\n*** Couldn't read ELF header\r\n");
        return false;
    }

    // Validate ELF header identification
    if (ehdr.e_ident[EI_MAG0] != ELFMAG0 || ehdr.e_ident[EI_MAG1] != ELFMAG1 ||
        ehdr.e_ident[EI_MAG2] != ELFMAG2 || ehdr.e_ident[EI_MAG3] != ELFMAG3) {
        FW_PRINT_C("\r\n*** Not an ELF file\r\n");
        return false;
    } else if (ehdr.e_ident[EI_CLASS] != ELFCLASS32) {
        FW_PRINT_C("\r\n*** ELF file does not use 32-bit objects\r\n");
        return false;
    } else if (ehdr.e_ident[EI_DATA] != ELFDATA2MSB) {
        FW_PRINT_C("\r\n*** ELF file does not use big-endian objects\r\n");
        return false;
    } else if (ehdr.e_ident[EI_VERSION] != EV_CURRENT) {
        FW_PRINT_C("\r\n*** ELF file does not use a compatible version\r\n");
        return false;
    }

    // Validate ELF header
    if (ehdr.e_type != ET_EXEC) {
        FW_PRINT_C("\r\n*** ELF file is not an executable file\r\n");
        return false;
    } else if (ehdr.e_machine != EM_68K) {
        FW_PRINT_C("\r\n*** ELF file is not for Motorola 68000\r\n");
        return false;
    } else if (ehdr.e_version != EV_CURRENT) {
        FW_PRINT_C("\r\n*** ELF file does not use a compatible version\r\n");
        return false;
    } else if (ehdr.e_ehsize != sizeof(ehdr)) {
        FW_PRINT_C("\r\n*** ELF file header has an unexpected size\r\n");
        return false;
    }

    // Process program headers
    uint32_t load_size = 0;
    if (ehdr.e_phoff == 0) {
        FW_PRINT_C("\r\n*** ELF file has no program header table\r\n");
        return false;
    }
    if (ehdr.e_phentsize != sizeof(Elf32_Phdr)) {
        FW_PRINT_C("\r\n*** ELF file program header entries have an unexpected size\r\n");
        return false;
    }
    for (Elf32_Half phidx = 0; phidx < ehdr.e_phnum; ++phidx) {
        if (fl_fseek(file, ehdr.e_phoff + phidx * ehdr.e_phentsize, SEEK_SET) != 0) {
            FW_PRINT_C("\r\n*** Failed to seek to ELF program header\r\n");
            return false;
        }

        Elf32_Phdr phdr;
        if (fl_fread(&phdr, ehdr.e_phentsize, 1, file) != ehdr.e_phentsize) {
            FW_PRINT_C("\r\n*** Couldn't read ELF program header\r\n");
            return false;
        }

        switch (phdr.p_type) {
        case PT_NULL:
            break;
        case PT_LOAD: {
            long phdr_result = load_kernel_elf_phdr_load(file, &phdr);
            if (phdr_result < 0) {
                return false;
            } else {
                load_size += (size_t) phdr_result;
            }
            break; }
        }
    }
    FW_PRINT_C("\r\n");

    if (ehdr.e_entry != 0) {
        kernel_entry = (KMain) ehdr.e_entry;
    } else {
        FW_PRINT_C("*** ELF file has no entry point\r\n");
        return false;
    }

    uint32_t total_ticks = sdb->upticks - start;
    uint32_t total_secs = (total_ticks + 50) / 100;
    FW_PRINT_C("Loaded ");
    print_unsigned(load_size, 10);
    FW_PRINT_C(" bytes in ~");
    print_unsigned(total_secs ? total_secs : 1, 10);
    FW_PRINT_C(" sec.\r\n");

    return true;
}

bool load_kernel(PartHandle *part) {
    load_part = part;

    for (int i = 0; i < 4; i++) {
        if (Part_valid(part, i)) {
            load_part_num = i;
            FW_PRINT_C("  Partition ");
            print_unsigned(load_part_num + 1, 10);  // Print partition numbers as 1-indexed
            FW_PRINT_C(": ");

            fl_attach_media(media_read, media_write);

            void *file;
            if ((file = fl_fopen(FILENAME_BIN, "r"))) {
                FW_PRINT_C("Loading \"");
                FW_PRINT_C(FILENAME_BIN);
                FW_PRINT_C("\"");
                bool result = load_kernel_bin(file);
                fl_fclose(file);
                return result;
            } else if ((file = fl_fopen(FILENAME_ELF, "r"))) {
                FW_PRINT_C("Loading \"");
                FW_PRINT_C(FILENAME_ELF);
                FW_PRINT_C("\"");
                bool result = load_kernel_elf(file);
                fl_fclose(file);
                return result;
            } else {
                FW_PRINT_C("(not bootable)\r\n");
            }
        }
    }

    return false;
}

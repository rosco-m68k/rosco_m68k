/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|           stdlibs 
 * ------------------------------------------------------------
 * Copyright (c)2020-2021 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Pre-main initialization and cxa_atexit for rosco_m68k.
 * ------------------------------------------------------------
 */

#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

// I don't really know how many of these is enough... This will take up 16KB.
#define MAX_CXA_ATEXITS 1024

typedef void (*cxa_atexit_func)(void *);

typedef struct {
    cxa_atexit_func func;
    void            *ptr;
    void            *dso_handle;
    bool            done;
} cxa_atexit_entry;    

// Linker defines
extern uint32_t _data_start, _data_end, _code_end, _bss_start, _bss_end;

static cxa_atexit_entry cxa_atexits[MAX_CXA_ATEXITS];
static uint16_t cxa_atexit_count;

void *__dso_handle;

__attribute__((weak)) void __kinit() {
  // zero .bss
  for (uint32_t *dst = &_bss_start; dst < &_bss_end; *dst++ = 0);
}

int __cxa_atexit ( void (*f)(void *), void *p, void *d ) {
    if (cxa_atexit_count == MAX_CXA_ATEXITS) {
        return 1; // failure!
    } else {
        cxa_atexit_entry *entry = &cxa_atexits[cxa_atexit_count++];

        entry->func = f;
        entry->ptr = p;
        entry->dso_handle = d;
        entry->done = false;

        return 0;
    }
}

/*
 * We probably don't need the full dso_handle capability as we're always
 * statically linked, but I'd rather do a proper impl now than have it 
 * break later because of a half-baked one :D
 */
void __cxa_finalize(void *dso_handle) {
    for (int i = cxa_atexit_count - 1; i >= 0; i--) {
        cxa_atexit_entry *entry = &cxa_atexits[i];

        if ((dso_handle == NULL || dso_handle == entry->dso_handle) && !entry->done) {
            entry->func(entry->ptr);
            entry->done = true;
        }
    }
}


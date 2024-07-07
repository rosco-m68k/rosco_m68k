#include <stdint.h>
#include <stdio.h>

#include "py/builtin.h"
#include "py/compile.h"
#include "py/gc.h"
#include "py/mperrno.h"
#include "py/stackctrl.h"
#include "shared/runtime/gchelper.h"
#include "shared/runtime/pyexec.h"

extern uint32_t _end;
volatile uint32_t *memsize = (uint32_t*)0x414;

int main() {
    // Set up MP heap.
    uint32_t l_memsize = *memsize;
    void *heap_begin;

    if (l_memsize > 0x100000) {
        // just use expansion RAM, ignore the onboard
        // naive hack, but it'll do for now...
        heap_begin = (void*)0x100000;
    } else {
        heap_begin = &_end;
    }

    // Initialise the MicroPython runtime.
    mp_stack_ctrl_init();
    gc_init(heap_begin, ((void*)(*memsize - 32768)));
    mp_init();

    // Start a normal REPL; will exit when ctrl-D is entered on a blank line.
    pyexec_friendly_repl();

    // Deinitialise the runtime.
    gc_sweep_all();
    mp_deinit();
    return 0;
}

// Handle uncaught exceptions (should never be reached in a correct C implementation).
void nlr_jump_fail(void *val) {
    for (;;) {
    }
}

// Do a garbage collection cycle.
void gc_collect(void) {
    gc_collect_start();
    gc_helper_collect_regs_and_stack();
    gc_collect_end();
}

// void gc_collect(void) {
//     // WARNING: This gc_collect implementation doesn't try to get root
//     // pointers from CPU registers, and thus may function incorrectly.
//     void *dummy;
//     gc_collect_start();
//     gc_collect_root(&dummy, ((mp_uint_t)stack_top - (mp_uint_t)&dummy) / sizeof(mp_uint_t));
//     gc_collect_end();
//     // gc_dump_info();
// }

// There is no filesystem so stat'ing returns nothing.
mp_import_stat_t mp_import_stat(const char *path) {
    return MP_IMPORT_STAT_NO_EXIST;
}

// There is no filesystem so opening a file raises an exception.
mp_lexer_t *mp_lexer_new_from_file(qstr filename) {
    mp_raise_OSError(MP_ENOENT);
}
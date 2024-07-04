#include <stdint.h>
#include "py/mpconfig.h"

static inline mp_uint_t mp_hal_ticks_ms(void) {
    return *((uint32_t*)0x40C);
}

static inline void mp_hal_set_interrupt_char(char c) {
}

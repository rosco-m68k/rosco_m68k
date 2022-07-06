/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 *  __ __
 * |  |  |___ ___ ___ ___ ___
 * |-   -| . |_ -| -_|  _| .'|
 * |__|__|___|___|___|_| |__,|
 *
 * Xark's Open Source Enhanced Retro Adapter
 *
 * - "Not as clumsy or random as a GPU, an embedded retro
 *    adapter for a more civilized age."
 *
 * ------------------------------------------------------------
 * Copyright (c) 2021 Xark
 * MIT License
 *
 * Xosera rosco_m68k low-level C API for Xosera registers
 * ------------------------------------------------------------
 */

#if !defined(XOSERA_M68K_API_H)
#define XOSERA_M68K_API_H

#include <stdbool.h>
#include <stdint.h>
// Low-level C API macro reference (act like functions as shown):

// set XM registers (main registers, omit XM_ from xmreg name):
// void     xm_setbh(xmreg, high_byte)
// void     xm_setbl(xmreg, low_byte)
// void     xm_setw(xmreg, word_value)
// void     xm_setl(xmreg, long_value)
// void     xm_set_rw_rd_incr()
// void     xm_set_no_rw_rd_incr()

// set XR register (extended registers, omit XR_ from xreg name):
// void     xreg_setw(xreg, word_value)
// void     xreg_set_addr(xreg)
// void     xreg_setw_next(word_value)

// set XR memory address (or XR register):
// void     xmem_setw(xrmem, word_value)
// void     xmem_set_addr(xrmem)
// void     xmem_setw_next(word_value)
// void     xmem_setw_wait(xrmem, wordval)
// void     xmem_setw_next_wait(word_value)

// get XM registers (main registers):
// uint8_t  xm_get_sys_ctrlb(bit_name)   (SYS_CTRL_<bit_name>_B)
// uint8_t  xm_getbh(xmreg)             (omit XM_ from xmreg name)
// uint8_t  xm_getbl(xmreg)             (omit XM_ from xmreg name)
// uint16_t xm_getw(xmreg)              (omit XM_ from xmreg name)
// uint32_t xm_getl(xmreg)              (omit XM_ from xmreg name)

// get XR registers (extended registers):
// uint16_t xreg_getw(xreg)             (omit XR_ from xreg name)
// uint16_t xreg_get_addr(xreg)         (omit XR_ from xreg name)
// uint16_t xreg_getw_next(xreg)        (omit XR_ from xreg name)

// NOTE: "*_wait" functions wait if there is memory contention (with xwait_mem_ready() before a read or after a write).
// In most video modes, other than reading COLOR_MEM, wait will not be needed as there will be enough free XR or VRAM
// memory cycles available. However, with certain video modes or combinations with both playfields the wait may be
// needed for reliable operation (especially when reading memories used during video display).
// TODO: test and verify exactly when "*_wait" functions are required

// get XR memory address (or XR register):
// uint16_t xmem_getw(xrmem)
// void xmem_get_addr(xrmem)
// uint16_t xmem_getw_next()
// uint16_t xmem_getw_wait(xrmem)
// uint16_t xmem_getw_next_wait()
// wait for status (busy wait until condition true)
// NOTE: May hang if condition not met (or Xosera not present/operating)
// void     xwait_ctrl_bit_set(bit_name)
// void     xwait_ctrl_bit_clear(bit_name)
// void     xwait_mem_ready()
// void     xwait_blit_ready()
// void     xwait_blit_done()
// void     xwait_hblank()
// void     xwait_not_hblank()
// void     xwait_vblank()
// void     xwait_not_vblank()

typedef struct _xosera_info xosera_info_t;        // forward declare

// external function declarations
bool xosera_init(int reconfig_num);                // wait a bit for Xosera to respond and optional reconfig (if 0 to 3)
bool xosera_get_info(xosera_info_t * info);        // retrieve init xosera_info_t (valid after xosera reconfig)
bool xosera_sync();                                // true if Xosera present and responding
void xosera_memclear(void * ptr, unsigned int n);        // memory zero
void cpu_delay(int ms);                                  // delay approx milliseconds with CPU busy wait
void xv_delay(uint32_t ms);                              // delay milliseconds using Xosera TIMER

#include "xosera_m68k_defs.h"

// C preprocessor "stringify" to embed #define into inline asm string
#define _XM_STR(s) #s
#define XM_STR(s)  _XM_STR(s)

// NOTE: Since Xosera is using a 6800-style 8-bit bus, it uses only data lines 8-15 of each 16-bit word (i.e., only the
//       upper byte of each word) this makes the size of its register map in memory appear doubled and is the reason for
//       the pad bytes in the struct below.  Byte access is fine but for word or long access to this struct, the MOVEP
//       680x0 instruction should be used (it was designed for this purpose).  The xv-set* and xv_get* macros below make
//       it easy.
typedef struct _xreg
{
    union
    {
        struct
        {
            volatile uint8_t h;
            volatile uint8_t _h_pad;
            volatile uint8_t l;
            volatile uint8_t _l_pad;
        } b;
        const volatile uint16_t w;        // NOTE: For use as offset only with xv_setw (and MOVEP.W opcode)
        const volatile uint32_t l;        // NOTE: For use as offset only with xv_setl (and MOVEP.L opcode)
    };
} xmreg_t;

// stored at XV_INFO_ADDR after FPGA reconfigure
typedef struct _xosera_info
{
    char          description_str[48];        // ASCII description
    uint16_t      reserved_48[4];             // 8 reserved bytes (and force alignment)
    uint16_t      version_bcd;                // BCD version number (xx.yy)
    unsigned char git_modified;               // non-zero if design modified from githash version
    unsigned char reserved_59;                // reserved byte
    uint32_t      githash;                    // git "short hash" version from repository
} xosera_info_t;

#ifndef __INTELLISENSE__        // vscode intellisense does not grok m68k (flags as error, but correct for m68k-gcc)
typedef char _xosera_init_size_static_assert[sizeof(xosera_info_t) == XV_INFO_SIZE ? 1 : -1];
#endif

// Xosera XM register base ptr
#if !defined(XV_PREP_REQUIRED)
extern volatile xmreg_t * const xosera_ptr;
#endif

// Extra-credit function that saves 8 cycles per function that calls xosera API functions (call once at top).
// (NOTE: This works by "shadowing" the global xosera_ptr and using asm to load the constant value more efficiently.  If
// GCC "sees" the constant pointer value, it seems to want to load it over and over as needed.  This method gets GCC to
// load the pointer once (using more efficient immediate addressing mode) and keep it loaded in an address register.)
#define xv_prep()                                                                                                      \
    _Pragma("GCC diagnostic push") _Pragma("GCC diagnostic ignored \"-Wshadow\"")                                      \
        _Pragma("GCC diagnostic ignored \"-Wpedantic\"") volatile xmreg_t * const xosera_ptr = ({                      \
            xmreg_t * ptr;                                                                                             \
            __asm__ __volatile__("lea.l " XM_STR(XM_BASEADDR) ",%[ptr]" : [ptr] "=a"(ptr) : :);                        \
            ptr;                                                                                                       \
        });                                                                                                            \
    _Pragma("GCC diagnostic pop")(void) 0

// set high byte (even address) of XM register XM_<xmreg> to 8-bit high_byte
#define xm_setbh(xmreg, high_byte) (xosera_ptr[(XM_##xmreg) >> 2].b.h = (high_byte))

// set low byte (odd address) of XM register XM_<xmreg> xr to 8-bit low_byte
#define xm_setbl(xmreg, low_byte) (xosera_ptr[(XM_##xmreg) >> 2].b.l = (low_byte))

// set XM register XM_<xmreg> to 16-bit word word_value
#define xm_setw(xmreg, word_value)                                                                                     \
    do                                                                                                                 \
    {                                                                                                                  \
        (void)(XM_##xmreg);                                                                                            \
        __asm__ __volatile__("movep.w %[src]," XM_STR(XM_##xmreg) "(%[ptr])"                                           \
                             :                                                                                         \
                             : [src] "d"((uint16_t)(word_value)), [ptr] "a"(xosera_ptr)                                \
                             :);                                                                                       \
    } while (false)

// set XM register XM_<xmreg> to 32-bit long long_value (sets two consecutive 16-bit word registers)
#define xm_setl(xmreg, long_value)                                                                                     \
    do                                                                                                                 \
    {                                                                                                                  \
        (void)(XM_##xmreg);                                                                                            \
        __asm__ __volatile__("movep.l %[src]," XM_STR(XM_##xmreg) "(%[ptr])"                                           \
                             :                                                                                         \
                             : [src] "d"((uint32_t)(long_value)), [ptr] "a"(xosera_ptr)                                \
                             :);                                                                                       \
    } while (false)

// clear high byte of SYS_CTRL register to disable RW_DATA read increment (NOTE: assumes only writeable bit)
#define xm_set_no_rw_rd_incr() xm_setbh(SYS_CTRL, 0)

// set XR register XR_<xreg> to 16-bit word word_value (uses MOVEP.L if reg and value are constant)
#define xreg_setw(xreg, word_value)                                                                                    \
    do                                                                                                                 \
    {                                                                                                                  \
        (void)(XR_##xreg);                                                                                             \
        uint16_t xreg_setw_u16 = (word_value);                                                                         \
        if (__builtin_constant_p((XR_##xreg)) && __builtin_constant_p(xreg_setw_u16))                                  \
        {                                                                                                              \
            __asm__ __volatile__(                                                                                      \
                "movep.l %[rxav]," XM_STR(XM_WR_XADDR) "(%[ptr])"                                                      \
                :                                                                                                      \
                : [rxav] "d"((((uint32_t)XR_##xreg) << 16) | (uint16_t)(xreg_setw_u16)), [ptr] "a"(xosera_ptr)         \
                :);                                                                                                    \
        }                                                                                                              \
        else                                                                                                           \
        {                                                                                                              \
            xm_setw(WR_XADDR, (XR_##xreg));                                                                            \
            xm_setw(XDATA, xreg_setw_u16);                                                                             \
        }                                                                                                              \
    } while (false)

// set XR memory write address xrmem (use xmem_setw_next()/xmem_setw_next_wait() to write data)
#define xreg_set_addr(xreg) xm_setw(WR_XADDR, (XR_##xreg))

// set next xreg (i.e., next WR_XADDR after increment) 16-bit word value
#define xreg_setw_next(word_value) xm_setw(XDATA, (word_value))

// set XR memory address xrmem to 16-bit word word_value
#define xmem_setw(xrmem, word_value)                                                                                   \
    do                                                                                                                 \
    {                                                                                                                  \
        xm_setw(WR_XADDR, (xrmem));                                                                                    \
        xm_setw(XDATA, (word_value));                                                                                  \
    } while (false)

// set XR memory write address xrmem (use xmem_setw_next()/xmem_setw_next_wait() to write data)
#define xmem_set_addr(xrmem) xm_setw(WR_XADDR, (xrmem))

// set next xmem (i.e., next WR_XADDR after increment) 16-bit word value
#define xmem_setw_next(word_value) xm_setw(XDATA, (word_value))

// set XR memory address xrmem to 16-bit word word_value and wait for slow memory
#define xmem_setw_wait(xrmem, word_value)                                                                              \
    do                                                                                                                 \
    {                                                                                                                  \
        xmem_setw((xrmem), (word_value));                                                                              \
        xwait_mem_ready();                                                                                             \
    } while (false)

// set next xmem (i.e., next WR_XADDR after increment) 16-bit word value and wait for slow memory
#define xmem_setw_next_wait(word_value)                                                                                \
    do                                                                                                                 \
    {                                                                                                                  \
        xmem_setw_next((word_value));                                                                                  \
        xwait_mem_ready();                                                                                             \
    } while (false)

// NOTE: Uses clang and gcc supported extension (statement expression), so we must slightly lower
// shields...
#pragma GCC diagnostic ignored "-Wpedantic"        // Yes, I'm slightly cheating (but ugly to have to pass in "return
                                                   // variable" - and this is the "low level" API, remember)

// get bit in SYS_CTRL
#define xm_get_sys_ctrlb(bit_name) ((xosera_ptr[XM_SYS_CTRL >> 2].b.h) & (1 << (SYS_CTRL_##bit_name##_B)))

// return high byte (even address) from XM register XM_<xmreg>
#define xm_getbh(xmreg) (xosera_ptr[XM_##xmreg >> 2].b.h)

// return low byte (odd address) from XM register XM_<xmreg>
#define xm_getbl(xmreg) (xosera_ptr[XM_##xmreg >> 2].b.l)

// return 16-bit word from XM register XM_<xmreg>
#define xm_getw(xmreg)                                                                                                 \
    ({                                                                                                                 \
        (void)(XM_##xmreg);                                                                                            \
        uint16_t xm_getw_u16;                                                                                          \
        __asm__ __volatile__("movep.w " XM_STR(XM_##xmreg) "(%[ptr]),%[dst]"                                           \
                             : [dst] "=d"(xm_getw_u16)                                                                 \
                             : [ptr] "a"(xosera_ptr)                                                                   \
                             :);                                                                                       \
        xm_getw_u16;                                                                                                   \
    })

// return 32-bit word from two consecutive 16-bit word XM registers XM_<xmreg> & XM_<xmreg>+1
#define xm_getl(xmreg)                                                                                                 \
    ({                                                                                                                 \
        (void)(XM_##xmreg);                                                                                            \
        uint32_t xm_getl_u32;                                                                                          \
        __asm__ __volatile__("movep.l " XM_STR(XM_##xmreg) "(%[ptr]),%[dst]"                                           \
                             : [dst] "=d"(xm_getl_u32)                                                                 \
                             : [ptr] "a"(xosera_ptr)                                                                   \
                             :);                                                                                       \
        xm_getl_u32;                                                                                                   \
    })

// return 16-bit word from XR register XR_<xreg>
#define xreg_getw(xreg)                                                                                                \
    ({                                                                                                                 \
        (void)(XR_##xreg);                                                                                             \
        xm_setw(RD_XADDR, (XR_##xreg));                                                                                \
        xm_getw(XDATA);                                                                                                \
    })

// set XR memory read address xrmem (use xmem_getw_next()/xmem_getw_next_wait() to read data)
#define xreg_get_addr(xreg)                                                                                            \
    do                                                                                                                 \
    {                                                                                                                  \
        (void)(XR_##xreg);                                                                                             \
        xm_setw(RD_XADDR, (XR_##xreg));                                                                                \
    } while (false)

// return next xreg (i.e., next RD_XADDR after increment) 16-bit word value
#define xreg_getw_next() xm_getw(XDATA)

// return 16-bit word from XR memory address xrmem
#define xmem_getw(xrmem)                                                                                               \
    ({                                                                                                                 \
        xm_setw(RD_XADDR, (xrmem));                                                                                    \
        xm_getw(XDATA);                                                                                                \
    })

// set XR memory read address xrmem (use xmem_getw_next()/xmem_getw_next_wait() to read data)
#define xmem_get_addr(xrmem) xm_setw(RD_XADDR, (xrmem))

// return next xmem (i.e., next RD_XADDR after increment) 16-bit word value
#define xmem_getw_next() xreg_getw_next()

// return 16-bit word from XR memory address xrmem and wait for slow memory
#define xmem_getw_wait(xrmem)                                                                                          \
    ({                                                                                                                 \
        uint16_t xmem_getw_wait_u16;                                                                                   \
        xm_setw(RD_XADDR, (xrmem));                                                                                    \
        xwait_mem_ready();                                                                                             \
        __asm__ __volatile__("movep.w " XM_STR(XM_XDATA) "(%[ptr]),%[dst]"                                             \
                             : [dst] "=d"(xmem_getw_wait_u16)                                                          \
                             : [ptr] "a"(xosera_ptr)                                                                   \
                             :);                                                                                       \
        xmem_getw_wait_u16;                                                                                            \
    })

// return next xmem (i.e., next RD_XADDR after increment) 16-bit word value and wait for slow
// memory
#define xmem_getw_next_wait()                                                                                          \
    ({                                                                                                                 \
        uint16_t xmem_getw_next_wait_u16;                                                                              \
        __asm__ __volatile__(                                                                                          \
            "0: tst.b (%[ptr]); bmi.s 0b\n"                                                                            \
            "movep.w " XM_STR(XM_XDATA) "(%[ptr]),%[dst]"                                                              \
            : [dst] "=d"(xmem_getw_next_wait_u16)                                                                      \
            : [ptr] "a"(xosera_ptr)                                                                                    \
            :);                                                                                                        \
        xmem_getw_next_wait_u16;                                                                                       \
    })

// wait while bit in SYS_CTRL is set
#define xwait_ctrl_bit_set(bit_name)                                                                                   \
    __asm__ __volatile__("0: btst.b #" XM_STR(SYS_CTRL_##bit_name##_B) ",(%[ptr]); beq.s 0b"                           \
                         :                                                                                             \
                         : [ptr] "a"(xosera_ptr)                                                                       \
                         : "cc")

// wait while bit in SYS_CTRL is clear
#define xwait_ctrl_bit_clear(bit_name)                                                                                 \
    __asm__ __volatile__("0: btst.b #" XM_STR(SYS_CTRL_##bit_name##_B) ",(%[ptr]); bne.s 0b"                           \
                         :                                                                                             \
                         : [ptr] "a"(xosera_ptr)                                                                       \
                         : "cc")

// wait for memory read/write to be completed
#define xwait_mem_ready() __asm__ __volatile__("0: tst.b (%[ptr]); bmi.s 0b" : : [ptr] "a"(xosera_ptr) : "cc")

// wait for blit unit is available for a new operation (queue not full)
#define xwait_blit_ready() xwait_ctrl_bit_clear(BLIT_FULL)

// wait until blit unit has completed all queued operations (not busy)
#define xwait_blit_done() xwait_ctrl_bit_clear(BLIT_BUSY)

// wait until scanout is in horizontal blank (off left/right edge of display line)
#define xwait_hblank() xwait_ctrl_bit_set(HBLANK)

// wait until scanout is not in horizontal blank (center visible  of display line)
#define xwait_not_hblank() xwait_ctrl_bit_clear(HBLANK)

// wait until scanout is in vertical blank (line off top/bottom edge of display)
#define xwait_vblank() xwait_ctrl_bit_set(VBLANK)

// wait until scanout is not in horizontal blank (visible line on display)
#define xwait_not_vblank() xwait_ctrl_bit_clear(VBLANK)

#endif        // XOSERA_M68K_API_H

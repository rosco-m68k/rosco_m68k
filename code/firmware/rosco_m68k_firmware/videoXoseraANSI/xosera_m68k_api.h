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
 * Copyright (c) 2021-2023 Xark
 * MIT License
 *
 * Xosera rosco_m68k low-level C API for Xosera
 * ------------------------------------------------------------
 */

#if !defined(XOSERA_M68K_API_H)
#define XOSERA_M68K_API_H

#include <stdbool.h>
#include <stdint.h>

// Low-level C API macro reference (act like functions as shown):
//
// ==== Prep local xosera_ptr address (optional per function for faster/smaller code)
// void     xv_prep();                          // preload xosera_ptr for faster/smaller code
//
// ==== Set named XM register XM_<xmreg_name> to value
// void     xm_setbh(xmreg_name, high_byte);    // set XM_<xmreg_name> bits [15:8] (high/even byte) to high_byte
// void     xm_setbl(xmreg_name, low_byte);     // set XM_<xmreg_name> bits [7:0] (low/odd byte) to low_byte
// void     xm_setw(xmreg_name, word_val);      // set XM_<xmreg_name> to word_val
// void     xm_setl(xmreg_name, long_val);      // sets two contiguous registers to long_val (high, low)
//
// ==== Get value from named XM register XM_<xmreg_name>
// uint8_t  xm_getbh(xmreg_name);               // get byte val from XM_<xmreg_name> bits [15:8] (high/even byte)
// uint8_t  xm_getbl(xmreg_name);               // get byte val from XM_<xmreg_name> bits [7:0] (low/odd byte)
// uint16_t xm_getw(xmreg_name);                // get word val from XM_<xmreg_name>
// uint32_t xm_getl(xmreg_name);                // get long val from XM_<xmreg_name> and XM_<xmreg_name>+1
//
// ==== Set named XR register XR_<xreg_name> to value
// void     xreg_setw(xreg_name, word_val);     // set XR_<xreg_name> to word_val
// void     xreg_setw_next_addr(xreg_name);     // set initial XR_<xreg_name> WR_XDATA address for xreg_setw_next()
// void     xreg_setw_next(word_val);           // set next XR register (and increment WR_XDATA address)
//
// ====  Get value from named XR register XR_<xreg_name>
// uint16_t xreg_getw(xreg_name);               // get word val from XR_<xreg_name>
// void     xreg_getw_next_addr(xreg_name);     // set initial XR_<xreg_name> RD_XDATA address for xreg_getw_next()
// uint16_t xreg_getw_next();                   // get word val from next XR register (and increment RD_XDATA address)
//
// ==== Set 16-bit XR memory address xr_addr to word value
// void     xmem_setw(xr_addr, word_val);       // set xr_addr to word_val
// void     xmem_setw_wait(xr_addr, word_val);  // set xr_addr to word_val, wait for write
// void     xmem_setw_next_addr(xr_addr);       // set initial xr_addr WR_XADDR address for xmem_setw_next*()
// void     xmem_setw_next(word_val);           // set next XR address to word_val, WR_XDATA++
// void     xmem_setw_next_wait(word_val);      // set next XR address to word_val, WR_XDATA++, wait for write
//
// ====  Get word value from 16-bit XR memory address xr_addr
// uint16_t xmem_getw(xr_addr);                 // get value from xr_addr
// uint16_t xmem_getw_wait(xr_addr);            // get value from xr_addr, wait for memory
// void     xmem_getw_next_addr(xr_addr);       // set initial xr_addr RD_XADDR address for xmem_getw_next*()
// uint16_t xmem_getw_next();                   // get value from next XR address, RD_XDATA++
// uint16_t xmem_getw_next_wait();              // get value from next XR address, RD_XDATA++, wait for memory
//
// ==== Set 16-bit VRAM memory address to value
// void     vram_setw(vram_addr, word_val);     // set vram_addr to word_val
// void     vram_setw_wait(vram_addr, word_val);// set vram_addr to word_val, wait for write
// void     vram_setw_addr_incr(vram_addr, incr);// set initial VRAM WR_ADDR and WR_INCR for vram_set*_next*()
// void     vram_setw_next_addr(vram_addr);     // set initial VRAM WR_ADDR vram_set*_next*()
// void     vram_setw_next(word_val);           // set next VRAM address to word_val, WR_ADDR += WR_INCR
// void     vram_setw_next_wait(word_val);      // set next VRAM address to word_val, WR_ADDR += WR_INCR, wait for write
// void     vram_setl(vram_addr, long_val);     // set vram_addr to long_val (as if two words)
// void     vram_setl_next(long_val);           // set next VRAM address to long_val (as if two words)
//
// ==== Get value from 16-bit VRAM memory address
// uint16_t vram_getw(vram_addr);               // get word val from vram_addr
// uint16_t vram_getw_wait(vram_addr);          // get word val from vram_addr, wait for memory
// void     vram_getw_addr_incr(vram_addr, incr);// set initial VRAM RD_ADDR and RD_INCR for vram_get*_next*()
// void     vram_getw_next_addr(vram_addr);     // set initial VRAM RD_ADDR vram_get*_next*()
// uint16_t vram_getw_next();                   // get word val from next VRAM address, RD_ADDR += RD_INCR
// uint16_t vram_getw_next_wait();              // get word val from next VRAM address, RD_ADDR += RD_INCR, wait memory
// uint32_t vram_getl(vram_addr);               // get long val from vram_addr (as if two words)
// uint32_t vram_getl_next();                   // get long val from next VRAM address (as if two words)
//
// ==== Get named bit from XM_SYS_CTRL (returns zero/non-zero)
// uint8_t  xm_getb_sys_ctrl(sysctrl_bit_name);
//
// ==== Wait for named bit from XM_SYS_CTRL to be set or clear
// void     xwait_sys_ctrl_set(sysctrl_bit_name);
// void     xwait_sys_ctrl_clear(sysctrl_bit_name);
//
// ==== Check or wait for specific bits (convenience macros)
// uint8_t  xis_mem_ready();
// void     xwait_mem_ready();
// uint8_t  xis_blit_ready();
// void     xwait_blit_ready();
// uint8_t  xis_blit_done();
// void     xwait_blit_done();
// uint8_t  xis_hblank();
// void     xwait_hblank();
// void     xwait_not_hblank();
// uint8_t  xis_vblank();
// void     xwait_vblank();
// void     xwait_not_vblank();
//
// ==== UART functions (if UART is present - debug feature)
// uint8_t  xuart_is_send_ready();
// void     xuart_send_byte(byte);
// uint8_t  xuart_is_get_ready();
// uint8_t  xuart_get_byte();
//
// ==== Video Mode information functions (640x480 4:3 or 848x480 16:9, depending on Xosera config active)
// uint16_t xosera_vid_width();         // return visible screen width (typically 640 or 848)
// uint16_t xosera_vid_height();        // return visible screen height (typically 480)
// uint16_t xosera_max_hpos();          // return maximum raw horizontal position (typically 799 or 1087)
// uint16_t xosera_max_vpos();          // return maximum raw vertical position (typically 524 or 516)
// uint16_t xosera_left_hpos()          // return raw horizontal position of visible left edge (typically 160 or 240)
// uint32_t xosera_sample_hz();         // return audio period sample main clock rate for AUDn_PERIOD (and pixels)
// uint8_t  xosera_aud_channels();      // return number of audio channels (typically 4, or zero if disabled)
// uint8_t  xosera_cur_config();        // return current Xosera configuration number (0-3)

typedef struct _xosera_info xosera_info_t;        // forward declare Xosera info structure

typedef enum _xosera_mode        // mode numbers for xosera_init
{
    XINIT_DETECT         = -1,        // detect only, do not configure
    XINIT_CONFIG_640x480 = 0,         // configure Xosera 640x480 VGA/DVI 4:3 (flash config #0)
    XINIT_CONFIG_848x480 = 1,         // configure Xosera 848x480 VGA/DVI 16:9 (flash config #1)
    XINIT_CONFIG_USER_2  = 2,         // configure Xosera flash config #2 (user defined/custom)
    XINIT_CONFIG_USER_3  = 3          // configure Xosera flash config #3 (user defined/custom)
} xosera_mode_t;

// external function declarations
bool xosera_xansi_detect(bool hide_cursor);        // detect if XANSI firmware running ("safe" presence check)
void xosera_xansi_restore(void);                   // restore XANSI text mode
bool xosera_init(xosera_mode_t mode);              // detect Xosera, set configuration (traps if not present)
bool xosera_reset_state(void);                     // reset to default state w/o config, clears VRAM (xrmem unaltered)
bool xosera_sync(void);                            // immediate check if Xosera responding (traps if not present)
bool xosera_wait_sync(void);                       // wait a bit and see if Xosera starts responding (traps if not present)
bool xosera_get_info(xosera_info_t * info);        // retrieve init xosera_info_t (valid after Xosera reconfig)
void cpu_delay(int ms);                            // delay approx milliseconds with CPU busy wait
void xosera_delay(uint32_t ms);                    // delay milliseconds using Xosera TIMER register
void xosera_memclear(void * ptr, unsigned int n);        // memory zero (mostly for XANSI firmware use)

void xosera_set_pointer(int16_t  x_pos,                  // native pixel X for pointer upper left
                        int16_t  y_pos,                  // native pixel Y for pointer upper left
                        uint16_t colormap_index);        // colormap_index = 0xi000 (upper 4-bits of pointer colorA)

#include "xosera_m68k_defs.h"

#define NUM_ELEMENTS(a) (sizeof(a) / sizeof(a[0]))

// NOTE: Since Xosera is using a 6800-style 8-bit bus, it uses only data lines 8-15 of each 16-bit word (i.e., only the
//       odd byte of each word) this makes the size of its register map in memory appear doubled and is the reason for
//       the pad bytes in the struct below.  Byte access is fine but for word or long access to this struct, the MOVEP
//       680x0 instruction should be used (it was designed for this purpose).  The macros below make it easy.
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
    char          description_str[240];        // ASCII description
    uint16_t      reserved_48[4];              // 8 reserved bytes (and force alignment)
    uint16_t      version_bcd;                 // BCD version number (xx.yy)
    unsigned char git_modified;                // non-zero if design modified from githash version
    unsigned char reserved_59;                 // reserved byte
    uint32_t      githash;                     // git "short hash" version from repository
} xosera_info_t;

_Static_assert(sizeof(struct _xosera_info) == XV_INFO_BYTES, "unexpected xosera_info_t size");

// Xosera XM register base ptr type
typedef volatile xmreg_t * const xosera_ptr_t;

// C preprocessor "stringify" to embed #define into inline asm string
#define _XM_STR(s) #s
#define XM_STR(s)  _XM_STR(s)

// NOTE: Several macros that return a value uses a clang and gcc supported extension (statement expression), so
// lowering the pedantic shield is required.
#pragma GCC diagnostic ignored "-Wpedantic"        // Yes, I'm slightly cheating (but ugly to have to pass in
                                                   // a "return variable" - and this is the "low level" API, remember)

// Extra-credit function that saves 8 cycles per function that calls xosera API functions (call once at top).
// (NOTE: This works by "shadowing" the global xosera_ptr and using asm to load the constant value more efficiently.  If
// GCC "sees" the constant pointer value, it seems to want to load it over and over as needed.  This method gets GCC to
// load the pointer once (using more efficient immediate addressing mode) and keep it loaded in an address register.)

// void xv_prep() - declare and load xosera_ptr (tries to use local/register for faster/smaller code vs global)
#define xv_prep() volatile xmreg_t * const xosera_ptr = ((volatile xmreg_t *)XM_BASEADDR)

// void xm_setbh(xmreg_name, high_byte) - set XM_<xmreg_name> bits [15:8] (high/even byte) to high_byte
#define xm_setbh(xmreg_name, high_byte) (xosera_ptr[(XM_##xmreg_name) >> 2].b.h = (high_byte))

// void xm_setbl(xmreg_name, low_byte) - set XM_<xmreg_name> bits [7:0] (low/odd byte) to low_byte
#define xm_setbl(xmreg_name, low_byte) (xosera_ptr[(XM_##xmreg_name) >> 2].b.l = (low_byte))

// void xm_setw(xmreg_name, word_val) - set XM_<xmreg_name> to word_val
#define xm_setw(xmreg_name, word_val)                                                                                  \
    do                                                                                                                 \
    {                                                                                                                  \
        (void)(XM_##xmreg_name);                                                                                       \
        __asm__ __volatile__("movep.w %[src]," XM_STR(XM_##xmreg_name) "(%[ptr])"                                      \
                             :                                                                                         \
                             : [src] "d"((uint16_t)(word_val)), [ptr] "a"(xosera_ptr)                                  \
                             :);                                                                                       \
    } while (false)

// void xm_setl(xmreg_name, long_val) - sets two contiguous registers to long_val (high, low)
#define xm_setl(xmreg_name, long_val)                                                                                  \
    do                                                                                                                 \
    {                                                                                                                  \
        (void)(XM_##xmreg_name);                                                                                       \
        __asm__ __volatile__("movep.l %[src]," XM_STR(XM_##xmreg_name) "(%[ptr])"                                      \
                             :                                                                                         \
                             : [src] "d"((uint32_t)(long_val)), [ptr] "a"(xosera_ptr)                                  \
                             :);                                                                                       \
    } while (false)

// uint8_t xm_getbh(xmreg_name) - get byte val from XM_<xmreg_name> bits [15:8] (high/even byte)
#define xm_getbh(xmreg_name) (xosera_ptr[XM_##xmreg_name >> 2].b.h)

// uint8_t xm_getbl(xmreg_name) - get byte val from XM_<xmreg_name> bits [7:0] (low/odd byte)
#define xm_getbl(xmreg_name) (xosera_ptr[XM_##xmreg_name >> 2].b.l)

// uint16_t xm_getw(xmreg_name) - get word val from XM_<xmreg_name>
#define xm_getw(xmreg_name)                                                                                            \
    ({                                                                                                                 \
        (void)(XM_##xmreg_name);                                                                                       \
        uint16_t xm_getw_u16;                                                                                          \
        __asm__ __volatile__("movep.w " XM_STR(XM_##xmreg_name) "(%[ptr]),%[dst]"                                      \
                             : [dst] "=d"(xm_getw_u16)                                                                 \
                             : [ptr] "a"(xosera_ptr)                                                                   \
                             :);                                                                                       \
        xm_getw_u16;                                                                                                   \
    })

// uint32_t xm_getl(xmreg_name) - get long val from XM_<xmreg_name> and XM_<xmreg_name>+1 (high, low)
#define xm_getl(xmreg_name)                                                                                            \
    ({                                                                                                                 \
        (void)(XM_##xmreg_name);                                                                                       \
        uint32_t xm_getl_u32;                                                                                          \
        __asm__ __volatile__("movep.l " XM_STR(XM_##xmreg_name) "(%[ptr]),%[dst]"                                      \
                             : [dst] "=d"(xm_getl_u32)                                                                 \
                             : [ptr] "a"(xosera_ptr)                                                                   \
                             :);                                                                                       \
        xm_getl_u32;                                                                                                   \
    })

// get named bit from SYS_CTRL high byte (zero/non-zero)
#define xm_getb_sys_ctrl(sysctrl_bit_name) (xm_getbh(SYS_CTRL) & SYS_CTRL_##sysctrl_bit_name##_F)

// wait while bit in SYS_CTRL is set (return only when bit clear)
#define xwait_sys_ctrl_set(sysctrl_bit_name)                                                                           \
    do                                                                                                                 \
    {                                                                                                                  \
        (void)(SYS_CTRL_##sysctrl_bit_name##_B);                                                                       \
        if (__builtin_constant_p((SYS_CTRL_##sysctrl_bit_name##_B)) &&                                                 \
            (SYS_CTRL_##sysctrl_bit_name##_B == SYS_CTRL_MEM_WAIT_B))                                                  \
        {                                                                                                              \
            __asm__ __volatile__("0: tst.b (%[ptr]); bmi.s 0b" : : [ptr] "a"(xosera_ptr) : "cc");                      \
        }                                                                                                              \
        else                                                                                                           \
        {                                                                                                              \
            __asm__ __volatile__("0: btst.b #" XM_STR(SYS_CTRL_##sysctrl_bit_name##_B) ",(%[ptr]); beq.s 0b"           \
                                 :                                                                                     \
                                 : [ptr] "a"(xosera_ptr)                                                               \
                                 : "cc");                                                                              \
        }                                                                                                              \
    } while (false)

// wait while bit in SYS_CTRL is clear (return only when bit set)
#define xwait_sys_ctrl_clear(sysctrl_bit_name)                                                                         \
    __asm__ __volatile__("0: btst.b #" XM_STR(SYS_CTRL_##sysctrl_bit_name##_B) ",(%[ptr]); bne.s 0b"                   \
                         :                                                                                             \
                         : [ptr] "a"(xosera_ptr)                                                                       \
                         : "cc")

// return non-zero if memory read/write is completed (no wait needed)
#define xis_mem_ready() (~xm_getbh(SYS_CTRL) & SYS_CTRL_MEM_WAIT_F)

// wait for any memory read/write to be completed (for slow/contended memory)
#define xwait_mem_ready() xwait_sys_ctrl_set(MEM_WAIT)

// return non-zero if blitter ready for a new operation (queue not full)
#define xis_blit_ready() (~xm_getbh(SYS_CTRL) & SYS_CTRL_BLIT_FULL_F)

// wait for blit unit is available for a new operation (queue not full)
#define xwait_blit_ready() xwait_sys_ctrl_clear(BLIT_FULL)

// return non-zero if blitter currenty idle (not busy)
#define xis_blit_done() (~xm_getbh(SYS_CTRL) & SYS_CTRL_BLIT_BUSY_F)

// wait until blit unit has completed all operations (not busy)
#define xwait_blit_done() xwait_sys_ctrl_clear(BLIT_BUSY)

// return non-zero if scanout is in horizontal blank
#define xis_hblank() xm_getb_sys_ctrl(HBLANK)

// wait until scanout is in horizontal blank
#define xwait_hblank() xwait_sys_ctrl_set(HBLANK)

// wait until scanout is not in horizontal blank
#define xwait_not_hblank() xwait_sys_ctrl_clear(HBLANK)

// return non-zero if scanout is in non-visible line
#define xis_vblank() xm_getb_sys_ctrl(VBLANK)

// wait until scanout is in non-visible vertical line
#define xwait_vblank() xwait_sys_ctrl_set(VBLANK)

// wait until scanout is in visible vertical line
#define xwait_not_vblank() xwait_sys_ctrl_clear(VBLANK)

// void xreg_setw(xreg_name, word_val) - set XR_<xreg_name> to word_val
#define xreg_setw(xreg_name, word_val)                                                                                 \
    do                                                                                                                 \
    {                                                                                                                  \
        (void)(XR_##xreg_name);                                                                                        \
        uint16_t xreg_setw_u16 = (word_val);                                                                           \
        if (__builtin_constant_p((XR_##xreg_name)) && __builtin_constant_p(xreg_setw_u16))                             \
        {                                                                                                              \
            __asm__ __volatile__(                                                                                      \
                "movep.l %[rxav]," XM_STR(XM_WR_XADDR) "(%[ptr])"                                                      \
                :                                                                                                      \
                : [rxav] "d"((((uint32_t)XR_##xreg_name) << 16) | (uint16_t)(xreg_setw_u16)), [ptr] "a"(xosera_ptr)    \
                :);                                                                                                    \
        }                                                                                                              \
        else                                                                                                           \
        {                                                                                                              \
            xm_setw(WR_XADDR, (XR_##xreg_name));                                                                       \
            xm_setw(XDATA, xreg_setw_u16);                                                                             \
        }                                                                                                              \
    } while (false)

// void xreg_setw_next_addr(xreg_name) - set initial XR_<xreg_name> WR_XDATA address for xreg_setw_next()
#define xreg_setw_next_addr(xreg_name) xm_setw(WR_XADDR, (XR_##xreg_name))

// void xreg_setw_next(word_val) - set next XR register (and increment WR_XDATA address)
#define xreg_setw_next(word_val) xm_setw(XDATA, (word_val))

// uint16_t xreg_getw(xreg_name) - get word val from XR_<xreg_name>
#define xreg_getw(xreg_name)                                                                                           \
    ({                                                                                                                 \
        (void)(XR_##xreg_name);                                                                                        \
        xm_setw(RD_XADDR, (XR_##xreg_name));                                                                           \
        xm_getw(XDATA);                                                                                                \
    })

// void xreg_getw_next_addr(xreg_name) - set initial XR_<xreg_name> RD_XDATA address for xreg_getw_next()
#define xreg_getw_next_addr(xreg_name)                                                                                 \
    do                                                                                                                 \
    {                                                                                                                  \
        (void)(XR_##xreg_name);                                                                                        \
        xm_setw(RD_XADDR, (XR_##xreg_name));                                                                           \
    } while (false)

// uint16_t xreg_getw_next() -  get word val from next XR register (and increment RD_XDATA address)
#define xreg_getw_next() xm_getw(XDATA)

// void xmem_setw(xr_addr, word_val) - set xr_addr to word_val
#define xmem_setw(xr_addr, word_val)                                                                                   \
    do                                                                                                                 \
    {                                                                                                                  \
        uint16_t xmem_setw_xaddr = (xr_addr);                                                                          \
        uint16_t xmem_setw_u16   = (word_val);                                                                         \
        if (__builtin_constant_p(xmem_setw_xaddr) && __builtin_constant_p(xmem_setw_u16))                              \
        {                                                                                                              \
            xm_setl(WR_XADDR, ((xmem_setw_xaddr) << 16) | (xmem_setw_u16));                                            \
        }                                                                                                              \
        else                                                                                                           \
        {                                                                                                              \
            xm_setw(WR_XADDR, xmem_setw_xaddr);                                                                        \
            xm_setw(XDATA, xmem_setw_u16);                                                                             \
        }                                                                                                              \
    } while (false)

// void xmem_setw_wait(xr_addr, word_val) - set xr_addr to word_val, wait for write
#define xmem_setw_wait(xr_addr, word_val)                                                                              \
    do                                                                                                                 \
    {                                                                                                                  \
        xmem_setw((xr_addr), (word_val));                                                                              \
        xwait_mem_ready();                                                                                             \
    } while (false)

// void xmem_setw_next_addr(xr_addr) - set initial xr_addr WR_XADDR address for xmem_setw_next*()
#define xmem_setw_next_addr(xr_addr) xm_setw(WR_XADDR, (xr_addr))

// void xmem_setw_next(word_val) - set next XR address to word_val, WR_XDATA++
#define xmem_setw_next(word_val) xm_setw(XDATA, (word_val))

// void xmem_setw_next_wait(word_val) - set next XR address to word_val, WR_XDATA++, wait for write
#define xmem_setw_next_wait(word_val)                                                                                  \
    do                                                                                                                 \
    {                                                                                                                  \
        xmem_setw_next((word_val));                                                                                    \
        xwait_mem_ready();                                                                                             \
    } while (false)

// uint16_t xmem_getw(xr_addr) - get value from xr_addr
#define xmem_getw(xr_addr)                                                                                             \
    ({                                                                                                                 \
        xm_setw(RD_XADDR, (xr_addr));                                                                                  \
        xm_getw(XDATA);                                                                                                \
    })

// uint16_t xmem_getw_wait(xr_addr) - get value from xr_addr, wait for memory
#define xmem_getw_wait(xr_addr)                                                                                        \
    ({                                                                                                                 \
        uint16_t xmem_getw_wait_u16;                                                                                   \
        xm_setw(RD_XADDR, (xr_addr));                                                                                  \
        xwait_mem_ready();                                                                                             \
        __asm__ __volatile__("movep.w " XM_STR(XM_XDATA) "(%[ptr]),%[dst]"                                             \
                             : [dst] "=d"(xmem_getw_wait_u16)                                                          \
                             : [ptr] "a"(xosera_ptr)                                                                   \
                             :);                                                                                       \
        xmem_getw_wait_u16;                                                                                            \
    })

// void xmem_getw_next_addr(xr_addr) - set initial xr_addr RD_XADDR address for xmem_getw_next*()
#define xmem_getw_next_addr(xr_addr) xm_setw(RD_XADDR, (xr_addr))

// uint16_t xmem_getw_next() - get value from next XR address, RD_XDATA++
#define xmem_getw_next() xm_getw(XDATA)

// uint16_t xmem_getw_next_wait() - get value from next XR address, RD_XDATA++, wait for memory
#define xmem_getw_next_wait()                                                                                          \
    ({                                                                                                                 \
        xwait_mem_ready();                                                                                             \
        xm_getw(XDATA);                                                                                                \
    })

// void vram_setw(vram_addr, word_val) - set vram_addr to word_val
#define vram_setw(vram_addr, word_val)                                                                                 \
    do                                                                                                                 \
    {                                                                                                                  \
        uint16_t vram_addr_u16 = (vram_addr);                                                                          \
        uint16_t vram_setw_u16 = (word_val);                                                                           \
        if (__builtin_constant_p((vram_addr_u16)) && __builtin_constant_p(vram_setw_u16))                              \
        {                                                                                                              \
            __asm__ __volatile__(                                                                                      \
                "movep.l %[rxav]," XM_STR(XM_WR_ADDR) "(%[ptr])"                                                       \
                :                                                                                                      \
                : [rxav] "d"((((uint32_t)(vram_addr_u16)) << 16) | (uint16_t)(vram_setw_u16)), [ptr] "a"(xosera_ptr)   \
                :);                                                                                                    \
        }                                                                                                              \
        else                                                                                                           \
        {                                                                                                              \
            xm_setw(WR_ADDR, vram_addr_u16);                                                                           \
            xm_setw(DATA, vram_setw_u16);                                                                              \
        }                                                                                                              \
    } while (false)

// void vram_setw_wait(vram_addr, word_val) - set vram_addr to word_val, wait for write
#define vram_setw_wait(vram_addr, word_val)                                                                            \
    do                                                                                                                 \
    {                                                                                                                  \
        vram_setw((vram_addr), (word_val));                                                                            \
        xwait_mem_ready();                                                                                             \
    } while (false)

// void vram_setw_addr_incr(vram_addr, incr) -  set initial VRAM WR_ADDR and WR_INCR for vram_set*_next*()
#define vram_setw_addr_incr(vram_addr, vram_incr)                                                                      \
    do                                                                                                                 \
    {                                                                                                                  \
        uint16_t vram_addr_u16 = (vram_addr);                                                                          \
        uint16_t vram_incr_u16 = (vram_incr);                                                                          \
        if (__builtin_constant_p((vram_addr_u16)) && __builtin_constant_p(vram_incr_u16))                              \
        {                                                                                                              \
            xm_setl(WR_INCR, ((vram_incr_u16) << 16) | (vram_addr_u16));                                               \
        }                                                                                                              \
        else                                                                                                           \
        {                                                                                                              \
            xm_setw(WR_INCR, vram_incr_u16);                                                                           \
            xm_setw(WR_ADDR, vram_addr_u16);                                                                           \
        }                                                                                                              \
    } while (false)

// void vram_setw_next_addr(vram_addr) - set initial VRAM WR_ADDR vram_set*_next*()
#define vram_setw_next_addr(vram_addr) xm_setw(WR_ADDR, (vram_addr))

// void vram_setw_next(word_val) -  set next VRAM address to word_val, WR_ADDR += WR_INCR
#define vram_setw_next(word_val) xm_setw(DATA, (word_val))

// void vram_setw_next_wait(word_val) - set next VRAM address to word_val, WR_ADDR += WR_INCR, wait for write
#define vram_setw_next_wait(word_val)                                                                                  \
    do                                                                                                                 \
    {                                                                                                                  \
        vram_setw_next((word_val));                                                                                    \
        xwait_mem_ready();                                                                                             \
    } while (false)

// void vram_setl(vram_addr, long_val) - set vram_addr to long_val (as if two words)
#define vram_setl(vram_addr, long_val)                                                                                 \
    do                                                                                                                 \
    {                                                                                                                  \
        xm_setw(WR_ADDR, (vram_addr));                                                                                 \
        xm_setl(DATA, long_val);                                                                                       \
    } while (false)

// void vram_setl_next(long_val) - set next VRAM address to long_val (as if two words)
#define vram_setl_next(long_val) xm_setl(DATA, (long_val))

// void vram_setl_next_wait(long_val) - set next VRAM address to long_val (as if two words), wait for write
#define vram_setl_next_wait(long_val)                                                                                  \
    do                                                                                                                 \
    {                                                                                                                  \
        vram_setl_next((long_val));                                                                                    \
        xwait_mem_ready();                                                                                             \
    } while (false)

// uint16_t vram_getw(vram_addr) - get word val from vram_addr
#define vram_getw(vram_addr)                                                                                           \
    ({                                                                                                                 \
        xm_setw(RD_ADDR, (vram_addr));                                                                                 \
        xm_getw(DATA);                                                                                                 \
    })

// uint16_t vram_getw_wait(vram_addr) - get word val from vram_addr, wait for memory
#define vram_getw_wait(vram_addr)                                                                                      \
    ({                                                                                                                 \
        xm_setw(RD_ADDR, (vram_addr));                                                                                 \
        xwait_mem_ready();                                                                                             \
        xm_getw(DATA);                                                                                                 \
    })

// void vram_getw_addr_incr(vram_addr, incr) - set initial VRAM RD_ADDR and RD_INCR for vram_get*_next*()
#define vram_getw_addr_incr(vram_addr, vram_incr)                                                                      \
    do                                                                                                                 \
    {                                                                                                                  \
        xm_setw(RD_INCR, (vram_addr));                                                                                 \
        xm_setw(RD_ADDR, (vram_incr));                                                                                 \
    } while (false)

// void vram_getw_next_addr(vram_addr) - set initial VRAM RD_ADDR vram_get*_next*()
#define vram_getw_next_addr(vram_addr) xm_setw(RD_ADDR, (vram_addr))

// uint16_t vram_getw_next() - get word val from next VRAM address, RD_ADDR += RD_INCR
#define vram_getw_next(vram_addr) xm_getw(DATA)

// uint16_t vram_getw_next_wait() - get word val from next VRAM address, RD_ADDR += RD_INCR, wait memory
#define vram_getw_next_wait()                                                                                          \
    ({                                                                                                                 \
        xwait_mem_ready();                                                                                             \
        xm_getw(DATA);                                                                                                 \
    })
// uint32_t vram_getl(vram_addr) - get long val from vram_addr (as if two words)
#define vram_getl(vram_addr)                                                                                           \
    ({                                                                                                                 \
        xm_setw(RD_ADDR, (vram_addr));                                                                                 \
        xm_getl(DATA);                                                                                                 \
    })

// uint32_t vram_getl_next() - get long val from next VRAM address (as if two words)
#define vram_getl_next(long_val) xm_getl(DATA)

// return true if ready to transmit character
#define xuart_is_send_ready() (!(xm_getbh(UART) & UART_TXF_F))

// transmit UART character (call when uart_send_ready() returns true)
#define xuart_send_byte(byte) (xosera_ptr[(XM_UART) >> 2].b.l = (byte))

// return true if RX character waiting
#define xuart_is_get_ready() (xm_getbh(UART) & UART_RXF_F)

// return UART received character (call when uart_get_ready() returns true)
#define xuart_get_byte() (xosera_ptr[XM_UART >> 2].b.l)

// Return current visible screen width and height
#define xosera_vid_width()  ((xm_getbl(FEATURE) & (1 << FEATURE_MONRES_B)) ? MODE_848x480_H : MODE_640x480_H)
#define xosera_vid_height() (MODE_640x480_V)

// Returns maximum value for "raw" HPOS and VPOS (including offscreen as seen by COPPER or SCANLINE register)
#define xosera_max_hpos()                                                                                              \
    ((xm_getbl(FEATURE) & (1 << FEATURE_MONRES_B)) ? MODE_848x480_TOTAL_H - 1 : MODE_640x480_TOTAL_H - 1)
#define xosera_max_vpos()                                                                                              \
    ((xm_getbl(FEATURE) & (1 << FEATURE_MONRES_B)) ? MODE_848x480_TOTAL_V - 1 : MODE_640x480_TOTAL_V - 1)

// Returns leftmost first visible "raw" HPOS (as seen by COPPER)
#define xosera_left_hpos()                                                                                             \
    ((xm_getbl(FEATURE) & (1 << FEATURE_MONRES_B)) ? MODE_848x480_LEFTEDGE : MODE_640x480_LEFTEDGE)

// return number of audio channels (typically 4, or zero if disabled)
#define xosera_aud_channels() (xm_getbh(FEATURE) & (FEATURE_AUDCHAN_F >> 8))

// return uint32_t audio period sample main clock rate for AUDn_PERIOD (and pixels)
#define xosera_sample_hz()                                                                                             \
    ((xm_getbl(FEATURE) & (1 << FEATURE_MONRES_B)) ? (uint32_t)AUDIO_PERIOD_HZ_848 : (uint32_t)AUDIO_PERIOD_HZ_640)

// return current xosera configuration (0 - 3)
#define xosera_cur_config() (xm_getbh(FEATURE) >> (FEATURE_CONFIG_B - 8))


#endif        // XOSERA_M68K_API_H

/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
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

#include <stdbool.h>
#include <stdint.h>

// building XANSI in firmware
#if !defined(XOSERA_API_MINIMAL)
#include <machine.h>        // rosco_m68k I/O
#include <basicio.h>
#include <stdlib.h>
#include <string.h>
#endif

#if !defined(ROSCO_M68K)
#define ROSCO_M68K
#endif
#include "xosera_m68k_api.h"

#define SYNC_RETRIES 250        // ~1/4 second

// TODO: This is less than ideal (tuned for ~10MHz)
__attribute__((noinline)) void cpu_delay(int ms)
{
    __asm__ __volatile__(
        "    lsl.l   #8,%[temp]\n"
        "    add.l   %[temp],%[temp]\n"
        "0:  sub.l   #1,%[temp]\n"
        "    tst.l   %[temp]\n"
        "    bne.s   0b\n"
        : [temp] "+d"(ms));
}

// GCC really wants to transform my code to call memset, even though I never reference it (it
// sees loops zeroing memory and tries to optimize).  This is a problem because it causes a
// link error in firmware-land (where some normal C libraries are missing). Since GCC seems
// to ignore -fno-builtin, using an obfuscated version seems the best way to outsmart GCC
// (for now...hopefully it won't learn how to parse inline asm anytime soon). :D
void xosera_memclear(void * ptr, unsigned int n)
{
    uint8_t * buf = (uint8_t *)ptr;
    uint8_t * end = buf + n;

    __asm__ __volatile__(
        "0:         clr.b   (%[buf])+\n"
        "           cmp.l   %[buf],%[end]\n"
        "           bne.s   0b\n"
        : [buf] "+a"(buf)
        : [end] "a"(end));
}

// delay for approx ms milliseconds
void xosera_delay(uint32_t ms)
{
    if (!xosera_sync())
    {
        return;
    }

    xv_prep();
    while (ms--)
    {
        for (uint16_t tms = 10; tms != 0; --tms)
        {
            uint16_t tv = xm_getw(TIMER);
            while (tv == xm_getw(TIMER))
                ;
        }
    }
}

// building XANSI in firmware
#if !defined(XOSERA_API_MINIMAL)

// return true if Xosera XANSI firmware detected (safe from BUS ERROR if no hardware present)
bool xosera_xansi_detect(bool hide_cursor)
{
    uint16_t       len          = 0;
    uint16_t       spincount    = 0;
    const uint16_t spin_timeout = 10000;        // spin count per reply char
    char           reply_str[32];

    xosera_memclear(reply_str, sizeof(reply_str));
    print("\23368c");        // CSI 68 c
    do
    {
        if (checkchar())
        {
            char cdata = readchar();
            // CAN/SUB
            if (cdata == 0x18 || cdata == 0x1a)
            {
                break;
            }

            reply_str[len++] = cdata;

            if ((len == 1 && cdata != '\x1b') || (len == 2 && cdata != '[') || (len > 2 && cdata >= 0x40))
            {
                break;
            }
            spincount = 0;
        }
        else
        {
            spincount++;
        }
    } while (++spincount < spin_timeout && len < (sizeof(reply_str) - 1));

    if (len && strncmp(reply_str, "\x1b[?68;", 6) == 0)
    {
        if (hide_cursor)
        {
            print("\233?25l");        // disable input cursor
        }
        return true;
    }
    return false;
}

// return to XANSI text mode
void xosera_xansi_restore(void)
{
    xv_prep();
    xreg_setw(VID_CTRL, 0x0008);        // grey border color
    xreg_setw(VID_LEFT, 0);
    xreg_setw(VID_RIGHT, xosera_vid_width());
    xreg_setw_next(/* VID_POINTER_H, */ 0x0000);
    xreg_setw(PA_GFX_CTRL, 0x0080);
    xreg_setw(PB_GFX_CTRL, 0x0080);

    if (xosera_xansi_detect(false))
    {
        print("\033c");        // reset XANSI
    }
}
#endif

// return true if Xosera responding
// NOTE: May BUS ERROR if no hardware present
bool xosera_sync(void)
{
    xv_prep();

    uint16_t rd_incr   = xm_getw(RD_INCR);
    uint16_t test_incr = rd_incr ^ 0xF5FA;
    xm_setw(RD_INCR, test_incr);
    if (xm_getw(RD_INCR) != test_incr)
    {
        return false;        // not detected
    }
    xm_setw(RD_INCR, rd_incr);

    return true;
}

// wait for Xosera to respond after reconfigure
bool xosera_wait_sync(void)
{
    // check for Xosera presense (retry in case it is reconfiguring)
    for (uint16_t r = SYNC_RETRIES; r != 0; --r)
    {
        if (xosera_sync())
        {
            return true;
        }
        cpu_delay(10);
    }
    return false;
}

// reconfigure or sync Xosera and return true if it is responsive
// NOTE: May BUS ERROR if no hardware present
bool xosera_init(xosera_mode_t init_mode)
{
    bool detected = xosera_wait_sync();

    if (detected)
    {
        xv_prep();
        xwait_not_vblank();
        xwait_vblank();
        if (init_mode >= XINIT_CONFIG_640x480)
        {
            xm_setbh(INT_CTRL, 0x80 | (init_mode & 0x03));        // reconfig FPGA to init_mode 0-3
            detected = xosera_wait_sync();                        // wait for detect
            if (detected)
            {
                // wait for initial copper program to disable itself (or timeout)
                uint16_t timeout = 100;
                do
                {
                    cpu_delay(1);
                } while ((xreg_getw(COPP_CTRL) & COPP_CTRL_COPP_EN_F) && --timeout);
            }
        }
    }

    return detected;
}

// reset registers and VRAM as-if reconfigured (but does not restore any xrmem)
bool xosera_reset_state(void)
{
    bool detected = xosera_wait_sync();

    if (detected)
    {
        xv_prep();
        uint16_t width = xosera_vid_width();
        // set registers as if reconfigured, clear VRAM (but not xrmem)
        xm_setw(PIXEL_X, 0x0000);
        xm_setw(PIXEL_Y, 0x0000);
        xm_setbh(SYS_CTRL, 0x00);
        xm_setbl(SYS_CTRL, SYS_CTRL_WR_MASK_F);
        xm_setw(INT_CTRL, INT_CTRL_CLEAR_ALL_F);
        xm_setw(RD_INCR, 0x0000);
        xm_setw(RD_ADDR, 0x0000);
        xm_setw(WR_INCR, 0x0000);
        xm_setw(WR_ADDR, 0x0000);
        // restore XR defaults
        xreg_setw(VID_CTRL, MAKE_VID_CTRL(0, 0x08));        // grey border color
        for (uint16_t xr = XR_COPP_CTRL; xr < XR_BLIT_CTRL; xr++)
        {
            xreg_setw_next(0x0000);        // zero default
        }
        // exceptions to zero XR default
        xreg_setw(PA_GFX_CTRL, MAKE_GFX_CTRL(0x00, 0, 0, GFX_4_BPP, GFX_1X, GFX_1X));
        xreg_setw_next(/* PA_TILE_CTRL, */ MAKE_TILE_CTRL(0x0000, 0, 0, 16));
        xreg_setw(PA_LINE_LEN, width / 8);
        xreg_setw(PB_GFX_CTRL, MAKE_GFX_CTRL(0x00, 1, 0, GFX_1_BPP, GFX_1X, GFX_1X));
        xreg_setw_next(/* PB_TILE_CTRL, */ MAKE_TILE_CTRL(0x0000, 0, 0, 16));
        xreg_setw(PB_LINE_LEN, width / 8);
        // clear VRAM
        xreg_setw(BLIT_CTRL, MAKE_BLIT_CTRL(0, 0, 0, 1));                      // no transp, constS
        xreg_setw_next(/* BLIT_ANDC,  */ 0x0000);                              // ANDC constant
        xreg_setw_next(/* BLIT_XOR,   */ 0x0000);                              // XOR constant
        xreg_setw_next(/* BLIT_MOD_S, */ 0x0000);                              // no modulo S
        xreg_setw_next(/* BLIT_SRC_S, */ 0x0000);                              // fill value
        xreg_setw_next(/* BLIT_MOD_D, */ 0x0000);                              // no modulo D
        xreg_setw_next(/* BLIT_DST_D, */ 0x0000);                              // VRAM address
        xreg_setw_next(/* BLIT_SHIFT, */ MAKE_BLIT_SHIFT(0xF, 0xF, 0));        // no edge masking or shifting
        xreg_setw_next(/* BLIT_LINES, */ 0x0000);                              // 1D
        xreg_setw_next(/* BLIT_WORDS, */ 0x10000 - 1);                         // 64KW VRAM - and go!
        xwait_blit_done();                                                     // wait until blitter done
    }
    return detected;
}

void xosera_set_pointer(int16_t x, int16_t y, uint16_t colormap_index)
{
    xv_prep();

    uint8_t ws = xm_getbl(FEATURE) & FEATURE_MONRES_F;        // 0 = 640x480

    // offscreen pixels plus 6 pixel "head start"
    x = x + (ws ? MODE_848x480_LEFTEDGE - POINTER_H_OFFSET : MODE_640x480_LEFTEDGE - POINTER_H_OFFSET);
    // make sure doesn't wrap back onscreen due to limited bits in POINTER_H
    if (x < 0 || x > MODE_848x480_TOTAL_H)
    {
        x = MODE_848x480_TOTAL_H;
    }

    // make sure doesn't wrap back onscreen due to limited bits in POINTER_V
    if (y < -32 || y > MODE_640x480_V)
    {
        y = MODE_640x480_V;
    }
    else if (y < 0)
    {
        // special handling for partially off top (offset to before V wrap)
        y = y + (ws ? MODE_848x480_TOTAL_V : MODE_640x480_TOTAL_V);
    }

    // wait for start of hblank to hide change
    xwait_not_hblank();
    xwait_hblank();
    xreg_setw(POINTER_H, x);
    xreg_setw(POINTER_V, colormap_index | y);
}

bool xosera_get_info(xosera_info_t * info)
{
    if (!info)
    {
        return false;
    }

    xosera_memclear(info, sizeof(xosera_info_t));

    if (!xosera_sync())
    {
        return false;
    }

    xv_prep();

    xwait_not_vblank();
    xwait_vblank();

    bool valid = false;

    xmem_getw_next_addr(XV_INFO_ADDR);
    if (xmem_getw_next_wait() == (('X' << 8) | 'o') && xmem_getw_next_wait() == (('s' << 8) | 'e') &&
        xmem_getw_next_wait() == (('r' << 8) | 'a'))
    {
        // xosera_info stored at end COPPER program memory
        uint16_t * wp = (uint16_t *)info;
        xmem_getw_next_addr(XV_INFO_ADDR);
        for (uint16_t i = 0; i < (sizeof(xosera_info_t) / 2); i++)
        {
            *wp++ = xmem_getw_next_wait();
        }

        valid = true;
    }

    return valid;
}

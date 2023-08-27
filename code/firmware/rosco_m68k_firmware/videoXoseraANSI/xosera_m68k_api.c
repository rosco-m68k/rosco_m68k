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

#include <machine.h>

#define XV_PREP_REQUIRED
#include "xosera_m68k_api.h"

#define MODE_640_FULL_H 800
#define MODE_640_FULL_V 525
#define MODE_848_FULL_H 1088
#define MODE_848_FULL_V 517

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
void xv_delay(uint32_t ms)
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

// return true if Xosera responding (may BUS ERROR if no hardware present)
bool xosera_sync()
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

    // make sure memory and blitter report not busy/running
    return (xm_getbh(SYS_CTRL) & (SYS_CTRL_MEM_WAIT_F | SYS_CTRL_BLIT_BUSY_F)) == 0;
}

// wait for Xosera to respond after reconfigure
bool xosera_wait_sync()
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
bool xosera_init(int reconfig_num)
{
    xv_prep();

    bool detected = xosera_wait_sync();

    if (detected)
    {
        // reconfig if configuration valid (0 to 3)
        if ((reconfig_num & 3) == reconfig_num)
        {
            xwait_not_vblank();
            xwait_vblank();
            xm_setbh(INT_CTRL, 0x80 | reconfig_num);        // reconfig FPGA to config_num
            detected = xosera_wait_sync();                  // wait for detect
        }
    }

    return detected;
}

int xosera_vid_width()
{
    xv_prep();

    return ((xm_getbl(FEATURE) & FEATURE_MONRES_F) == 0) ? 640 : 848;
}

int xosera_vid_height()
{
    return 480;
}

int xosera_max_hpos()
{
    xv_prep();

    return ((xm_getbl(FEATURE) & FEATURE_MONRES_F) == 0) ? MODE_640_FULL_H - 1 : MODE_848_FULL_H - 1;
}

int xosera_max_vpos()
{
    xv_prep();

    return ((xm_getbl(FEATURE) & FEATURE_MONRES_F) == 0) ? MODE_640_FULL_V - 1 : MODE_848_FULL_V - 1;
}

void xosera_set_pointer(int16_t x, int16_t y, uint16_t colormap_index)
{
    xv_prep();

    uint8_t ws = xm_getbl(FEATURE) & FEATURE_MONRES_F;        // 0 = 640x480

    // offscreen pixels plus 6 pixel "head start"
    x = x + (ws ? (MODE_848_FULL_H - 848 - 6) : (MODE_640_FULL_H - 640 - 6));
    // make sure doesn't wrap back onscreen due to limited bits in POINTER_H
    if (x < 0 || x > MODE_848_FULL_H)
    {
        x = MODE_848_FULL_H;
    }

    // make sure doesn't wrap back onscreen due to limited bits in POINTER_V
    if (y < -32 || y > 480)
    {
        y = 480;
    }
    else if (y < 0)
    {
        // special handling for partially off top (offset to before V wrap)
        y = y + (ws ? MODE_848_FULL_V : MODE_640_FULL_V);
    }

    while (!(xm_getbh(SYS_CTRL) & (SYS_CTRL_HBLANK_F | SYS_CTRL_VBLANK_F)))
        ;
    xreg_setw(POINTER_H, x);
    xreg_setw(POINTER_V, colormap_index | y);
}

int xosera_aud_channels()
{
    xv_prep();

    return xm_getbh(FEATURE) & (FEATURE_AUDCHAN_F >> 8);
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

    xmem_get_addr(XV_INFO_ADDR);
    if (xmem_getw_next_wait() == (('X' << 8) | 'o') && xmem_getw_next_wait() == (('s' << 8) | 'e') &&
        xmem_getw_next_wait() == (('r' << 8) | 'a'))
    {
        // xosera_info stored at end COPPER program memory
        uint16_t * wp = (uint16_t *)info;
        xmem_get_addr(XV_INFO_ADDR);
        for (uint16_t i = 0; i < (sizeof(xosera_info_t) / 2); i++)
        {
            *wp++ = xmem_getw_next_wait();
        }

        valid = true;
    }

    return valid;
}

// define xosera_ptr so GCC doesn't see const value (so it tries to keep it in a register vs reloading it).
__asm__(
    "               .section    .text\n"
    "               .align      2\n"
    "               .globl      xosera_ptr\n"
    "xosera_ptr:    .long       " XM_STR(XM_BASEADDR) "\n");

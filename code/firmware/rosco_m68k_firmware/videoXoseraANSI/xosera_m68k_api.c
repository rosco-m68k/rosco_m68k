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

    return true;
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

// TODO: retrieve xosera_info (placed in COPPER memory after xosera reconfig)
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

    uint16_t copsave = xreg_getw(COPP_CTRL);        // save COPP_CTRL

    xreg_setw(COPP_CTRL, 0x005A);        // set to test value 1
    if (xreg_getw(COPP_CTRL) != 0x005A)
    {
        return false;
    }
    xreg_setw(COPP_CTRL, 0x00A5);        // set to test value 2
    if (xreg_getw(COPP_CTRL) != 0x00A5)
    {
        return false;
    }

    xreg_setw(COPP_CTRL, copsave);        // restore

    uint16_t * wp = (uint16_t *)info;

    // xosera_info stored at end COPPER program memory
    xmem_get_addr(XV_INFO_ADDR);
    for (uint16_t i = 0; i < sizeof(xosera_info_t); i += 2)
    {
        *wp++ = xmem_getw_next_wait();
    }

    return true;        // TODO: Add CRC or similar?
}

// define xosera_ptr so GCC doesn't see const value (so it tries to keep it in a register vs reloading it).
__asm__(
    "               .section    .text\n"
    "               .align      2\n"
    "               .globl      xosera_ptr\n"
    "xosera_ptr:    .long       " XM_STR(XM_BASEADDR) "\n");

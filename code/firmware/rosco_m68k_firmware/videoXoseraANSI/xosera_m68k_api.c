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

#if defined(TEST_FIRMWARE)
#include <stdio.h>
#include <stdlib.h>
#endif

#include <machine.h>

#define XV_PREP_REQUIRED
#include "xosera_m68k_api.h"

void xv_delay(uint32_t ms)
{
    xv_prep();

    while (ms--)
    {
        uint16_t tms = 10;
        do
        {
            uint8_t tvb = xm_getbl(TIMER);
            while (tvb == xm_getbl(TIMER))
                ;
        } while (--tms);
    }
}

bool xosera_init(int reconfig_num)
{
    xv_prep();

    // check for Xosera presense (retry in case it is reconfiguring)
    for (int r = 0; r < 200; r++)
    {
        if (xosera_sync())
        {
            break;
        }
        cpu_delay(10);
    }

    // done if configuration if not valid (0 to 3)
    if ((reconfig_num & 3) == reconfig_num)
    {
        // set reconfig bit, along with reconfig values
        xm_setw(SYS_CTRL, 0x8000 | (uint16_t)(reconfig_num << 13));        // reboot FPGA to config_num
        if (xosera_sync())                                                 // should not sync right away...
        {
            return false;
        }
        // wait for Xosera to regain consciousness (takes ~80 milliseconds)
        for (int r = 0; r < 200; r++)
        {
            cpu_delay(10);
            if (xosera_sync())
            {
                break;
            }
        }
    }

    return xosera_sync();
}

bool xosera_sync()
{
    xv_prep();

    xm_setw(XR_ADDR, 0xF5A5);
    if (xm_getw(XR_ADDR) != 0xF5A5)
    {
        return false;        // not detected
    }
    xm_setw(XR_ADDR, 0xFA5A);
    if (xm_getw(XR_ADDR) != 0xFA5A)
    {
        return false;        // not detected
    }
    return true;
}

// NOTE: size is in bytes, but assumed to be a multiple of 2 (words)
void xv_vram_fill(uint32_t vram_addr, uint32_t numwords, uint32_t word_value)
{
    xv_prep();

    xm_setw(WR_ADDR, (uint16_t)vram_addr);
    xm_setw(WR_INCR, 1);
    uint32_t long_value = (word_value << 16) | (uint16_t)(word_value & 0xffff);
    if (numwords & 1)
    {
        xm_setw(DATA, (uint16_t)word_value);
    }
    uint32_t long_size = numwords >> 1;
    while (long_size--)
    {
        xm_setl(DATA, long_value);
    }
}

// NOTE: numbytes is in bytes, but assumed to be a multiple of 2 (words)
void xv_copy_to_vram(uint16_t * source, uint32_t vram_dest, uint32_t numbytes)
{
    xv_prep();

    xm_setw(WR_ADDR, (uint16_t)vram_dest);
    xm_setw(WR_INCR, 1);
    if (numbytes & 2)
    {
        xm_setw(DATA, *source++);
    }
    uint32_t * long_ptr  = (uint32_t *)source;
    uint32_t   long_size = numbytes >> 2;
    while (long_size--)
    {
        xm_setl(DATA, *long_ptr++);
    }
}

// NOTE: size is in bytes, but assumed to be a multiple of 2 (words)
void xv_copy_from_vram(uint32_t vram_source, uint16_t * dest, uint32_t numbytes)
{
    xv_prep();

    xm_setw(RD_ADDR, (uint16_t)vram_source);
    xm_setw(RD_INCR, 1);
    if (numbytes & 2)
    {
        *dest++ = xm_getw(DATA);
    }
    uint32_t * long_ptr  = (uint32_t *)dest;
    uint32_t   long_size = numbytes >> 2;
    while (long_size--)
    {
        *long_ptr++ = xm_getl(DATA);
    }
}

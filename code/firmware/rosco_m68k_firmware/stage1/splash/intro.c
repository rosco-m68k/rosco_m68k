/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2024 Ross Bamford
 * MIT License
 *
 * Rosco boot concept intro screen
 * ------------------------------------------------------------
 */

#include <stdlib.h>
#include <machine.h>
#include <limits.h>

#include "xosera_m68k_api.h"
#include "interlace.h"
#include "pcx.h"

#include "splash.h"

#ifdef HAVE_SPLASH_AUDIO
#include "bong.h"
#endif

#define COPPER_GLITCH

#ifdef DEBUG_SPLASH
#include "dprint.h"
#else
#define dprintf(...)            (((void)(0)))
#endif

#ifdef COPPER_GLITCH
#define ENTER_GLITCH_CHANCE     99990
#define EXIT_GLITCH_CHANCE      92500
#define GLITCH_SWITCH_CHANCE    70000
#endif

#ifdef HAVE_SPLASH_AUDIO
#define AUDIO_RATE              11025
#define AUDIO_BUFFER_SIZE       0x200
#define TILE_FONT_SIZE          0x1000
#define AUDIO_BUFFER_A          ((XR_TILE_ADDR+TILE_FONT_SIZE))
#define AUDIO_BUFFER_B          ((AUDIO_BUFFER_A+AUDIO_BUFFER_SIZE))
#endif

#define SHOW_DELAY              3

#define FADE_IN_DELAY           3
#define FADE_OUT    
#define FADE_OUT_DELAY          2

volatile uint32_t *tick_int = (uint32_t*)0x408;
volatile uint32_t *upticks  = (uint32_t*)0x40c;

void MC_DELAY_MSEC_10(int);

static void splash_delay_loop(uint32_t secs) {
    xv_prep();

    uint32_t now = *upticks;
    uint32_t end_ticks;
    if (secs == 0) {
        end_ticks = UINT_MAX;
    } else {
        end_ticks = now + (secs * 100);
    }

#   ifdef COPPER_GLITCH
    bool cop_on = true;
    bool in_glitch = false;
#   endif

#   ifdef HAVE_SPLASH_AUDIO
    uint32_t audio_start_ticks = now + 100;

    uint32_t clk_hz = xosera_sample_hz();
    uint16_t period = (clk_hz + AUDIO_RATE - 1) / AUDIO_RATE;        // rate is samples per second
    dprintf("Period is %d\n", period);

    xreg_setw(AUD_CTRL, AUD_CTRL_AUD_EN_F);
    xreg_setw(AUD0_PERIOD, period);
    xreg_setw(AUD0_VOL, MAKE_AUD_VOL(AUD_VOL_FULL / 2, AUD_VOL_FULL / 2));

    bool prime = true;
    bool done = false;
    uint32_t src_ptr = 0;
    uint32_t current_buf = AUDIO_BUFFER_A;
#   endif

    while (*upticks < end_ticks) {

        // Handle audio sample feeding if compiled in...
#       ifdef HAVE_SPLASH_AUDIO
        if ((*upticks > audio_start_ticks) && (prime || (xm_getw(INT_CTRL) & INT_CTRL_AUD0_INTR_F))) {
            xm_setw(INT_CTRL, INT_CTRL_AUD_ALL_F);
            prime = false;

            if (done) {
                // disable audio system
                xreg_setw(AUD_CTRL, 0x0000);
            }

            // copy data to buffer
            int copy_len = AUDIO_BUFFER_SIZE;
            int data_remain = bong_data_len - src_ptr;
            if (data_remain < AUDIO_BUFFER_SIZE) {
                dprintf("Fetched last chunk of %d\n", data_remain);
                copy_len = data_remain;
                done = true;        // Signal done next time we get an interrupt pending...
            }
            copy_len /= 2;

            xm_setw(WR_XADDR, current_buf);

            for (int i = 0; i < copy_len; i++) {
                uint16_t word = bong_data[src_ptr++] << 8;
                word |= bong_data[src_ptr++];

                xm_setw(XDATA, word);
            }            

            xreg_setw(AUD0_LENGTH, (copy_len - 1) | AUD_LENGTH_TILEMEM_F);
            xreg_setw(AUD0_START, current_buf);

            current_buf = (current_buf == AUDIO_BUFFER_A) ? AUDIO_BUFFER_B : AUDIO_BUFFER_A;
        }
#       endif

        // Handle glitch effect if compiled in...
#       ifdef COPPER_GLITCH
        if (in_glitch) {
            // do we want to exit the glitch?
            if ((rand() / (RAND_MAX / (100000 + 1) + 1)) > 92500) {
                // exit glitch
                cop_on = false;
                in_glitch = false;
                xwait_vblank();
                xreg_setw(COPP_CTRL, 0x0000);
            } else {
                // random glitchiness
                if ((rand() / (RAND_MAX / (100000 + 1) + 1)) > 70000) {
                    if (cop_on) {
                        cop_on = false;
                        xwait_vblank();
                        xreg_setw(COPP_CTRL, 0x0000);
                    } else {
                        cop_on = true;
                        xwait_vblank();
                        xreg_setw(COPP_CTRL, 0x8000);
                    }

                    MC_DELAY_MSEC_10(2);
                }
            }
        } else {
            // do we want to enter a glitch?
            if ((rand() / (RAND_MAX / (100000 + 1) + 1)) > 99990) {
                in_glitch = true;
            }
        }
#       endif
    }

#   ifdef HAVE_SPLASH_AUDIO
    // Disable audio, just in case sound was longer than delay...
    xreg_setw(AUD_CTRL, 0x0000);
#   endif
}

void intro(void) {
#   ifdef COPPER_GLITCH
    srand(*tick_int);
#   endif

    dprintf("Image is at 0x%08x (%d bytes)\n", splash_data, splash_data_len);

    xv_prep();

    dprintf("\nxosera_init(0)...");
#   ifdef DEBUG_SPLASH
    bool success = xosera_init(XINIT_CONFIG_848x480);
#   else
    xosera_init(XINIT_CONFIG_848x480);
#   endif

    dprintf("%s\n", success ? "succeeded" : "FAILED" /*, xv_reg_getw(vidwidth), xv_reg_getw(vidheight)*/);

    xreg_setw(PA_GFX_CTRL, 0x0065);     /* 320x240 8bpp */
    xreg_setw(PA_DISP_ADDR, 0x0000);
    xreg_setw(PA_LINE_LEN, 424 >> 1);
    xm_setw(WR_INCR, 0x0001);

    // Clear both palettes to black, A to hide draw, B to make glitch effect (and fade) work
    xmem_setw_next_addr(XR_COLOR_B_ADDR);
    for (int i = 0; i < 256; i++) {
        xmem_setw_next(0);
    }

    xmem_setw_next_addr(XR_COLOR_B_ADDR);
    for (int i = 0; i < 256; i++) {
        xmem_setw_next(0xF000);
    }

#   ifdef COPPER_GLITCH
    // load copper program
    xwait_vblank();
    xmem_setw_next_addr(interlace_start);
    for (uint8_t i = 0; i < interlace_size; i++) {
        xmem_setw_next(interlace_bin[i]);
    }
    dprintf("Copper initialized\n");
#   endif

    // 1.5s delay for screen to sync...
    // MC_DELAY_MSEC_10(150);
    show_pcx(splash_data_len, splash_data, FADE_IN_DELAY);

#   ifdef COPPER_GLITCH
    xwait_vblank();
    xreg_setw(COPP_CTRL, 0x0000);
#   endif

    splash_delay_loop(SHOW_DELAY);

#   ifdef COPPER_GLITCH
    xreg_setw(COPP_CTRL, 0x0000);
    dprintf("Done glitching\n");
#   endif
}

void intro_end(void) {
#   ifdef FADE_OUT
    xv_prep();

    for (int i = 0; i < 16; i++) {
        xwait_vblank();

        uint16_t alpha = i << 12;
        xmem_setw_next_addr(XR_COLOR_B_ADDR);
        for (int i = 0; i < 256; i++) {
            xmem_setw_next(alpha);
        }

        for (int j = 0; j < FADE_OUT_DELAY - 1; j++) {
            xwait_vblank();
            xwait_not_vblank();
        }
    }    
#else
    xmem_setw_next_addr(XR_COLOR_B_ADDR);
    for (int i = 0; i < 256; i++) {
        xmem_setw_next(alpha);
    }

    MC_DELAY_MSEC_10(75);
#   endif
}


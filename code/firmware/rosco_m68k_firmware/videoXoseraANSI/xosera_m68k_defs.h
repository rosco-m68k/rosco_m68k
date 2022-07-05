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
 * Copyright (c) 2021-2022 Xark
 * MIT License
 *
 * Xosera rosco_m68k C register definition header file
 * ------------------------------------------------------------
 */

// See: https://github.com/XarkLabs/Xosera/blob/master/REFERENCE.md

#if !defined(XOSERA_M68K_DEFS_H)
#define XOSERA_M68K_DEFS_H

#define XM_BASEADDR 0xf80060        // Xosera rosco_m68k 68010 register base address

// Xosera XR Memory Regions (size in 16-bit words)
#define XR_CONFIG_REGS  0x0000        // 0x0000-0x000F 16 config/ctrl registers
#define XR_PA_REGS      0x0010        // 0x0010-0x0017 8 playfield A video registers
#define XR_PB_REGS      0x0018        // 0x0018-0x001F 8 playfield B video registers
#define XR_AUDIO_REGS   0x0020        // 0x0020-0x002F 16 audio playback registers      // TODO: audio
#define XR_BLIT_REGS    0x0040        // 0x0040-0x004B 12 blitter registers
#define XR_TILE_ADDR    0x4000        // (R/W) 0x4000-0x53FF tile glyph/tile map memory
#define XR_TILE_SIZE    0x1400        //                     5120 x 16-bit tile glyph/tile map memory
#define XR_COLOR_ADDR   0x8000        // (R/W) 0x8000-0x81FF 2 x A & B color lookup memory
#define XR_COLOR_SIZE   0x0200        //                     2 x 256 x 16-bit words  (0xARGB)
#define XR_COLOR_A_ADDR 0x8000        // (R/W) 0x8000-0x80FF A 256 entry color lookup memory
#define XR_COLOR_A_SIZE 0x0100        //                     256 x 16-bit words (0xARGB)
#define XR_COLOR_B_ADDR 0x8100        // (R/W) 0x8100-0x81FF B 256 entry color lookup memory
#define XR_COLOR_B_SIZE 0x0100        //                     256 x 16-bit words (0xARGB)
#define XR_COPPER_ADDR  0xC000        // (R/W) 0xC000-0xC7FF copper program memory (32-bit instructions)
#define XR_COPPER_SIZE  0x0800        //                     2048 x 16-bit copper program memory addresses

// Xosera version info put in COPPER memory after FPGA reconfigure
#define XV_INFO_ADDR        (XR_COPPER_ADDR + XR_COPPER_SIZE - (XV_INFO_SIZE >> 1))
#define XV_INFO_SIZE        64        // 64 bytes total for "struct _xosera_info" (32 words in copper memory)
#define XV_INFO_DESCRIPTION 0         // 48 character description string
#define XV_INFO_VER_MAJOR   56        // BCD major version number
#define XV_INFO_VER_MINOR   57        // BCD minor version number
#define XV_INFO_GITMODIFIED 59        // non-zero if design modified from git version
#define XV_INFO_GITHASH     60        // byte offset in xosera_info for githash uint32_t

// Macros to make bit-fields easier (works similar to Verilog "+:" operator, e.g., word[RIGHTMOST_BIT +: BIT_WIDTH])
// encode value into bit-field for register
#define XB_(v, right_bit, bit_width) ((((uint16_t)(v)) & ((1 << (bit_width)) - 1)) << (right_bit))
// decode bit-field from register into value
#define XV_(v, right_bit, bit_width) ((((uint16_t)(v)) >> (right_bit)) & ((1 << (bit_width)) - 1))

// Xosera Main Registers (XM Registers, directly CPU accessable)
// NOTE: Main register numbers are multiplied by 4 for rosco_m68k, because of even byte 6800 8-bit addressing plus
// 16-bit registers
#define XM_SYS_CTRL  0x00        // (R /W+) status bits, FPGA config, write masking
#define XM_INT_CTRL  0x04        // (R /W ) interrupt status/control
#define XM_TIMER     0x08        // (RO   ) read 1/10th millisecond timer
#define XM_RD_XADDR  0x0C        // (R /W+) XR register/address for XM_XDATA read access
#define XM_WR_XADDR  0x10        // (R /W ) XR register/address for XM_XDATA write access
#define XM_XDATA     0x14        // (R /W+) read/write XR register/memory at XM_RD_XADDR/XM_WR_XADDR
#define XM_RD_INCR   0x18        // (R /W ) increment value for XM_RD_ADDR read from XM_DATA/XM_DATA_2
#define XM_RD_ADDR   0x1C        // (R /W+) VRAM address for reading from VRAM when XM_DATA/XM_DATA_2 is read
#define XM_WR_INCR   0x20        // (R /W ) increment value for XM_WR_ADDR on write to XM_DATA/XM_DATA_2
#define XM_WR_ADDR   0x24        // (R /W ) VRAM address for writing to VRAM when XM_DATA/XM_DATA_2 is written
#define XM_DATA      0x28        // (R+/W+) read/write VRAM word at XM_RD_ADDR/XM_WR_ADDR & add XM_RD_INCR/XM_WR_INCR
#define XM_DATA_2    0x2C        // (R+/W+) 2nd XM_DATA(to allow for 32-bit read/write access)
#define XM_UNUSED_0C 0x30        // (- /- )
#define XM_UNUSED_0D 0x34        // (- /- )
#define XM_UNUSED_0E 0x38        // (- /- )
#define XM_UNUSED_0F 0x3C        // (- /- )

// SYS_CTRL bit numbers NOTE: These are bits in high byte of SYS_CTRL word (for access with fast address register
// indirect with no offset)
#define SYS_CTRL_MEM_BUSY_B  7        // (RO   )  memory read/write operation pending (with contended memory)
#define SYS_CTRL_BLIT_FULL_B 6        // (RO   )  blitter queue is full, do not write new operation to blitter registers
#define SYS_CTRL_BLIT_BUSY_B 5        // (RO   )  blitter is still busy performing an operation (not done)
#define SYS_CTRL_UNUSED_12_B 4        // (RO   )  unused (reads 0)
#define SYS_CTRL_HBLANK_B    3        // (RO   )  video signal is in horizontal blank period
#define SYS_CTRL_VBLANK_B    2        // (RO   )  video signal is in vertical blank period
#define SYS_CTRL_UNUSED_9_B  1        // (RO   )  unused (reads 0)
#define SYS_CTRL_UNUSED_8_B  0        // (- /- )
// SYS_CTRL bit flags
#define SYS_CTRL_MEM_BUSY_F  0x80        // (RO   )  memory read/write operation pending (with contended memory)
#define SYS_CTRL_BLIT_FULL_F 0x40        // (RO   )  blitter queue is full (do not write to blitter registers)
#define SYS_CTRL_BLIT_BUSY_F 0x20        // (RO   )  blitter is still busy performing an operation (not done)
#define SYS_CTRL_UNUSED_12_F 0x10        // (RO   )  unused (reads 0)
#define SYS_CTRL_HBLANK_F    0x08        // (RO   )  video signal is in horizontal blank period
#define SYS_CTRL_VBLANK_F    0x04        // (RO   )  video signal is in vertical blank period
#define SYS_CTRL_UNUSED_9_F  0x02        // (RO   )  unused (reads 0)
#define SYS_CTRL_UNUSED_8_F  0x01        // (- /- )

// INT_CTRL bit numbers NOTE: These are word bits for INT_CTRL word
#define INT_CTRL_RECONFIG_B   15        // reconfigure FPGA to config # in bits [9:8] of INT_CTRL
#define INT_CTRL_BLIT_EN_B    14        // blitter ready interrupt mask
#define INT_CTRL_TIMER_EN_B   13        // timer match interrupt mask
#define INT_CTRL_VIDEO_EN_B   12        // v-blank or copper interrupt mask
#define INT_CTRL_AUD3_EN_B    11        // audio channel 3 ready (START addr was loaded)
#define INT_CTRL_AUD2_EN_B    10        // audio channel 2 ready (START addr was loaded)
#define INT_CTRL_AUD1_EN_B    9         // audio channel 1 ready (START addr was loaded)
#define INT_CTRL_AUD0_EN_B    8         // audio channel 0 ready (START addr was loaded)
#define INT_CTRL_UNUSED_7_B   7         // timer match read interrupt (status, write acknowledge)
#define INT_CTRL_BLIT_INTR_B  6         // blitter ready interrupt (read status, write acknowledge)
#define INT_CTRL_TIMER_INTR_B 5         // timer match read interrupt (status, write acknowledge)
#define INT_CTRL_VIDEO_INTR_B 4         // v-blank or copper interrupt (read status, write acknowledge)
#define INT_CTRL_AUD3_INTR_B  3         // audio channel ready interrupt (read status, write acknowledge)
#define INT_CTRL_AUD2_INTR_B  2         // audio channel ready interrupt (read status, write acknowledge)
#define INT_CTRL_AUD1_INTR_B  1         // audio channel ready interrupt (read status, write acknowledge)
#define INT_CTRL_AUD0_INTR_B  0         // audio channel ready interrupt (read status, write acknowledge)
// INT_CTRL bit flags
#define INT_CTRL_RECONFIG_F   0x8000        // reconfigure FPGA to config # in bits [9:8] of INT_CTRL
#define INT_CTRL_BLIT_EN_F    0x4000        // blitter ready interrupt enable
#define INT_CTRL_TIMER_EN_F   0x2000        // timer match interrupt enable
#define INT_CTRL_VIDEO_EN_F   0x1000        // v-blank or copper interrupt enable
#define INT_CTRL_AUD3_EN_F    0x0800        // audio channel 3 interrupt enable
#define INT_CTRL_AUD2_EN_F    0x0400        // audio channel 2 interrupt enable
#define INT_CTRL_AUD1_EN_F    0x0200        // audio channel 1 interrupt enable
#define INT_CTRL_AUD0_EN_F    0x0100        // audio channel 0 interrupt enable
#define INT_CTRL_AUD_ALL_EN_F 0x0F00        // all audio channel interrupts enable
#define INT_CTRL_EN_ALL_F     0x7F00        // enable all interrupts
#define INT_CTRL_UNUSED_7_F   0x0080        // timer match read interrupt (status, write acknowledge)
#define INT_CTRL_BLIT_INTR_F  0x0040        // blitter ready interrupt (read status, write acknowledge)
#define INT_CTRL_TIMER_INTR_F 0x0020        // timer match read interrupt (status, write acknowledge)
#define INT_CTRL_VIDEO_INTR_F 0x0010        // v-blank or copper interrupt (read status, write acknowledge)
#define INT_CTRL_AUD3_INTR_F  0x0008        // audio channel ready interrupt (read status, write acknowledge)
#define INT_CTRL_AUD2_INTR_F  0x0004        // audio channel ready interrupt (read status, write acknowledge)
#define INT_CTRL_AUD1_INTR_F  0x0002        // audio channel ready interrupt (read status, write acknowledge)
#define INT_CTRL_AUD0_INTR_F  0x0001        // audio channel ready interrupt (read status, write acknowledge)
#define INT_CTRL_AUD_ALL_F    0x000F        // all audio channels status/acknowledge
#define INT_CTRL_CLEAR_ALL_F  0x007F        // clear all interrupts

// XR Extended Register / Region (accessed via XM_RD_XADDR/XM_WR_XADDR and XM_XDATA)

//  Video Config and Copper XR Registers
#define XR_VID_CTRL  0x00        // (R /W) display control and border color index
#define XR_COPP_CTRL 0x01        // (R /W) display synchronized coprocessor control
#define XR_AUD_CTRL  0x02        // (- /-) TODO: audio channel control
#define XR_UNUSED_03 0x03        // (- /-) TODO: unused XR 03
#define XR_VID_LEFT  0x04        // (R /W) left edge of active display window (typically 0)
#define XR_VID_RIGHT 0x05        // (R /W) right edge of active display window +1 (typically 640 or 848)
#define XR_UNUSED_06 0x06        // (- /-) TODO: unused XR 06
#define XR_UNUSED_07 0x07        // (- /-) TODO: unused XR 07
#define XR_SCANLINE  0x08        // (RO  ) scanline (including offscreen >= 480)
#define XR_FEATURES  0x09        // (RO  ) update frequency of monitor mode in BCD 1/100th Hz (0x5997 = 59.97 Hz)
#define XR_VID_HSIZE 0x0A        // (RO  ) native pixel width of monitor mode (e.g. 640/848)
#define XR_VID_VSIZE 0x0B        // (RO  ) native pixel height of monitor mode (e.g. 480)
#define XR_UNUSED_0C 0x0C        // (- /-) TODO: unused XR 0C
#define XR_UNUSED_0D 0x0D        // (- /-) TODO: unused XR 0D
#define XR_UNUSED_0E 0x0E        // (- /-) TODO: unused XR 0E
#define XR_UNUSED_0F 0x0F        // (- /-) TODO: unused XR 0F

// Playfield A Control XR Registers
#define XR_PA_GFX_CTRL  0x10        // (R /W) playfield A graphics control
#define XR_PA_TILE_CTRL 0x11        // (R /W) playfield A tile control
#define XR_PA_DISP_ADDR 0x12        // (R /W) playfield A display VRAM start address
#define XR_PA_LINE_LEN  0x13        // (R /W) playfield A display line width in words
#define XR_PA_HV_FSCALE 0x14        // (R /W) playfield A horizontal and vertical fractional scale
#define XR_PA_HV_SCROLL 0x15        // (R /W) playfield A horizontal and vertical fine scroll
#define XR_PA_LINE_ADDR 0x16        // (- /W) playfield A scanline start address (loaded at start of line)
#define XR_PA_UNUSED_17 0x17        // // TODO: colorbase?

// Playfield B Control XR Registers
#define XR_PB_GFX_CTRL  0x18        // (R /W) playfield B graphics control
#define XR_PB_TILE_CTRL 0x19        // (R /W) playfield B tile control
#define XR_PB_DISP_ADDR 0x1A        // (R /W) playfield B display VRAM start address
#define XR_PB_LINE_LEN  0x1B        // (R /W) playfield B display line width in words
#define XR_PB_HV_FSCALE 0x1C        // (R /W) playfield B horizontal and vertical fractional scale
#define XR_PB_HV_SCROLL 0x1D        // (R /W) playfield B horizontal and vertical fine scroll
#define XR_PB_LINE_ADDR 0x1E        // (- /W) playfield B scanline start address (loaded at start of line)
#define XR_PB_UNUSED_1F 0x1F        // // TODO: colorbase?

// Audio Registers
#define XR_AUD0_VOL    0x20        // (WO/-) // TODO: WIP
#define XR_AUD0_PERIOD 0x21        // (WO/-) // TODO: WIP
#define XR_AUD0_LENGTH 0x22        // (WO/-) // TODO: WIP
#define XR_AUD0_START  0x23        // (WO/-) // TODO: WIP
#define XR_AUD1_VOL    0x24        // (WO/-) // TODO: WIP
#define XR_AUD1_PERIOD 0x25        // (WO/-) // TODO: WIP
#define XR_AUD1_LENGTH 0x26        // (WO/-) // TODO: WIP
#define XR_AUD1_START  0x27        // (WO/-) // TODO: WIP
#define XR_AUD2_VOL    0x28        // (WO/-) // TODO: WIP
#define XR_AUD2_PERIOD 0x29        // (WO/-) // TODO: WIP
#define XR_AUD2_LENGTH 0x2A        // (WO/-) // TODO: WIP
#define XR_AUD2_START  0x2B        // (WO/-) // TODO: WIP
#define XR_AUD3_VOL    0x2C        // (WO/-) // TODO: WIP
#define XR_AUD3_PERIOD 0x2D        // (WO/-) // TODO: WIP
#define XR_AUD3_LENGTH 0x2E        // (WO/-) // TODO: WIP
#define XR_AUD3_START  0x2F        // (WO/-) // TODO: WIP

// Blitter Registers
#define XR_BLIT_CTRL  0x40        // (R /W) blit control (transparency control, logic op and op input flags)
#define XR_BLIT_MOD_A 0x41        // (R /W) blit line modulo added to SRC_A (XOR if A const)
#define XR_BLIT_SRC_A 0x42        // (R /W) blit A source VRAM read address / constant value
#define XR_BLIT_MOD_B 0x43        // (R /W) blit line modulo added to SRC_B (XOR if B const)
#define XR_BLIT_SRC_B 0x44        // (R /W) blit B AND source VRAM read address / constant value
#define XR_BLIT_MOD_C 0x45        // (R /W) blit line XOR modifier for C_VAL const
#define XR_BLIT_VAL_C 0x46        // (R /W) blit C XOR constant value
#define XR_BLIT_MOD_D 0x47        // (R /W) blit modulo added to D destination after each line
#define XR_BLIT_DST_D 0x48        // (R /W) blit D VRAM destination write address
#define XR_BLIT_SHIFT 0x49        // (R /W) blit first and last word nibble masks and nibble right shift (0-3)
#define XR_BLIT_LINES 0x4A        // (R /W) blit number of lines minus 1, (repeats blit word count after modulo calc)
#define XR_BLIT_WORDS 0x4B        // (R /W) blit word count minus 1 per line (write starts blit operation)
#define XR_UNUSED_2C  0x4C        // (- /-) TODO: unused XR 2C
#define XR_UNUSED_2D  0x4D        // (- /-) TODO: unused XR 2D
#define XR_UNUSED_2E  0x4E        // (- /-) TODO: unused XR 2E
#define XR_UNUSED_2F  0x4F        // (- /-) TODO: unused XR 2F

// constants
#define XR_GFX_BPP_1 0        // Px_GFX_CTRL.bpp (1-bpp + fore/back attribute color)
#define XR_GFX_BPP_4 1        // Px_GFX_CTRL.bpp (4-bpp, 16 color)
#define XR_GFX_BPP_8 2        // Px_GFX_CTRL.bpp (8-bpp 256 color)
#define XR_GFX_BPP_X 3        // Px_GFX_CTRL.bpp (reserved)

#define MAKE_GFX_CTRL(colbase, blank, bpp, bm, hx, vx)                                                                 \
    (XB_(colbase, 8, 8) | XB_(blank, 7, 1) | XB_(bm, 6, 1) | XB_(bpp, 4, 2) | XB_(hx, 2, 2) | XB_(vx, 0, 2))
#define MAKE_TILE_CTRL(tilebase, map_in_tile, glyph_in_vram, tileheight)                                               \
    (((tilebase)&0xFC00) | XB_(map_in_tile, 9, 1) | XB_(glyph_in_vram, 8, 1) | XB_(((tileheight)-1), 0, 4))
#define MAKE_HV_SCROLL(h_scrl, v_scrl) (XB_(h_scrl, 8, 8) | XB_(v_scrl, 0, 8))

#define MAKE_VID_CTRL(borcol, intmask) (XB_(borcol, 8, 8) | XB_(intmask, 0, 4))

// Copper instruction helper macros
#define COP_WAIT_HV(h_pos, v_pos)   (0x00000000 | XB_((uint32_t)(v_pos), 16, 12) | XB_((uint32_t)(h_pos), 4, 12))
#define COP_WAIT_H(h_pos)           (0x00000001 | XB_((uint32_t)(h_pos), 4, 12))
#define COP_WAIT_V(v_pos)           (0x00000002 | XB_((uint32_t)(v_pos), 16, 12))
#define COP_WAIT_F()                (0x00000003)
#define COP_END()                   (0x00000003)
#define COP_SKIP_HV(h_pos, v_pos)   (0x20000000 | XB_((uint32_t)(v_pos), 16, 12) | XB_((uint32_t)(h_pos), 4, 12))
#define COP_SKIP_H(h_pos)           (0x20000001 | XB_((uint32_t)(h_pos), 4, 12))
#define COP_SKIP_V(v_pos)           (0x20000002 | XB_((uint32_t)(v_pos), 16, 12))
#define COP_SKIP_F()                (0x20000003)
#define COP_JUMP(cop_addr)          (0x40000000 | XB_((uint32_t)(cop_addr), 16, 13))
#define COP_MOVER(val16, xreg)      (0x60000000 | XB_((uint32_t)(XR_##xreg), 16, 13) | ((uint16_t)(val16)))
#define COP_MOVEF(val16, tile_addr) (0x80000000 | XB_((uint32_t)(tile_addr), 16, 13) | ((uint16_t)(val16)))
#define COP_MOVEP(rgb16, color_num) (0xA0000000 | XB_((uint32_t)(color_num), 16, 13) | ((uint16_t)(rgb16)))
#define COP_MOVEC(val16, cop_addr)  (0xC0000000 | XB_((uint32_t)(cop_addr), 16, 13) | ((uint16_t)(val16)))

// TODO: repace more magic constants with defines for bit positions


#endif        // XOSERA_M68K_DEFS_H

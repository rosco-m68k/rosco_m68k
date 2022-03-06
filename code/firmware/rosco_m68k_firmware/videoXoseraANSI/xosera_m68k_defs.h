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
 * Xosera rosco_m68k C register definition header file
 * ------------------------------------------------------------
 */

// See: https://github.com/XarkLabs/Xosera/blob/master/REFERENCE.md

#define XM_BASEADDR 0xf80060        // Xosera rosco_m68k register base address

// Xosera Main Registers (XM Registers, directly CPU accessable)
// NOTE: Main register numbers are multiplied by 4 for rosco_m68k, because of even byte 6800 8-bit addressing plus
// 16-bit registers
#define XM_XR_ADDR   0x0         // (R /W+) XR register number/address for XM_XR_DATA read/write access
#define XM_XR_DATA   0x4         // (R /W+) read/write XR register/memory at XM_XR_ADDR (XM_XR_ADDR incr. on write)
#define XM_RD_INCR   0x8         // (R /W ) increment value for XM_RD_ADDR read from XM_DATA/XM_DATA_2
#define XM_RD_ADDR   0xC         // (R /W+) VRAM address for reading from VRAM when XM_DATA/XM_DATA_2 is read
#define XM_WR_INCR   0x10        // (R /W ) increment value for XM_WR_ADDR on write to XM_DATA/XM_DATA_2
#define XM_WR_ADDR   0x14        // (R /W ) VRAM address for writing to VRAM when XM_DATA/XM_DATA_2 is written
#define XM_DATA      0x18        // (R+/W+) read/write VRAM word at XM_RD_ADDR/XM_WR_ADDR (and add XM_RD_INCR/XM_WR_INCR)
#define XM_DATA_2    0x1C        // (R+/W+) 2nd XM_DATA(to allow for 32-bit read/write access)
#define XM_SYS_CTRL  0x20        // (R /W+) busy status, FPGA reconfig, interrupt status/control, write masking
#define XM_TIMER     0x24        // (RO   ) read 1/10th millisecond timer [TODO]
#define XM_UNUSED_A  0x28        // (R /W ) unused direct register 0xA [TODO]
#define XM_UNUSED_B  0x2C        // (R /W ) unused direct register 0xB [TODO]
#define XM_RW_INCR   0x30        // (R /W ) XM_RW_ADDR increment value on read/write of XM_RW_DATA/XM_RW_DATA_2
#define XM_RW_ADDR   0x34        // (R /W+) read/write address for VRAM access from XM_RW_DATA/XM_RW_DATA_2
#define XM_RW_DATA   0x38        // (R+/W+) read/write VRAM word at XM_RW_ADDR (and add XM_RW_INCR)
#define XM_RW_DATA_2 0x3C        // (R+/W+) 2nd XM_RW_DATA(to allow for 32-bit read/write access)

// XR Extended Register / Region (accessed via XM_XR_ADDR and XM_XR_DATA)

// XR Register Regions
#define XR_CONFIG_REGS   0x0000        // 0x0000-0x000F config XR registers
#define XR_PA_REGS       0x0010        // 0x0010-0x0017 playfield A XR registers
#define XR_PB_REGS       0x0018        // 0x0018-0x001F playfield B XR registers
#define XR_BLIT_REGS     0x0020        // 0x0020-0x002F 2D-blit XR registers
#define XR_POLYDRAW_REGS 0x0030        // 0x0030-0x003F line/poly draw XR registers

// XR Memory Regions
#define XR_COLOR_MEM  0x8000        // (WO) 0x8000-0x80FF 256 x 16-bit color lookup memory ($xRGB)
#define XR_TILE_MEM   0x9000        // (WO) 0x9000-0x9FFF 4096 x 16-bit tile glyph storage memory
#define XR_COPPER_MEM 0xA000        // (WO) 0xA000-0xA7FF 2048 x 16-bit copper program memory
#define XR_SPRITE_MEM 0xB000        // (WO) 0xB000-0xB0FF 256 x 16-bit sprite cursor memory
#define XR_UNUSED_MEM 0xC000        //      0xC000-0xF0FF unused

//  Video Config and Copper XR Registers
#define XR_VID_CTRL   0x00        // (R /W) display control and border color index
#define XR_COPP_CTRL  0x01        // (R /W) display synchronized coprocessor control
#define XR_CURSOR_X   0x02        // (R /W) sprite cursor X position
#define XR_CURSOR_Y   0x03        // (R /W) sprite cursor Y position
#define XR_VID_TOP    0x04        // (R /W) top line of active display window (typically 0)
#define XR_VID_BOTTOM 0x05        // (R /W) bottom line of active display window (typically 479)
#define XR_VID_LEFT   0x06        // (R /W) left edge of active display window (typically 0)
#define XR_VID_RIGHT  0x07        // (R /W) right edge of active display window (typically 639 or 847)
#define XR_SCANLINE   0x08        // (RO  ) [15] in V blank, [14] in H blank [10:0] V scanline
#define XR_UNUSED_09  0x09        // (RO  )
#define XR_VERSION    0x0A        // (RO  ) Xosera optional feature bits [15:8] and version code [7:0] [TODO]
#define XR_GITHASH_H  0x0B        // (RO  ) [15:0] high 16-bits of 32-bit Git hash build identifier
#define XR_GITHASH_L  0x0C        // (RO  ) [15:0] low 16-bits of 32-bit Git hash build identifier
#define XR_VID_HSIZE  0x0D        // (RO  ) native pixel width of monitor mode (e.g. 640/848)
#define XR_VID_VSIZE  0x0E        // (RO  ) native pixel height of monitor mode (e.g. 480)
#define XR_VID_VFREQ  0x0F        // (RO  ) update frequency of monitor mode in BCD 1/100th Hz (0x5997 = 59.97 Hz)

// Playfield A Control XR Registers
#define XR_PA_GFX_CTRL  0x10        // (R /W) playfield A graphics control
#define XR_PA_TILE_CTRL 0x11        // (R /W) playfield A tile control
#define XR_PA_DISP_ADDR 0x12        // (R /W) playfield A display VRAM start address
#define XR_PA_LINE_LEN  0x13        // (R /W) playfield A display line width in words
#define XR_PA_HV_SCROLL 0x14        // (R /W) playfield A horizontal and vertical fine scroll
#define XR_PA_LINE_ADDR 0x15        // (R /W) playfield A scanline start address (loaded at start of line)
#define XR_PA_UNUSED_16 0x16        //
#define XR_PA_UNUSED_17 0x17        //

// Playfield B Control XR Registers
#define XR_PB_GFX_CTRL  0x18        // (R /W) playfield B graphics control
#define XR_PB_TILE_CTRL 0x19        // (R /W) playfield B tile control
#define XR_PB_DISP_ADDR 0x1A        // (R /W) playfield B display VRAM start address
#define XR_PB_LINE_LEN  0x1B        // (R /W) playfield B display line width in words
#define XR_PB_HV_SCROLL 0x1C        // (R /W) playfield B horizontal and vertical fine scroll
#define XR_PB_LINE_ADDR 0x1D        // (R /W) playfield B scanline start address (loaded at start of line)
#define XR_PB_UNUSED_1E 0x1E        //
#define XR_PB_UNUSED_1F 0x1F        //

// Macros to make bit-fields easier
#define XB_(v, lb, rb) (((v) & ((1 << ((lb) - (rb) + 1)) - 1)) << (rb))

#define MAKE_SYS_CTRL(reboot, bootcfg, wrmask, intena)                                                                 \
    (XB_(reboot, 15, 15) | XB_(bootcfg, 14, 13) | XB_(wrmask, 11, 8) | XB_(intena, 3, 0))
#define MAKE_VID_CTRL(borcol, intmask) (XB_(borcol, 15, 8) | XB_(intmask, 3, 0))
#define MAKE_GFX_CTRL(colbase, blank, bpp, bm, hx, vx)                                                                 \
    (XB_(colbase, 15, 8) | XB_(blank, 7, 7) | XB_(bm, 6, 6) | XB_(bpp, 5, 4) | XB_(hx, 3, 2) | XB_(vx, 1, 0))
#define MAKE_TILE_CTRL(tilebase, vram, tileheight) (((tilebase)&0xFC00) | XB_(vram, 8, 8) | XB_(((tileheight)-1), 3, 0))
#define MAKE_HV_SCROLL(h_scrl, v_scrl)             (XB_(h_scrl, 12, 8) | XB_(v_scrl, 5, 0))

// Copper instruction helper macros
#define COP_WAIT_HV(h_pos, v_pos)   (0x00000000 | XB_((uint32_t)(v_pos), 26, 16) | XB_((uint32_t)(h_pos), 14, 4))
#define COP_WAIT_H(h_pos)           (0x00000001 | XB_((uint32_t)(h_pos), 14, 4))
#define COP_WAIT_V(v_pos)           (0x00000002 | XB_((uint32_t)(v_pos), 26, 16))
#define COP_WAIT_F()                (0x00000003)
#define COP_END()                   (0x00000003)
#define COP_SKIP_HV(h_pos, v_pos)   (0x20000000 | XB_((uint32_t)(v_pos), 26, 16) | XB_((uint32_t)(h_pos), 14, 4))
#define COP_SKIP_H(h_pos)           (0x20000001 | XB_((uint32_t)(h_pos), 14, 4))
#define COP_SKIP_V(v_pos)           (0x20000002 | XB_((uint32_t)(v_pos), 26, 16))
#define COP_SKIP_F()                (0x20000003 | XB_((uint32_t)(0), 14, 4))
#define COP_JUMP(cop_addr)          (0x40000000 | XB_((uint32_t)(cop_addr), 26, 16))
#define COP_MOVER(val16, xreg)      (0x90000000 | XB_((uint32_t)(XR_##xreg), 23, 16) | ((uint16)(val16)))
#define COP_MOVEF(val16, tile_addr) (0xa0000000 | XB_((uint32_t)(tile_addr), 27, 16) | ((uint16)(val16)))
#define COP_MOVEP(rgb16, color_num) (0xB0000000 | XB_((uint32_t)(color_num), 23, 16) | ((uint16)(rgb16)))
#define COP_MOVEC(val16, cop_addr)  (0xC0000000 | XB_((uint32_t)(cop_addr), 26, 16) | ((uint16)(val16)))

// TODO blit and polydraw

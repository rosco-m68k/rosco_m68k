;
;  vim: set et ts=4 sw=4
; ------------------------------------------------------------
;   __ __
;  |  |  |___ ___ ___ ___ ___
;  |-   -| . |_ -| -_|  _| .'|
;  |__|__|___|___|___|_| |__,|
;
;  Xark's Open Source Enhanced Retro Adapter
;
;  - "Not as clumsy or random as a GPU, an embedded retro
;     adapter for a more civilized age."
;
;  ------------------------------------------------------------
;  Copyright (c) 2021-2022 Xark
;  MIT License
;
;  Xosera rosco_m68k asm register definition header file
;  ------------------------------------------------------------
;

; See: https://github.com/XarkLabs/Xosera/blob/master/REFERENCE.md

; #if !defined(XOSERA_M68K_DEFS_H)
; #define XOSERA_M68K_DEFS_H

XM_BASEADDR             equ     $f80060        ; Xosera rosco_m68k 68010 register base address

; Xosera XR Memory Regions (size in 16-bit words)
XR_CONFIG_REGS          equ     $0000       ; 0x0000-0x000F 16 config/ctrl registers
XR_PA_REGS              equ     $0010       ; 0x0010-0x0017 8 playfield A video registers
XR_PB_REGS              equ     $0018       ; 0x0000-0x001F 8 playfield B video registers
XR_BLIT_REGS            equ     $0020       ; 0x0020-0x002F 12 blitter registers
XR_AUDIO_REGS           equ     $0030       ; 0x0030-0x003F 16 audio playback registers      ; TODO: audio
XR_TILE_ADDR            equ     $4000       ; (R/W) 0x4000-0x53FF tile glyph/tile map memory
XR_TILE_SIZE            equ     $1400       ;                     5120 x 16-bit tile glyph/tile map memory
XR_COLOR_ADDR           equ     $8000       ; (R/W) 0x8000-0x81FF 2 x A & B color lookup memory
XR_COLOR_SIZE           equ     $0200       ;                     2 x 256 x 16-bit words  (0xARGB)
XR_COLOR_A_ADDR         equ     $8000       ; (R/W) 0x8000-0x80FF A 256 entry color lookup memory
XR_COLOR_A_SIZE         equ     $0100       ;                     256 x 16-bit words (0xARGB)
XR_COLOR_B_ADDR         equ     $8100       ; (R/W) 0x8100-0x81FF B 256 entry color lookup memory
XR_COLOR_B_SIZE         equ     $0100       ;                     256 x 16-bit words (0xARGB)
XR_COPPER_ADDR          equ     $C000       ; (R/W) 0xC000-0xC7FF copper program memory (32-bit instructions)
XR_COPPER_SIZE          equ     $0800       ;                     2048 x 16-bit copper program memory addresses

XV_INFO_SIZE            equ     64          ; 64 bytes total for "struct _xosera_info"
XV_INFO_SIZEW           equ     32          ; 32 words in copper memory
XV_INFO_ADDR            equ     XR_COPPER_ADDR+XR_COPPER_SIZE-XV_INFO_SIZEW
XV_INFO_DESCRIPTION     equ     0           ; 48 character description string
XV_INFO_VER_MAJOR       equ     56          ; BCD major version number
XV_INFO_VER_MINOR       equ     57          ; BCD minor version number
XV_INFO_GITMODIFIED     equ     59          ; non-zero if design modified from git version
XV_INFO_GITHASH         equ     60          ; byte offset in xosera_info for githash uint32_t

; Xosera Main Registers (XM Registers, directly CPU accessable)
; NOTE: Main register numbers are multiplied by 4 for rosco_m68k, because of even byte 6800 8-bit addressing plus
; 16-bit registers
XM_SYS_CTRL             equ     $00         ; (R /W+) status bits, FPGA config, write masking
XM_INT_CTRL             equ     $04         ; (R /W ) interrupt status/control
XM_TIMER                equ     $08         ; (RO   ) read 1/10th millisecond timer
XM_RD_XADDR             equ     $0C         ; (R /W+) XR register/address for XM_XDATA read access
XM_WR_XADDR             equ     $10         ; (R /W ) XR register/address for XM_XDATA write access
XM_XDATA                equ     $14         ; (R /W+) read/write XR register/memory at XM_RD_XADDR/XM_WR_XADDR
XM_RD_INCR              equ     $18         ; (R /W ) increment value for XM_RD_ADDR read from XM_DATA/XM_DATA_2
XM_RD_ADDR              equ     $1C         ; (R /W+) VRAM address for reading from VRAM when XM_DATA/XM_DATA_2 is read
XM_WR_INCR              equ     $20         ; (R /W ) increment value for XM_WR_ADDR on write to XM_DATA/XM_DATA_2
XM_WR_ADDR              equ     $24         ; (R /W ) VRAM address for writing to VRAM when XM_DATA/XM_DATA_2 is written
XM_DATA                 equ     $28         ; (R+/W+) read/write VRAM word at XM_RD_ADDR/XM_WR_ADDR & add XM_RD_INCR/XM_WR_INCR
XM_DATA_2               equ     $2C         ; (R+/W+) 2nd XM_DATA(to allow for 32-bit read/write access)
XM_UNUSED_0C            equ     $30         ; (- /- )
XM_UNUSED_0D            equ     $34         ; (- /- )
XM_UNUSED_0E            equ     $38         ; (- /- )
XM_UNUSED_0F            equ     $3C         ; (- /- )

; NOTE: These are bits in high byte of SYS_CTRL word (fastest to access)
SYS_CTRL_MEM_BUSY_B     equ     7           ; (RO   )  memory read/write operation pending (with contended memory)
SYS_CTRL_BLIT_FULL_B    equ     6           ; (RO   )  blitter queue is full, do not write new operation to blitter registers
SYS_CTRL_BLIT_BUSY_B    equ     5           ; (RO   )  blitter is still busy performing an operation (not done)
SYS_CTRL_UNUSED_12_B    equ     4           ; (RO   )  unused (reads 0)
SYS_CTRL_HBLANK_B       equ     3           ; (RO   )  video signal is in horizontal blank period
SYS_CTRL_VBLANK_B       equ     2           ; (RO   )  video signal is in vertical blank period
SYS_CTRL_UNUSED_9_B     equ     1           ; (RO   )  unused (reads 0)
SYS_CTRL_UNUSED_8_B     equ     0           ; (- /- )
; bit field values for above
SYS_CTRL_MEM_BUSY_F     equ     $80         ; (RO   )  memory read/write operation pending (with contended memory)
SYS_CTRL_BLIT_FULL_F    equ     $40         ; (RO   )  blitter queue is full, do not write new operation to blitter registers
SYS_CTRL_BLIT_BUSY_F    equ     $20         ; (RO   )  blitter is still busy performing an operation (not done)
SYS_CTRL_UNUSED_12_F    equ     $10         ; (RO   )  unused (reads 0)
SYS_CTRL_HBLANK_F       equ     $08         ; (RO   )  video signal is in horizontal blank period
SYS_CTRL_VBLANK_F       equ     $04         ; (RO   )  video signal is in vertical blank period
SYS_CTRL_UNUSED_9_F     equ     $02         ; (RO   )  unused (reads 0)
SYS_CTRL_UNUSED_8_F     equ     $01         ; (- /- )

; NOTE: These are word bits for INT_CTRL word
INT_CTRL_RECONFIG_B     equ     15          ; reconfigure FPGA to config # in bits [9:8] of INT_CTRL
INT_CTRL_BLIT_EN_B      equ     14          ; blitter ready interrupt mask
INT_CTRL_TIMER_EN_B     equ     13          ; timer match interrupt mask
INT_CTRL_VIDEO_EN_B     equ     12          ; v-blank or copper interrupt mask
INT_CTRL_AUD3_EN_B      equ     11          ; audio channel 3 ready (START addr was loaded) // TODO: move these
INT_CTRL_AUD2_EN_B      equ     10          ; audio channel 2 ready (START addr was loaded) // TODO: move these
INT_CTRL_AUD1_EN_B      equ     9           ; audio channel 1 ready (START addr was loaded) // TODO: move these
INT_CTRL_AUD0_EN_B      equ     8           ; audio channel 0 ready (START addr was loaded) // TODO: move these
INT_CTRL_UNUSED_7_B     equ     7           ; timer match read interrupt (status, write acknowledge)
INT_CTRL_BLIT_INTR_B    equ     6           ; blitter ready interrupt (read status, write acknowledge)
INT_CTRL_TIMER_INTR_B   equ     5           ; timer match read interrupt (status, write acknowledge)
INT_CTRL_VIDEO_INTR_B   equ     4           ; v-blank or copper interrupt (read status, write acknowledge)
INT_CTRL_AUD3_INTR_B    equ     3           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD2_INTR_B    equ     2           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD1_INTR_B    equ     1           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD0_INTR_B    equ     0           ; audio channel ready interrupt (read status, write acknowledge)
; bit field values for above
INT_CTRL_RECONFIG_F     equ     $8000       ; reconfigure FPGA to config # in bits [9:8] of INT_CTRL
INT_CTRL_BLIT_EN_F      equ     $4000       ; blitter ready interrupt mask
INT_CTRL_TIMER_EN_F     equ     $2000       ; timer match interrupt mask
INT_CTRL_VIDEO_EN_F     equ     $1000       ; v-blank or copper interrupt mask
INT_CTRL_AUD3_EN_F      equ     $0800       ; audio channel 3 ready (START addr was loaded) // TODO: move these
INT_CTRL_AUD2_EN_F      equ     $0400       ; audio channel 2 ready (START addr was loaded) // TODO: move these
INT_CTRL_AUD1_EN_F      equ     $0200       ; audio channel 1 ready (START addr was loaded) // TODO: move these
INT_CTRL_AUD0_EN_F      equ     $0100       ; audio channel 0 ready (START addr was loaded) // TODO: move these
INT_CTRL_EN_ALL_F       equ     $7F00       ; enable all interrupt sources

INT_CTRL_UNUSED_7_F     equ     $0080       ; timer match read interrupt (status, write acknowledge)
INT_CTRL_BLIT_INTR_F    equ     $0040       ; blitter ready interrupt (read status, write acknowledge)
INT_CTRL_TIMER_INTR_F   equ     $0020       ; timer match read interrupt (status, write acknowledge)
INT_CTRL_VIDEO_INTR_F   equ     $0010       ; v-blank or copper interrupt (read status, write acknowledge)
INT_CTRL_AUD3_INTR_F    equ     $0008       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD2_INTR_F    equ     $0004       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD1_INTR_F    equ     $0002       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD0_INTR_F    equ     $0001       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_CLEAR_ALL_F    equ     $007F       ; write to clear all interrupt sources

; XR Extended Register / Region (accessed via XM_XR_ADDR and XM_XR_DATA)

;  Video Config and Copper XR Registers
XR_VID_CTRL             equ     $00         ; (R /W) display control and border color index
XR_COPP_CTRL            equ     $01         ; (R /W) display synchronized coprocessor control
XR_AUD_CTRL             equ     $02         ; (- /-) TODO: audio channel control
XR_UNUSED_03            equ     $03         ; (- /-) TODO: unused XR 03
XR_VID_LEFT             equ     $04         ; (R /W) left edge of active display window (typically 0)
XR_VID_RIGHT            equ     $05         ; (R /W) right edge of active display window +1 (typically 640 or 848)
XR_UNUSED_06            equ     $06         ; (- /-) TODO: unused XR 06
XR_UNUSED_07            equ     $07         ; (- /-) TODO: unused XR 07
XR_SCANLINE             equ     $08         ; (RO  ) scanline (including offscreen >= 480)
XR_FEATURES             equ     $09         ; (RO  ) update frequency of monitor mode in BCD 1/100th Hz (0x5997 = 59.97 Hz)
XR_VID_HSIZE            equ     $0A         ; (RO  ) native pixel width of monitor mode (e.g. 640/848)
XR_VID_VSIZE            equ     $0B         ; (RO  ) native pixel height of monitor mode (e.g. 480)
XR_UNUSED_0C            equ     $0C         ; (- /-) TODO: unused XR 0C
XR_UNUSED_0D            equ     $0D         ; (- /-) TODO: unused XR 0D
XR_UNUSED_0E            equ     $0E         ; (- /-) TODO: unused XR 0E
XR_UNUSED_0F            equ     $0F         ; (- /-) TODO: unused XR 0F

; Playfield A Control XR Registers
XR_PA_GFX_CTRL          equ     $10         ; (R /W) playfield A graphics control
XR_PA_TILE_CTRL         equ     $11         ; (R /W) playfield A tile control
XR_PA_DISP_ADDR         equ     $12         ; (R /W) playfield A display VRAM start address
XR_PA_LINE_LEN          equ     $13         ; (R /W) playfield A display line width in words
XR_PA_HV_FSCALE         equ     $14         ; (R /W) playfield A horizontal and vertical fractional scale
XR_PA_HV_SCROLL         equ     $15         ; (R /W) playfield A horizontal and vertical fine scroll
XR_PA_LINE_ADDR         equ     $16         ; (- /W) playfield A scanline start address (loaded at start of line)
XR_PA_UNUSED_17         equ     $17         ; ; TODO: colorbase?

; Playfield B Control XR Registers
XR_PB_GFX_CTRL          equ     $18         ; (R /W) playfield B graphics control
XR_PB_TILE_CTRL         equ     $19         ; (R /W) playfield B tile control
XR_PB_DISP_ADDR         equ     $1A         ; (R /W) playfield B display VRAM start address
XR_PB_LINE_LEN          equ     $1B         ; (R /W) playfield B display line width in words
XR_PB_HV_FSCALE         equ     $1C         ; (R /W) playfield B horizontal and vertical fractional scale
XR_PB_HV_SCROLL         equ     $1D         ; (R /W) playfield B horizontal and vertical fine scroll
XR_PB_LINE_ADDR         equ     $1E         ; (- /W) playfield B scanline start address (loaded at start of line)
XR_PB_UNUSED_1F         equ     $1F         ; ; TODO: colorbase?

; Audio Registers
XR_AUD0_VOL             equ     $20         ; (-/W) // TODO: WIP
XR_AUD0_PERIOD          equ     $21         ; (-/W) // TODO: WIP
XR_AUD0_LENGTH          equ     $22         ; (-/W) // TODO: WIP
XR_AUD0_START           equ     $23         ; (-/W) // TODO: WIP
XR_AUD1_VOL             equ     $24         ; (-/W) // TODO: WIP
XR_AUD1_PERIOD          equ     $25         ; (-/W) // TODO: WIP
XR_AUD1_LENGTH          equ     $26         ; (-/W) // TODO: WIP
XR_AUD1_START           equ     $27         ; (-/W) // TODO: WIP
XR_AUD2_VOL             equ     $28         ; (-/W) // TODO: WIP
XR_AUD2_PERIOD          equ     $29         ; (-/W) // TODO: WIP
XR_AUD2_LENGTH          equ     $2A         ; (-/W) // TODO: WIP
XR_AUD2_START           equ     $2B         ; (-/W) // TODO: WIP
XR_AUD3_VOL             equ     $2C         ; (-/W) // TODO: WIP
XR_AUD3_PERIOD          equ     $2D         ; (-/W) // TODO: WIP
XR_AUD3_LENGTH          equ     $2E         ; (-/W) // TODO: WIP
XR_AUD3_START           equ     $2F         ; (-/W) // TODO: WIP

; Blitter Registers
XR_BLIT_CTRL            equ     $30         ; (-/W ) blit control (transparency control, logic op and op input flags)
XR_BLIT_MOD_A           equ     $31         ; (-/W ) blit line modulo added to SRC_A (XOR if A const)
XR_BLIT_SRC_A           equ     $32         ; (-/W ) blit A source VRAM read address / constant value
XR_BLIT_MOD_B           equ     $33         ; (-/W ) blit line modulo added to SRC_B (XOR if B const)
XR_BLIT_SRC_B           equ     $34         ; (-/W ) blit B AND source VRAM read address / constant value
XR_BLIT_MOD_C           equ     $35         ; (-/W ) blit line XOR modifier for C_VAL const
XR_BLIT_VAL_C           equ     $36         ; (-/W ) blit C XOR constant value
XR_BLIT_MOD_D           equ     $37         ; (-/W ) blit modulo added to D destination after each line
XR_BLIT_DST_D           equ     $38         ; (-/W ) blit D VRAM destination write address
XR_BLIT_SHIFT           equ     $39         ; (-/W ) blit first and last word nibble masks and nibble right shift (0-3)
XR_BLIT_LINES           equ     $3A         ; (-/W ) blit number of lines minus 1, (repeats blit word count after modulo calc)
XR_BLIT_WORDS           equ     $3B         ; (-/W+) blit word count minus 1 per line (write starts blit operation)
XR_UNUSED_2C            equ     $3C         ; (-/- ) TODO: unused XR 2C
XR_UNUSED_2D            equ     $3D         ; (-/- ) TODO: unused XR 2D
XR_UNUSED_2E            equ     $3E         ; (-/- ) TODO: unused XR 2E
XR_UNUSED_2F            equ     $3F         ; (-/- ) TODO: unused XR 2F

; constants
XR_GFX_BPP_1            equ     0           ; Px_GFX_CTRL.bpp (1-bpp + fore/back attribute color)
XR_GFX_BPP_4            equ     1           ; Px_GFX_CTRL.bpp (4-bpp, 16 color)
XR_GFX_BPP_8            equ     2           ; Px_GFX_CTRL.bpp (8-bpp 256 color)
XR_GFX_BPP_X            equ     3           ; Px_GFX_CTRL.bpp (reserved)

; Copper instruction helper macros
; COP_WAIT_HV(h_pos, v_pos)   (0x00000000 | XB_((uint32_t)(v_pos), 16, 12) | XB_((uint32_t)(h_pos), 4, 12))
; COP_WAIT_H(h_pos)           (0x00000001 | XB_((uint32_t)(h_pos), 4, 12))
; COP_WAIT_V(v_pos)           (0x00000002 | XB_((uint32_t)(v_pos), 16, 12))
; COP_WAIT_F()                (0x00000003)
; COP_END()                   (0x00000003)
; COP_SKIP_HV(h_pos, v_pos)   (0x20000000 | XB_((uint32_t)(v_pos), 16, 12) | XB_((uint32_t)(h_pos), 4, 12))
; COP_SKIP_H(h_pos)           (0x20000001 | XB_((uint32_t)(h_pos), 4, 12))
; COP_SKIP_V(v_pos)           (0x20000002 | XB_((uint32_t)(v_pos), 16, 12))
; COP_SKIP_F()                (0x20000003)
; COP_JUMP(cop_addr)          (0x40000000 | XB_((uint32_t)(cop_addr), 16, 13))
; COP_MOVER(val16, xreg)      (0x60000000 | XB_((uint32_t)(XR_##xreg), 16, 13) | ((uint16_t)(val16)))
; COP_MOVEF(val16, tile_addr) (0x80000000 | XB_((uint32_t)(tile_addr), 16, 13) | ((uint16_t)(val16)))
; COP_MOVEP(rgb16, color_num) (0xA0000000 | XB_((uint32_t)(color_num), 16, 13) | ((uint16_t)(rgb16)))
; COP_MOVEC(val16, cop_addr)  (0xC0000000 | XB_((uint32_t)(cop_addr), 16, 13) | ((uint16_t)(val16)))

; TODO: repace more magic constants with defines for bit positions

;
; vim: set et ts=4 sw=4
;------------------------------------------------------------
;  __ __
; |  |  |___ ___ ___ ___ ___
; |-   -| . |_ -| -_|  _| .'|
; |__|__|___|___|___|_| |__,|
;
; Xark's Open Source Enhanced Retro Adapter
;
; - "Not as clumsy or random as a GPU, an embedded retro
;    adapter for a more civilized age."
;
; ------------------------------------------------------------
; Copyright (c) 2021-2022 Xark
; MIT License
;
; Xosera rosco_m68k asm register definition header file
; ------------------------------------------------------------
;

; See: https://github.com/XarkLabs/Xosera/blob/master/REFERENCE.md

XM_BASEADDR             equ     $f80060     ; Xosera rosco_m68k 68010 register base address

; Xosera XR Memory Regions (size in 16-bit words)
XR_CONFIG_REGS          equ     $0000       ; 0x0000-0x000F 16 config/ctrl registers
XR_PA_REGS              equ     $0010       ; 0x0010-0x0017 8 playfield A video registers
XR_PB_REGS              equ     $0018       ; 0x0018-0x001F 8 playfield B video registers
XR_AUDIO_REGS           equ     $0020       ; 0x0020-0x002F 16 audio playback registers      // TODO: audio
XR_BLIT_REGS            equ     $0040       ; 0x0040-0x004B 10 blitter registers
XR_TILE_ADDR            equ     $4000       ; (R/W) 0x4000-0x53FF tile glyph/tile map memory
XR_TILE_SIZE            equ     $1400       ;                     5120 x 16-bit tile glyph/tile map memory
XR_COLOR_ADDR           equ     $8000       ; (R/W) 0x8000-0x81FF 2 x A & B color lookup memory
XR_COLOR_SIZE           equ     $0200       ;                     2 x 256 x 16-bit words  (0xARGB)
XR_COLOR_A_ADDR         equ     $8000       ; (R/W) 0x8000-0x80FF A 256 entry color lookup memory
XR_COLOR_A_SIZE         equ     $0100       ;                     256 x 16-bit words (0xARGB)
XR_COLOR_B_ADDR         equ     $8100       ; (R/W) 0x8100-0x81FF B 256 entry color lookup memory
XR_COLOR_B_SIZE         equ     $0100       ;                     256 x 16-bit words (0xARGB)
XR_COPPER_ADDR          equ     $C000       ; (R/W) 0xC000-0xC5FF copper memory (16-bit instructions)
XR_COPPER_SIZE          equ     $0600       ;                     1024+512 x 16-bit copper memory words

; Xosera version info put in COPPER memory after FPGA reconfigure
XV_INFO_ADDR            equ     XR_COPPER_ADDR+XR_COPPER_SIZE-128
XV_INFO_SIZE            equ     256        ; 256 bytes total for "struct _xosera_info" (last 128 words in copper memory)

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
XM_FEATURES             equ     $3C         ; (RO)

; SYS_CTRL bit numbers NOTE: These are bits in high byte of SYS_CTRL word (for access with fast address register
; indirect with no offset)
SYS_CTRL_MEM_BUSY_B     equ     7           ; (RO   )  memory read/write operation pending (with contended memory)
SYS_CTRL_BLIT_FULL_B    equ     6           ; (RO   )  blitter queue is full, do not write new operation to blitter registers
SYS_CTRL_BLIT_BUSY_B    equ     5           ; (RO   )  blitter is still busy performing an operation (not done)
SYS_CTRL_UNUSED_12_B    equ     4           ; (RO   )  unused (reads 0)
SYS_CTRL_HBLANK_B       equ     3           ; (RO   )  video signal is in horizontal blank period
SYS_CTRL_VBLANK_B       equ     2           ; (RO   )  video signal is in vertical blank period
SYS_CTRL_UNUSED_9_B     equ     1           ; (RO   )  unused (reads 0)
SYS_CTRL_UNUSED_8_B     equ     0           ; (- /- )
; SYS_CTRL bit flags
SYS_CTRL_MEM_BUSY_F     equ     $80         ; (RO   )  memory read/write operation pending (with contended memory)
SYS_CTRL_BLIT_FULL_F    equ     $40         ; (RO   )  blitter queue is full (do not write to blitter registers)
SYS_CTRL_BLIT_BUSY_F    equ     $20         ; (RO   )  blitter is still busy performing an operation (not done)
SYS_CTRL_UNUSED_12_F    equ     $10         ; (RO   )  unused (reads 0)
SYS_CTRL_HBLANK_F       equ     $08         ; (RO   )  video signal is in horizontal blank period
SYS_CTRL_VBLANK_F       equ     $04         ; (RO   )  video signal is in vertical blank period
SYS_CTRL_UNUSED_9_F     equ     $02         ; (RO   )  unused (reads 0)
SYS_CTRL_UNUSED_8_F     equ     $01         ; (- /- )

; INT_CTRL bit numbers NOTE: These are word bits for INT_CTRL word
INT_CTRL_RECONFIG_B     equ     15          ; reconfigure FPGA to config # in bits [9:8] of INT_CTRL
INT_CTRL_BLIT_EN_B      equ     14          ; blitter ready interrupt mask
INT_CTRL_TIMER_EN_B     equ     13          ; timer match interrupt mask
INT_CTRL_VIDEO_EN_B     equ     12          ; v-blank or copper interrupt mask
INT_CTRL_AUD3_EN_B      equ     11          ; audio channel 3 ready (START addr was loaded)
INT_CTRL_AUD2_EN_B      equ     10          ; audio channel 2 ready (START addr was loaded)
INT_CTRL_AUD1_EN_B      equ     9           ; audio channel 1 ready (START addr was loaded)
INT_CTRL_AUD0_EN_B      equ     8           ; audio channel 0 ready (START addr was loaded)
INT_CTRL_UNUSED_7_B     equ     7           ; timer match read interrupt (status, write acknowledge)
INT_CTRL_BLIT_INTR_B    equ     6           ; blitter ready interrupt (read status, write acknowledge)
INT_CTRL_TIMER_INTR_B   equ     5           ; timer match read interrupt (status, write acknowledge)
INT_CTRL_VIDEO_INTR_B   equ     4           ; v-blank or copper interrupt (read status, write acknowledge)
INT_CTRL_AUD3_INTR_B    equ     3           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD2_INTR_B    equ     2           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD1_INTR_B    equ     1           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD0_INTR_B    equ     0           ; audio channel ready interrupt (read status, write acknowledge)
; INT_CTRL bit flags
INT_CTRL_RECONFIG_F     equ     $8000       ; reconfigure FPGA to config # in bits [9:8] of INT_CTRL
INT_CTRL_BLIT_EN_F      equ     $4000       ; blitter ready interrupt enable
INT_CTRL_TIMER_EN_F     equ     $2000       ; timer match interrupt enable
INT_CTRL_VIDEO_EN_F     equ     $1000       ; v-blank or copper interrupt enable
INT_CTRL_AUD3_EN_F      equ     $0800       ; audio channel 3 interrupt enable
INT_CTRL_AUD2_EN_F      equ     $0400       ; audio channel 2 interrupt enable
INT_CTRL_AUD1_EN_F      equ     $0200       ; audio channel 1 interrupt enable
INT_CTRL_AUD0_EN_F      equ     $0100       ; audio channel 0 interrupt enable
INT_CTRL_AUD_ALL_EN_F   equ     $0F00       ; all audio channel interrupts enable
INT_CTRL_EN_ALL_F       equ     $7F00       ; enable all interrupts
INT_CTRL_UNUSED_7_F     equ     $0080       ; timer match read interrupt (status, write acknowledge)
INT_CTRL_BLIT_INTR_F    equ     $0040       ; blitter ready interrupt (read status, write acknowledge)
INT_CTRL_TIMER_INTR_F   equ     $0020       ; timer match read interrupt (status, write acknowledge)
INT_CTRL_VIDEO_INTR_F   equ     $0010       ; v-blank or copper interrupt (read status, write acknowledge)
INT_CTRL_AUD3_INTR_F    equ     $0008       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD2_INTR_F    equ     $0004       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD1_INTR_F    equ     $0002       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD0_INTR_F    equ     $0001       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD_ALL_F      equ     $000F       ; all audio channels status/acknowledge
INT_CTRL_CLEAR_ALL_F    equ     $007F       ; clear all interrupts

; XR Extended Register / Region (accessed via XM_RD_XADDR/XM_WR_XADDR and XM_XDATA)

;  Video Config and Copper XR Registers
XR_VID_CTRL             equ     $00         ; (R /W) display control and border color index
XR_COPP_CTRL            equ     $01         ; (R /W) display synchronized coprocessor control
XR_AUD_CTRL             equ     $02         ; (- /-) TODO: audio channel control
XR_SCANLINE             equ     $03         ; (R /W) read scanline (incl. offscreen), write signal video interrupt
XR_VID_LEFT             equ     $04         ; (R /W) left edge of active display window (typically 0)
XR_VID_RIGHT            equ     $05         ; (R /W) right edge of active display window +1 (typically 640 or 848)
XR_UNUSED_06            equ     $06         ; (- /-) unused XR 06
XR_UNUSED_07            equ     $07         ; (- /-) unused XR 07
XR_UNUSED_08            equ     $08         ; (- /-) unused XR 08
XR_UNUSED_09            equ     $09         ; (- /-) unused XR 09
XR_UNUSED_0A            equ     $0A         ; (- /-) unused XR 0A
XR_UNUSED_0B            equ     $0B         ; (- /-) unused XR 0B
XR_UNUSED_0C            equ     $0C         ; (- /-) unused XR 0C
XR_UNUSED_0D            equ     $0D         ; (- /-) unused XR 0D
XR_UNUSED_0E            equ     $0E         ; (- /-) unused XR 0E
XR_UNUSED_0F            equ     $0F         ; (- /-) unused XR 0F
; XR_VID_CTRL bit numbers within word)
XR_VID_CTRL_SWAP_AB_B   equ     15          ; bit number to colormap used (pf A uses colormap B and vice versa)
XR_VID_CTRL_BORDCOL_B   equ     0           ; rightmost bit number of pf A color index
XR_VID_CTRL_BORDCOL_W   equ     8           ; bit width for pf A color index
; XR_VID_CTRL flag/mask
XR_VID_CTRL_SWAP_AB_F   equ     $8000       ; flag to swap colormap used (pf A uses colormap B and vice versa)
XR_VID_CTRL_BORDCOL_F   equ     $00FF       ; mask for pf A color index

; XR_COPP_CTRL bit numbers within word)
XR_COPP_CTRL_COPP_EN_B      equ     15      ; bit number to enable/disable copper
; XR_COPP_CTRL bit flag/mask
XR_COPP_CTRL_COPP_EN_F      equ     $8000    ; flag to enable/disable copper

; XR_AUD_CTRL bit numbers within word)
XR_AUD_CTRL_AUD_EN_B        equ     0           ; bit number to enable/disable audio
; XR_AUD_CTRL bit flag/mask
XR_AUD_CTRL_AUD_EN_F        equ     $0001       ; flag to enable/disable audio


; Playfield A Control XR Registers
XR_PA_GFX_CTRL          equ     $10         ; (R /W) playfield A graphics control
XR_PA_TILE_CTRL         equ     $11         ; (R /W) playfield A tile control
XR_PA_DISP_ADDR         equ     $12         ; (R /W) playfield A display VRAM start address
XR_PA_LINE_LEN          equ     $13         ; (R /W) playfield A display line width in words
XR_PA_HV_FSCALE         equ     $14         ; (R /W) playfield A horizontal and vertical fractional scale
XR_PA_HV_SCROLL         equ     $15         ; (R /W) playfield A horizontal and vertical fine scroll
XR_PA_LINE_ADDR         equ     $16         ; (- /W) playfield A scanline start address (loaded at start of line)
XR_PA_UNUSED_17         equ     $17         ; (- /-)

; Playfield B Control XR Registers
XR_PB_GFX_CTRL          equ     $18         ; (R /W) playfield B graphics control
XR_PB_TILE_CTRL         equ     $19         ; (R /W) playfield B tile control
XR_PB_DISP_ADDR         equ     $1A         ; (R /W) playfield B display VRAM start address
XR_PB_LINE_LEN          equ     $1B         ; (R /W) playfield B display line width in words
XR_PB_HV_FSCALE         equ     $1C         ; (R /W) playfield B horizontal and vertical fractional scale
XR_PB_HV_SCROLL         equ     $1D         ; (R /W) playfield B horizontal and vertical fine scroll
XR_PB_LINE_ADDR         equ     $1E         ; (- /W) playfield B scanline start address (loaded at start of line)
XR_PB_UNUSED_1F         equ     $1F         ; (- /-)

; Playfield GFX BPP constants
XR_GFX_BPP_1            equ     0           ; Px_GFX_CTRL.bpp (1-bpp + fore/back attribute color)
XR_GFX_BPP_4            equ     1           ; Px_GFX_CTRL.bpp (4-bpp, 16 color)
XR_GFX_BPP_8            equ     2           ; Px_GFX_CTRL.bpp (8-bpp 256 color)
XR_GFX_BPP_X            equ     3           ; Px_GFX_CTRL.bpp (reserved)

; XR_AUD_CTRL bit numbers within word)
XR_GFX_CTRL_V_REPEAT_B  equ     0
XR_GFX_CTRL_V_REPEAT_W  equ     2
XR_GFX_CTRL_H_REPEAT_B  equ     2
XR_GFX_CTRL_H_REPEAT_W  equ     2
XR_GFX_CTRL_BPP_B       equ     4
XR_GFX_CTRL_BPP_W       equ     2
XR_GFX_CTRL_BITMAP_B    equ     6
XR_GFX_CTRL_BLANK_B     equ     7
XR_GFX_CTRL_COLORBASE_B equ     8
XR_GFX_CTRL_COLORBASE_W equ     8
; XR_AUD_CTRL bit flag/mask
XR_GFX_CTRL_V_REPEAT_F  equ     $0003
XR_GFX_CTRL_H_REPEAT_F  equ     $000C
XR_GFX_CTRL_BPP_F       equ     $0030
XR_GFX_CTRL_BITMAP_F    equ     $0040
XR_GFX_CTRL_BLANK_F     equ     $0080
XR_GFX_CTRL_COLORBASE_F equ     $FF00

; XR_Px_TILE_CTRL bit numbers within word)
XR_TILE_CTRL_TILE_H_B       equ 0
XR_TILE_CTRL_TILE_H_W       equ 4
XR_TILE_CTRL_TILE_VRAM_B    equ 8
XR_TILE_CTRL_DISP_TILEMEM_B equ 9
XR_TILE_CTRL_TILEBASE_B     equ 10
XR_TILE_CTRL_TILEBASE_W     equ 6
; XR_Px_TILE_CTRL bit flag/mask
XR_TILE_CTRL_TILE_H_F       equ $000F
XR_TILE_CTRL_TILE_VRAM_F    equ $0100
XR_TILE_CTRL_DISP_TILEMEM_F equ $0200
XR_TILE_CTRL_TILEBASE_F     equ $FC00

; Audio Registers
XR_AUD0_VOL             equ     $20         ; (WO/-) // TODO: WIP
XR_AUD0_PERIOD          equ     $21         ; (WO/-) // TODO: WIP
XR_AUD0_LENGTH          equ     $22         ; (WO/-) // TODO: WIP
XR_AUD0_START           equ     $23         ; (WO/-) // TODO: WIP
XR_AUD1_VOL             equ     $24         ; (WO/-) // TODO: WIP
XR_AUD1_PERIOD          equ     $25         ; (WO/-) // TODO: WIP
XR_AUD1_LENGTH          equ     $26         ; (WO/-) // TODO: WIP
XR_AUD1_START           equ     $27         ; (WO/-) // TODO: WIP
XR_AUD2_VOL             equ     $28         ; (WO/-) // TODO: WIP
XR_AUD2_PERIOD          equ     $29         ; (WO/-) // TODO: WIP
XR_AUD2_LENGTH          equ     $2A         ; (WO/-) // TODO: WIP
XR_AUD2_START           equ     $2B         ; (WO/-) // TODO: WIP
XR_AUD3_VOL             equ     $2C         ; (WO/-) // TODO: WIP
XR_AUD3_PERIOD          equ     $2D         ; (WO/-) // TODO: WIP
XR_AUD3_LENGTH          equ     $2E         ; (WO/-) // TODO: WIP
XR_AUD3_START           equ     $2F         ; (WO/-) // TODO: WIP
; Audio flags
AUD_PER_RESTART_B       equ     15          ; AUDx_PERIOD bit 15 is force channel restart
AUD_PER_RESTART_F       equ     $8000
AUD_LEN_TILEMEM_B       equ     15          ; AUDx_LENGTH bit 15 is TILEMEM flag
AUD_LEN_TILEMEM_F       equ     $8000

; "Slim" blitter
XR_BLIT_CTRL            equ     $40         ; (WO) blit control ([15:8]=transp value, [5]=8 bpp, [4]=transp on, [0]=S constant)
XR_BLIT_ANDC            equ     $41         ; (WO) blit AND-COMPLEMENT constant value
XR_BLIT_XOR             equ     $42         ; (WO) blit XOR constant value
XR_BLIT_MOD_S           equ     $43         ; (WO) blit modulo added to S source after each line
XR_BLIT_SRC_S           equ     $44         ; (WO) blit S source VRAM read address / constant value
XR_BLIT_MOD_D           equ     $45         ; (WO) blit modulo added to D destination after each line
XR_BLIT_DST_D           equ     $46         ; (WO) blit D destination VRAM write address
XR_BLIT_SHIFT           equ     $47         ; (WO) blit first and last word nibble masks and nibble right shift (0-3)
XR_BLIT_LINES           equ     $48         ; (WO) blit number of lines minus 1, (repeats blit word count after modulo calc)
XR_BLIT_WORDS           equ     $49         ; (WO+) blit word count minus 1 per line (write starts blit operation)
XR_UNUSED_4A            equ     $4A         ; unused XR reg
XR_UNUSED_4B            equ     $4B         ; unused XR reg
XR_UNUSED_4C            equ     $4C         ; unused XR reg
XR_UNUSED_4D            equ     $4D         ; unused XR reg
XR_UNUSED_4E            equ     $4E         ; unused XR reg
XR_UNUSED_4F            equ     $4F         ; unused XR reg

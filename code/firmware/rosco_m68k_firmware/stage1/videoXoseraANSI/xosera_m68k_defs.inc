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

; See: https:;github.com/XarkLabs/Xosera/blob/master/REFERENCE.md

XM_BASEADDR             equ     $f80061     ; Xosera rosco_m68k 68010 register base address

; Xosera XR Memory Regions (size in 16-bit words)
XR_CONFIG_REGS          equ     $0000       ; (R/W) $0000-$0007 8 config/ctrl registers
XR_PA_REGS              equ     $0010       ; (R/W) $0010-$0017 8 playfield A video registers
XR_PB_REGS              equ     $0018       ; (R/W) $0018-$001F 8 playfield B video registers
XR_AUDIO_REGS           equ     $0020       ; (-/W) $0020-$002F 16 audio playback registers
XR_BLIT_REGS            equ     $0040       ; (-/W) $0040-$0049 10 blitter registers
XR_TILE_ADDR            equ     $4000       ; (R/W) $4000-$53FF tile glyph/tile map memory
XR_TILE_SIZE            equ     $1400       ;                     4096+1024 x 16-bit tile glyph/tile map memory
XR_COLOR_ADDR           equ     $8000       ; (R/W) $8000-$81FF 2 x A & B color lookup memory
XR_COLOR_SIZE           equ     $0200       ;                     2 x 256 x 16-bit words ($ARGB)
XR_COLOR_A_ADDR         equ     $8000       ; (R/W) $8000-$80FF A 256 entry color lookup memory
XR_COLOR_A_SIZE         equ     $0100       ;                     256 x 16-bit words ($ARGB)
XR_COLOR_B_ADDR         equ     $8100       ; (R/W) $8100-$81FF B 256 entry color lookup memory
XR_COLOR_B_SIZE         equ     $0100       ;                     256 x 16-bit words ($ARGB)
XR_POINTER_ADDR         equ     $8200       ; (-/W) $8200-$82FF 256 word 32x32 4-bpp pointer image
XR_POINTER_SIZE         equ     $0100       ;                     256 x 16-bit words (4-bit pixels)
XR_COPPER_ADDR          equ     $C000       ; (R/W) $C000-$C5FF copper memory (16-bit words)
XR_COPPER_SIZE          equ     $0600       ;                     1024+512 x 16-bit copper memory words

; Default 1-bpp font glyphs in TILE memory (total $1400 words)
FONT_ST_8x16_ADDR       equ     XR_TILE_ADDR+$0000
FONT_ST_8x16_SIZE       equ     $800
FONT_ST_8x8_ADDR        equ     XR_TILE_ADDR+$0800
FONT_ST_8x8_SIZE        equ     $400
FONT_PC_8x8_ADDR        equ     XR_TILE_ADDR+$0C00
FONT_PC_8x8_SIZE        equ     $400
FONT_HEX_8x8_ADDR       equ     XR_TILE_ADDR+$1000
FONT_HEX_8x8_SIZE       equ     $400

; Xosera version info put in COPPER memory after FPGA reconfigure
XV_INFO_BYTES           equ     256         ; 256 bytes total for "struct _xosera_info" (last 128 words in copper memory)
XV_INFO_WORDS           equ     128         ; 128 16-bit words (last 128 words in copper memory)
XV_INFO_ADDR            equ     XR_COPPER_ADDR+XR_COPPER_SIZE-XV_INFO_WORDS

; Xosera Main 16-bit Registers (directly CPU accessable XM Registers)
; NOTE: Main register numbers are multiplied by 4 for rosco_m68k, because of even byte 6800 8-bit addressing plus
; 16-bit registers
XM_SYS_CTRL             equ     $00         ; (R /W+) [15:8] status bits, write setup PIXEL_X/Y & options, [7:0] write masking
XM_INT_CTRL             equ     $04         ; (R /W+) FPGA config, interrupt status/control
XM_TIMER                equ     $08         ; (R /W+) read 1/10th millisecond timer, write 8-bit interval timer count
XM_RD_XADDR             equ     $0C         ; (R /W+) XR register/address for XM_XDATA read access
XM_WR_XADDR             equ     $10         ; (R /W ) XR register/address for XM_XDATA write access
XM_XDATA                equ     $14         ; (R /W+) read/write XR register/memory at XM_RD_XADDR/XM_WR_XADDR
XM_RD_INCR              equ     $18         ; (R /W ) increment value for XM_RD_ADDR read from XM_DATA/XM_DATA_2
XM_RD_ADDR              equ     $1C         ; (R /W+) VRAM address for reading from VRAM when XM_DATA/XM_DATA_2 is read
XM_WR_INCR              equ     $20         ; (R /W ) increment value for XM_WR_ADDR on write to XM_DATA/XM_DATA_2
XM_WR_ADDR              equ     $24         ; (R /W ) VRAM address for writing to VRAM when XM_DATA/XM_DATA_2 is written
XM_DATA                 equ     $28         ; (R+/W+) read/write VRAM word at XM_RD_ADDR/XM_WR_ADDR & add XM_RD_INCR/XM_WR_INCR
XM_DATA_2               equ     $2C         ; (R+/W+) 2nd XM_DATA(to allow for 32-bit read/write access)
XM_PIXEL_X              equ     $30         ; (- /W+) pixel X coordinate / setup pixel base address
XM_PIXEL_Y              equ     $34         ; (- /W+) pixel Y coordinate / setup pixel line width
XM_UART                 equ     $38         ; (R+/W+) optional debug USB UART communication
XM_FEATURE              equ     $3C         ; (R /- ) Xosera feature flags
; XR Extended Register / Region (accessed via XM_RD_XADDR/XM_WR_XADDR and XM_XDATA)
;  Video Config and Copper XR Registers
XR_VID_CTRL             equ     $00         ; (R /W) display control and border color index
XR_COPP_CTRL            equ     $01         ; (R /W) display synchronized coprocessor control
XR_AUD_CTRL             equ     $02         ; (- /-) TODO: audio channel control
XR_SCANLINE             equ     $03         ; (R /W) read scanline (incl. offscreen), write signal video interrupt
XR_VID_LEFT             equ     $04         ; (R /W) left edge of active display window (typically 0)
XR_VID_RIGHT            equ     $05         ; (R /W) right edge of active display window +1 (typically 640 or 848)
XR_POINTER_H            equ     $06         ; (- /W) pointer sprite raw H position
XR_POINTER_V            equ     $07         ; (- /W) pointer sprite raw V position / pointer color select
XR_UNUSED_08            equ     $08         ; (- /-) unused XR 08
XR_UNUSED_09            equ     $09         ; (- /-) unused XR 09
XR_UNUSED_0A            equ     $0A         ; (- /-) unused XR 0A
XR_UNUSED_0B            equ     $0B         ; (- /-) unused XR 0B
XR_UNUSED_0C            equ     $0C         ; (- /-) unused XR 0C
XR_UNUSED_0D            equ     $0D         ; (- /-) unused XR 0D
XR_UNUSED_0E            equ     $0E         ; (- /-) unused XR 0E
XR_UNUSED_0F            equ     $0F         ; (- /-) unused XR 0F
; Playfield A Control XR Registers
XR_PA_GFX_CTRL          equ     $10         ; (R /W ) playfield A graphics control
XR_PA_TILE_CTRL         equ     $11         ; (R /W ) playfield A tile control
XR_PA_DISP_ADDR         equ     $12         ; (R /W ) playfield A display VRAM start address
XR_PA_LINE_LEN          equ     $13         ; (R /W ) playfield A display line width in words
XR_PA_HV_FSCALE         equ     $14         ; (R /W ) playfield A horizontal and vertical fractional scale
XR_PA_H_SCROLL          equ     $15         ; (R /W ) playfield A horizontal and vertical fine scroll
XR_PA_V_SCROLL          equ     $16         ; (R /W ) playfield A horizontal and vertical fine scroll
XR_PA_LINE_ADDR         equ     $17         ; (- /W ) playfield A scanline start address (loaded at start of line)
; Playfield B Control XR Registers
XR_PB_GFX_CTRL          equ     $18         ; (R /W ) playfield B graphics control
XR_PB_TILE_CTRL         equ     $19         ; (R /W ) playfield B tile control
XR_PB_DISP_ADDR         equ     $1A         ; (R /W ) playfield B display VRAM start address
XR_PB_LINE_LEN          equ     $1B         ; (R /W ) playfield B display line width in words
XR_PB_HV_FSCALE         equ     $1C         ; (R /W ) playfield B horizontal and vertical fractional scale
XR_PB_H_SCROLL          equ     $1D         ; (R /W ) playfield B horizontal and vertical fine scroll
XR_PB_V_SCROLL          equ     $1E         ; (R /W ) playfield B horizontal and vertical fine scroll
XR_PB_LINE_ADDR         equ     $1F         ; (- /W ) playfield B scanline start address (loaded at start of line)
; Audio Registers
XR_AUD0_VOL             equ     $20         ; (- /W ) audio channel 0 8-bit L[15:8]+R[7:0] volume ($80 = 100%)
XR_AUD0_PERIOD          equ     $21         ; (- /W+) audio channel 0 15-bit period, bit [15] force restart
XR_AUD0_LENGTH          equ     $22         ; (- /W ) audio channel 0 15-bit sample word length-1, bit [15] tile mem
XR_AUD0_START           equ     $23         ; (- /W+) audio channel 0 sample start add (vram/tilemem), writes next pending
XR_AUD1_VOL             equ     $24         ; (- /W ) audio channel 1 8-bit L[15:8]+R[7:0] volume ($80 = 100%)
XR_AUD1_PERIOD          equ     $25         ; (- /W+) audio channel 1 15-bit period, bit [15] force restart
XR_AUD1_LENGTH          equ     $26         ; (- /W ) audio channel 1 15-bit sample word length-1, bit [15] tile mem
XR_AUD1_START           equ     $27         ; (- /W+) audio channel 1 sample start add (vram/tilemem), writes next pending
XR_AUD2_VOL             equ     $28         ; (- /W ) audio channel 2 8-bit L[15:8]+R[7:0] volume ($80 = 100%)
XR_AUD2_PERIOD          equ     $29         ; (- /W+) audio channel 2 15-bit period, bit [15] force restart
XR_AUD2_LENGTH          equ     $2A         ; (- /W ) audio channel 2 15-bit sample word length-1, bit [15] tile mem
XR_AUD2_START           equ     $2B         ; (- /W+) audio channel 2 sample start add (vram/tilemem), writes next pending
XR_AUD3_VOL             equ     $2C         ; (- /W ) audio channel 3 8-bit L[15:8]+R[7:0] volume ($80 = 100%)
XR_AUD3_PERIOD          equ     $2D         ; (- /W+) audio channel 3 15-bit period, bit [15] force restart
XR_AUD3_LENGTH          equ     $2E         ; (- /W ) audio channel 3 15-bit sample word length-1, bit [15] tile mem
XR_AUD3_START           equ     $2F         ; (- /W+) audio channel 3 sample start add (vram/tilemem), writes next pending
; (Registers $30-$3F reserved)
; Blitter Registers
XR_BLIT_CTRL            equ     $40         ; (- /W ) blit control ([15:8]=transp value, [5]=8 bpp, [4]=transp on, [0]=S constant)
XR_BLIT_ANDC            equ     $41         ; (- /W ) blit AND-COMPLEMENT constant value
XR_BLIT_XOR             equ     $42         ; (- /W ) blit XOR constant value
XR_BLIT_MOD_S           equ     $43         ; (- /W ) blit modulo added to S source after each line
XR_BLIT_SRC_S           equ     $44         ; (- /W ) blit S source VRAM read address / constant value
XR_BLIT_MOD_D           equ     $45         ; (- /W ) blit modulo added to D destination after each line
XR_BLIT_DST_D           equ     $46         ; (- /W ) blit D destination VRAM write address
XR_BLIT_SHIFT           equ     $47         ; (- /W ) blit first and last word nibble masks and nibble right shift (0-3)
XR_BLIT_LINES           equ     $48         ; (- /W ) blit number of lines minus 1, (repeats blit word count after modulo calc)
XR_BLIT_WORDS           equ     $49         ; (- /W+) blit word count minus 1 per line (write starts blit operation)
XR_UNUSED_4A            equ     $4A         ; (- /- ) unused XR reg
XR_UNUSED_4B            equ     $4B         ; (- /- ) unused XR reg
XR_UNUSED_4C            equ     $4C         ; (- /- ) unused XR reg
XR_UNUSED_4D            equ     $4D         ; (- /- ) unused XR reg
XR_UNUSED_4E            equ     $4E         ; (- /- ) unused XR reg
XR_UNUSED_4F            equ     $4F         ; (- /- ) unused XR reg

; Xosera register bits and constants

; SYS_CTRL bit definitions (NOTE: in high/even byte, use xm_getbh(SYS_CTRL) to check)
SYS_CTRL_MEM_WAIT_B     equ     7           ; (R /- ) memory read/write operation pending (with contended memory)
SYS_CTRL_MEM_WAIT_W     equ     1           ; (R /- ) memory read/write operation pending (with contended memory)
SYS_CTRL_MEM_WAIT_F     equ     $80         ; (R /- ) memory read/write operation pending (with contended memory)
SYS_CTRL_BLIT_FULL_B    equ     6           ; (R /- ) blitter queue is full, do not write to blitter registers
SYS_CTRL_BLIT_FULL_W    equ     1           ; (R /- ) blitter queue is full, do not write to blitter registers
SYS_CTRL_BLIT_FULL_F    equ     $40         ; (R /- ) blitter queue is full (do not write to blitter registers)
SYS_CTRL_BLIT_BUSY_B    equ     5           ; (R /- ) blitter is still busy performing an operation (not done)
SYS_CTRL_BLIT_BUSY_W    equ     1           ; (R /- ) blitter is still busy performing an operation (not done)
SYS_CTRL_BLIT_BUSY_F    equ     $20         ; (R /- ) blitter is still busy performing an operation (not done)
SYS_CTRL_UNUSED_12_B    equ     4           ; (R /- ) unused (reads 0)
SYS_CTRL_UNUSED_12_W    equ     1           ; (R /- ) unused (reads 0)
SYS_CTRL_UNUSED_12_F    equ     $10         ; (R /- ) unused (reads 0)
SYS_CTRL_HBLANK_B       equ     3           ; (R /- ) video signal is in horizontal blank period
SYS_CTRL_HBLANK_W       equ     1           ; (R /- ) video signal is in horizontal blank period
SYS_CTRL_HBLANK_F       equ     $08         ; (R /- ) video signal is in horizontal blank period
SYS_CTRL_VBLANK_B       equ     2           ; (R /- ) video signal is in vertical blank period
SYS_CTRL_VBLANK_W       equ     1           ; (R /- ) video signal is in vertical blank period
SYS_CTRL_VBLANK_F       equ     $04         ; (R /- ) video signal is in vertical blank period
SYS_CTRL_PIX_NO_MASK_B  equ     1           ; (R /W ) PIXEL_X/Y won't set WR_MASK (low two bits of PIXEL_X ignored)
SYS_CTRL_PIX_NO_MASK_W  equ     1           ; (R /W ) PIXEL_X/Y won't set WR_MASK (low two bits of PIXEL_X ignored)
SYS_CTRL_PIX_NO_MASK_F  equ     $02         ; (R /W ) PIXEL_X/Y won't set WR_MASK (low two bits of PIXEL_X ignored)
SYS_CTRL_PIX_8B_MASK_B  equ     0           ; (R /W ) PIXEL_X/Y 8-bit pixel mask for WR_MASK
SYS_CTRL_PIX_8B_MASK_W  equ     1           ; (R /W ) PIXEL_X/Y 8-bit pixel mask for WR_MASK
SYS_CTRL_PIX_8B_MASK_F  equ     $01         ; (R /W ) PIXEL_X/Y 8-bit pixel mask for WR_MASK
; SYS_CTRL WR_MASK nibble mask (NOTE: in low/odd byte, can use xm_setbl(SYS_CTRL, mask) to set as other bits unused)
SYS_CTRL_WR_MASK_B      equ     0           ; (R /W ) WR_MASK nibble write enable for VRAM write from host CPU
SYS_CTRL_WR_MASK_W      equ     4           ; (R /W ) WR_MASK nibble write enable for VRAM write from host CPU
SYS_CTRL_WR_MASK_F      equ     $0F         ; (R /W ) WR_MASK nibble write enable for VRAM write from host CPU
; INT_CTRL bit definitions
INT_CTRL_RECONFIG_B     equ     15          ; reconfigure FPGA to config # in bits [9:8] of INT_CTRL
INT_CTRL_RECONFIG_W     equ     1           ; reconfigure FPGA to config # in bits [9:8] of INT_CTRL
INT_CTRL_RECONFIG_F     equ     $8000       ; reconfigure FPGA to config # in bits [9:8] of INT_CTRL
INT_CTRL_BLIT_EN_B      equ     14          ; blitter ready interrupt mask
INT_CTRL_BLIT_EN_W      equ     1           ; blitter ready interrupt mask
INT_CTRL_BLIT_EN_F      equ     $4000       ; blitter ready interrupt enable
INT_CTRL_TIMER_EN_B     equ     13          ; timer match interrupt mask
INT_CTRL_TIMER_EN_W     equ     1           ; timer match interrupt mask
INT_CTRL_TIMER_EN_F     equ     $2000       ; timer match interrupt enable
INT_CTRL_VIDEO_EN_B     equ     12          ; v-blank or copper interrupt mask
INT_CTRL_VIDEO_EN_W     equ     1           ; v-blank or copper interrupt mask
INT_CTRL_VIDEO_EN_F     equ     $1000       ; v-blank or copper interrupt enable
INT_CTRL_AUD3_EN_B      equ     11          ; audio channel 3 ready (START addr was loaded)
INT_CTRL_AUD3_EN_W      equ     1           ; audio channel 3 ready (START addr was loaded)
INT_CTRL_AUD3_EN_F      equ     $0800       ; audio channel 3 interrupt enable
INT_CTRL_AUD2_EN_B      equ     10          ; audio channel 2 ready (START addr was loaded)
INT_CTRL_AUD2_EN_W      equ     1           ; audio channel 2 ready (START addr was loaded)
INT_CTRL_AUD2_EN_F      equ     $0400       ; audio channel 2 interrupt enable
INT_CTRL_AUD1_EN_B      equ     9           ; audio channel 1 ready (START addr was loaded)
INT_CTRL_AUD1_EN_W      equ     1           ; audio channel 1 ready (START addr was loaded)
INT_CTRL_AUD1_EN_F      equ     $0200       ; audio channel 1 interrupt enable
INT_CTRL_AUD0_EN_B      equ     8           ; audio channel 0 ready (START addr was loaded)
INT_CTRL_AUD0_EN_W      equ     1           ; audio channel 0 ready (START addr was loaded)
INT_CTRL_AUD0_EN_F      equ     $0100       ; audio channel 0 interrupt enable
INT_CTRL_AUD_EN_ALL_F   equ     $0F00       ; all audio channels interrupt enable
INT_CTRL_UNUSED_7_B     equ     7           ; timer match read interrupt (status, write acknowledge)
INT_CTRL_UNUSED_7_W     equ     1           ; timer match read interrupt (status, write acknowledge)
INT_CTRL_UNUSED_7_F     equ     $0080       ; timer match read interrupt (status, write acknowledge)
INT_CTRL_BLIT_INTR_B    equ     6           ; blitter ready interrupt (read status, write acknowledge)
INT_CTRL_BLIT_INTR_W    equ     1           ; blitter ready interrupt (read status, write acknowledge)
INT_CTRL_BLIT_INTR_F    equ     $0040       ; blitter ready interrupt (read status, write acknowledge)
INT_CTRL_TIMER_INTR_B   equ     5           ; timer match read interrupt (status, write acknowledge)
INT_CTRL_TIMER_INTR_W   equ     1           ; timer match read interrupt (status, write acknowledge)
INT_CTRL_TIMER_INTR_F   equ     $0020       ; timer match read interrupt (status, write acknowledge)
INT_CTRL_VIDEO_INTR_B   equ     4           ; v-blank or copper interrupt (read status, write acknowledge)
INT_CTRL_VIDEO_INTR_F   equ     $0010       ; v-blank or copper interrupt (read status, write acknowledge)
INT_CTRL_VIDEO_INTR_W   equ     1           ; v-blank or copper interrupt (read status, write acknowledge)
INT_CTRL_AUD3_INTR_B    equ     3           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD3_INTR_W    equ     1           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD3_INTR_F    equ     $0008       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD2_INTR_B    equ     2           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD2_INTR_W    equ     1           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD2_INTR_F    equ     $0004       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD1_INTR_B    equ     1           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD1_INTR_W    equ     1           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD1_INTR_F    equ     $0002       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD0_INTR_B    equ     0           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD0_INTR_W    equ     1           ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD0_INTR_F    equ     $0001       ; audio channel ready interrupt (read status, write acknowledge)
INT_CTRL_AUD_ALL_F      equ     $000F       ; all audio channels clear/acknowledge
INT_CTRL_CLEAR_ALL_F    equ     $007F       ; clear all interrupts
; UART status bit definitions (NOTE: high/even byte of XM_UART)
UART_RXF_B              equ     7           ; UART receive buffer full (data waiting)
UART_RXF_W              equ     1           ; UART receive buffer full (data waiting)
UART_RXF_F              equ     $80         ; UART receive buffer full (data waiting)
UART_TXF_B              equ     6           ; UART transmit buffer full (busy transmitting data)
UART_TXF_W              equ     1           ; UART transmit buffer full (busy transmitting data)
UART_TXF_F              equ     $40         ; UART transmit buffer full (busy transmitting data)
; FEATURE bit definitions
FEATURE_MONRES_B        equ     0           ; rightmost bit number for 4-bit monitor mode field
FEATURE_MONRES_W        equ     4           ; bit width for 4-bit monitor mode field
FEATURE_MONRES_F        equ     $000F       ; bit-mask for 4-bit monitor mode field
FEATURE_COPP_B          equ     4           ; bit number indicating presence of COPPER
FEATURE_COPP_W          equ     1           ; bit flag indicating presence of COPPER
FEATURE_COPP_F          equ     $0010       ; bit flag indicating presence of COPPER
FEATURE_BLIT_B          equ     5           ; bit number indicating presence of BLITTER
FEATURE_BLIT_W          equ     1           ; bit number indicating presence of BLITTER
FEATURE_BLIT_F          equ     $0020       ; bit flag indicating presence of BLITTER
FEATURE_PF_B_B          equ     6           ; bit number indicating presence of playfield B (2nd playfield)
FEATURE_PF_B_W          equ     1           ; bit number indicating presence of playfield B (2nd playfield)
FEATURE_PF_B_F          equ     $0040       ; bit flag indicating presence of playfield B (2nd playfield)
FEATURE_UART_B          equ     7           ; bit number indicating presence of debug UART
FEATURE_UART_W          equ     1           ; bit number indicating presence of debug UART
FEATURE_UART_F          equ     $0080       ; bit flag indicating presence of debug UART
FEATURE_AUDCHAN_B       equ     8           ; rightmost bit number for 4-bit audio channels field
FEATURE_AUDCHAN_W       equ     4           ; bit width for 4-bit audio channels field
FEATURE_AUDCHAN_F       equ     $0F00       ; bit-mask for 4-bit audio channels field
FEATURE_CONFIG_B        equ     12          ; rightmost bit number for 4-bit FPGA config field
FEATURE_CONFIG_W        equ     4           ; bit width for 4-bit FPGA config field
FEATURE_CONFIG_F        equ     $F000       ; bit-mask for 4-bit config field
; XR_VID_CTRL bit definitions
VID_CTRL_SWAP_AB_B      equ     15          ; flag to swap colormap used (pf A uses colormap B and vice versa)
VID_CTRL_SWAP_AB_W      equ     1           ; 1 bit
VID_CTRL_SWAP_AB_F      equ     $8000       ; flag to swap colormap used (pf A uses colormap B and vice versa)
VID_CTRL_BORDCOL_B      equ     0           ; mask for pf A color index
VID_CTRL_BORDCOL_W      equ     8           ; 8 bit field
VID_CTRL_BORDCOL_F      equ     $00FF       ; mask for pf A color index
; XR_COPP_CTRL bit definitions
COPP_CTRL_COPP_EN_B     equ     15          ; bit number to enable/disable copper
COPP_CTRL_COPP_EN_W     equ     1           ; 1 bit
COPP_CTRL_COPP_EN_F     equ     $8000       ; flag to enable/disable copper
; XR_AUD_CTRL bit definitions
AUD_CTRL_AUD_EN_B       equ     0           ; bit number to enable/disable audio
AUD_CTRL_AUD_EN_W       equ     1           ; 1 bit
AUD_CTRL_AUD_EN_F       equ     $0001       ; flag to enable/disable audio
; XR_POINTER_H/XR_POINTER_V
POINTER_H_OFFSET        equ     6           ; native pixel "head-start" subtracted from raw H pos
POINTER_H_B             equ     0           ; pointer sprite raw H position
POINTER_H_W             equ     12          ; pointer sprite raw H position
POINTER_H_F             equ     $0FFF       ; pointer sprite raw H position
POINTER_V_COLORSEL_B    equ     12          ; pointer sprite upper 4-bit for color index
POINTER_V_COLORSEL_W    equ     4           ; pointer sprite upper 4-bit for color index
POINTER_V_COLORSEL_F    equ     $F000       ; pointer sprite upper 4-bit for color index
POINTER_V_B             equ     0           ; pointer raw V position
POINTER_V_W             equ     12          ; pointer raw V position
POINTER_V_F             equ     $0FFF       ; pointer raw V position
; XR_Px_GFX_CTRL constants
GFX_1_BPP               equ     0           ; 1-bpp (2 colors + selected via fore/back color attribute byte)
GFX_4_BPP               equ     1           ; 4-bpp (16 colors)
GFX_8_BPP               equ     2           ; 8-bpp (256 colors)
GFX_X_BPP               equ     3           ; (reserved)
GFX_1X                  equ     0           ; H/V repeat x1
GFX_2X                  equ     1           ; H/V repeat x2
GFX_3X                  equ     2           ; H/V repeat x3
GFX_4X                  equ     3           ; H/V repeat x4
; XR_Px_HV_FSCALE constants    16:9   4:3
HV_FSCALE_OFF           equ     $0          ; H 848 / 640,  V 480
HV_FSCALE_1OF2          equ     $1          ; H 424 / 320,  V 240
HV_FSCALE_1OF3          equ     $2          ; H 565+/ 426+, V 320
HV_FSCALE_1OF4          equ     $3          ; H 636 / 480,  V 360
HV_FSCALE_1OF5          equ     $4          ; H 678+/ 512,  V 384
HV_FSCALE_1OF6          equ     $5          ; H 706+/ 533+, V 400
HV_FSCALE_1OF7          equ     $6          ; H 726+/ 548+, V 411+
HV_FSCALE_1OF8          equ     $7          ; H 742 / 560,  V 420
; XR_Px_GFX_CTRL bit definitions
GFX_CTRL_V_REPEAT_B     equ     0
GFX_CTRL_V_REPEAT_W     equ     2
GFX_CTRL_V_REPEAT_F     equ     $0003
GFX_CTRL_H_REPEAT_B     equ     2
GFX_CTRL_H_REPEAT_W     equ     2
GFX_CTRL_H_REPEAT_F     equ     $000C
GFX_CTRL_BPP_B          equ     4
GFX_CTRL_BPP_W          equ     2
GFX_CTRL_BPP_F          equ     $0030
GFX_CTRL_BITMAP_B       equ     6
GFX_CTRL_BITMAP_W       equ     1
GFX_CTRL_BITMAP_F       equ     $0040
GFX_CTRL_BLANK_B        equ     7
GFX_CTRL_BLANK_W        equ     1
GFX_CTRL_BLANK_F        equ     $0080
GFX_CTRL_COLORBASE_B    equ     8
GFX_CTRL_COLORBASE_W    equ     8
GFX_CTRL_COLORBASE_F    equ     $FF00
; XR_Px_TILE_CTRL bit definitions
TILE_CTRL_TILE_H_B      equ     0
TILE_CTRL_TILE_H_W      equ     4
TILE_CTRL_TILE_H_F      equ     $000F
TILE_CTRL_TILE_VRAM_B   equ     8
TILE_CTRL_TILE_VRAM_W   equ     1
TILE_CTRL_TILE_VRAM_F   equ     $0100
TILE_CTRL_DISP_TILEMEM_B equ    9
TILE_CTRL_DISP_TILEMEM_W equ    1
TILE_CTRL_DISP_TILEMEM_F equ    $0200
TILE_CTRL_TILEBASE_B    equ     10
TILE_CTRL_TILEBASE_W    equ     6
TILE_CTRL_TILEBASE_F    equ     $FC00
; XR_Px_H_SCROLL bit definitions
H_SCROLL_FINE_B         equ     0
H_SCROLL_FINE_W         equ     5
H_SCROLL_FINE_F         equ     $001F
; XR_Px_V_SCROLL bit definitions
V_SCROLL_FINE_B         equ     8
V_SCROLL_FINE_W         equ     2
V_SCROLL_FINE_F         equ     $0300
V_SCROLL_TILE_B         equ     0
V_SCROLL_TILE_W         equ     4
V_SCROLL_TILE_F         equ     $000F
; XR_Px_HV_FSCALE bit definitions
HV_FSCALE_H_FRAC_B      equ     8
HV_FSCALE_H_FRAC_W      equ     3
HV_FSCALE_H_FRAC_F      equ     $0700
HV_FSCALE_V_FRAC_B      equ     0
HV_FSCALE_V_FRAC_W      equ     3
HV_FSCALE_V_FRAC_F      equ     $0700
; XR_AUDx_VOL bit definitions
AUD_VOL_LEFT_B          equ     8
AUD_VOL_LEFT_W          equ     8
AUD_VOL_LEFT_F          equ     $FF00
AUD_VOL_RIGHT_B         equ     0
AUD_VOL_RIGHT_W         equ     8
AUD_VOL_RIGHT_F         equ     $00FF
; XR_AUDx_VOL constants
AUD_VOL_FULL            equ     $80        ; AUDx_VOL left/right 100% volume level (0% attenuation)
; XR_AUDx_PERIOD bit definitions
AUD_PERIOD_RESTART_B    equ     15          ; AUDx_PERIOD bit 15 is force channel restart
AUD_PERIOD_RESTART_W    equ     1
AUD_PERIOD_RESTART_F    equ     $8000
AUD_PERIOD_B            equ     0
AUD_PERIOD_W            equ     15
AUD_PERIOD_F            equ     $7FFF
; XR_AUDx_LENGTH bit definitions
AUD_LENGTH_TILEMEM_B    equ     15          ; AUDx_LENGTH bit 15 is TILEMEM flag
AUD_LENGTH_TILEMEM_W    equ     1
AUD_LENGTH_TILEMEM_F    equ     $8000
AUD_LENGTH_B            equ     0
AUD_LENGTH_W            equ     15
AUD_LENGTH_F            equ     $7FFF
; XR_BLIT_CTRL bit definitions
BLIT_CTRL_TRANSPVAL_B   equ     8
BLIT_CTRL_TRANSPVAL_W   equ     8
BLIT_CTRL_TRANSPVAL_G   equ     $FF00
BLIT_CTRL_8B_B          equ     5
BLIT_CTRL_8B_W          equ     1
BLIT_CTRL_8B_F          equ     $0020
BLIT_CTRL_TRANSP_B      equ     4
BLIT_CTRL_TRANSP_W      equ     1
BLIT_CTRL_TRANSP_F      equ     $0010
BLIT_CTRL_SCONST_B      equ     0
BLIT_CTRL_SCONST_W      equ     1
BLIT_CTRL_SCONST_F      equ     $0001
; XR_BLIT_SHIFT bit definitions
BLIT_SHIFT_LMSK_B       equ     12
BLIT_SHIFT_LMSK_W       equ     4
BLIT_SHIFT_LMSK_G       equ     $F000
BLIT_SHIFT_RMSK_B       equ     8
BLIT_SHIFT_RMSK_W       equ     4
BLIT_SHIFT_RMSK_G       equ     $0F00
BLIT_SHIFT_CNT_B        equ     0
BLIT_SHIFT_CNT_W        equ     2
BLIT_SHIFT_CNT_F        equ     $0003

; Video mode 640x480 constants (4:3 aspect ratio)
MODE_640x480_H           equ     640                                     ; visible width
MODE_640x480_V           equ     480                                     ; visible height
MODE_640x480_TOTAL_H     equ     800                                     ; total hpos width
MODE_640x480_TOTAL_V     equ     525                                     ; total vpos height
MODE_640x480_LEFTEDGE    equ     MODE_640x480_TOTAL_H-MODE_640x480_H       ; offscreen hpos pixels
AUDIO_PERIOD_HZ_640     equ     25125000                                ; sample main clock in 640x480 video mode
; Video mode 848x480 constants (16:9 aspect ratio)
MODE_848x480_H          equ     848                                     ; visible width
MODE_848x480_V          equ     480                                     ; visible height
MODE_848x480_TOTAL_H    equ     1088                                    ; total hpos width
MODE_848x480_TOTAL_V    equ     517                                     ; total vpos height
MODE_848x480_LEFTEDGE   equ     MODE_848x480_TOTAL_H-MODE_848x480_H     ; offscreen hpos pixels
AUDIO_PERIOD_HZ_848     equ     33750000                                ; sample main clock in 848x480 video mode

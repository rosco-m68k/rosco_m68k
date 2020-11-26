    section .text
;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|       V9958 Video
;------------------------------------------------------------
; Copyright (c)2020 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; V9958 80x24 TEXT2 console.
;
; This console supports the following features:
;
;   * 80x24 lines
;   * Scrolling (Software, but fairly efficient)
;   * Support for CR and Backspace
;   * Flashing cursor, alternates between any two characters
;
; The following is still TODO (coming soon):
;
;   * Clear screen ability
;   * Programmatically move the cursor
;
;------------------------------------------------------------
;
    include "../equates.S"

; Options - Change these to suit your tastes...
DISPMODE          equ   DM_NTSC           ; DM_PAL or DM_NTSC
CURSORHIGH        equ   152               ; "little" cursor character
CURSORLOW         equ   145               ; "big" cursor character
CURSORDELAY       equ   50                ; Blink delay, Lower is faster

BACKGROUND1       equ   %00100111         ; BG: 0 R2 R1 R0 0 B2 B1 B0
BACKGROUND2       equ   %00000010         ; BG: 0 0  0  0  0 G2 G1 G0
FOREGROUND1       equ   %01000111         ; FG: 0 R2 R1 R0 0 B2 B1 B0
FOREGROUND2       equ   %00000100         ; FG: 0 0  0  0  0 G2 G1 G0

; Addresses and other constants, don't change unless you know what
; you're doing...
PORT_RWDATA       equ   $F80000
PORT_WREG_SETUP   equ   $2
PORT_WPALETTE     equ   $4
PORT_WREG_DATA    equ   $6
IRQ2_HANDLER      equ   $68
BSET              equ   $08f9
BCLR              equ   $08b9
NOP               equ   $4E71

LINELENGTH        equ   80                ; Must be a multiple of 4!
DWLINELENGTH      equ   LINELENGTH/4
LINECOUNT         equ   24
DISPLAYSIZE       equ   LINELENGTH*LINECOUNT
DWDISPLAYSIZE     equ   DISPLAYSIZE/4
CURSORDELAY2      equ   CURSORDELAY*2

DM_PAL            equ   2
DM_NTSC           equ   0

; Constants for addressing video RAM
VDP_REG2_PAGE0    equ   $3           ; Page 0 at 0x0
VDP_REG2_PAGE1    equ   $B           ; Page 1 at 0x2000

VRAM_HIGH         equ   $0           ; VRAM A14-16 for any page
VRAM_LOW          equ   $0           ; VRAM A0-A7 for any page (base)

VRAM_MID_PAGE0_R  equ   $0           ; VRAM A8-A13 for page 0 (Read)
VRAM_MID_PAGE0_W  equ   $40          ; VRAM A8-A13 for page 0 (Write)
VRAM_MID_PAGE1_R  equ   $20          ; VRAM A8-A13 for page 1 (Read)
VRAM_MID_PAGE1_W  equ   $60          ; VRAM A8-A13 for page 1 (Write)

; Determine if there's a V9958 installed.
;
; Arguments:
;   None
;   
; Modifies:
;   D0.B    Return (1 - installed, 0 - not installed)
;
HAVE_V9958::
    movem.l D1/A0-A1,-(A7)
    move.l  #PORT_RWDATA,A0           ; Use A0 as port base register

    ; Install temp bus error handler in case card not installed
    move.l  $8,$500
    move.l  #BERR_HANDLER,$8

    ; Zero Bus Error flag
    move.b  #0,$504

    move.b  #1,(PORT_WREG_SETUP,A0)   ; Write 1 (SR#1)...\

    tst.b   $504                      ; Was there a bus error?
    bne.s   .NO_9958                  ; Bail now if so...
   
    move.b  #$8F,(PORT_WREG_SETUP,A0) ; ... to register 15 (with high bit set)
    eor.l   D1,D1                     ; Zero D1
    move.b  (PORT_WREG_SETUP,A0),D1   ; And read status into it
    and.b   #$3E,D1                   ; We only want ID number
    ror.b   #1,D1                     ; Shift right by 1 (for correct display)

    cmp.b   #2,D1                     ; V9958 has ID 2
    beq.s   .IS_9958

.NO_9958:
    moveq   #0,D1                     ; Stash negative result in D1 for a sec...
    lea.l   SZNOID,A1                 ; Print "not 9958"
    bra.s   .DISPLAY_MESSAGE

.IS_9958:    
    moveq   #1,D1                     ; Stash positive result
    lea.l   SZID,A1                   ; Print "have 9958"

.DISPLAY_MESSAGE:
    move.l  #14,D0                    ; Print the message
    trap    #15

    move.l  $500,$8                   ; Restore bus error handler

    move.b  D1,D0                     ; Result in D0.B
    movem.l (A7)+,D1/A0-A1
    rts


; Initialize the console
V9958_CON_INIT::
    movem.l D0-D1/A0-A1,-(A7)
    move.l  #PORT_RWDATA,A0                   ; Use A0 as port base register

    ori.w   #$0200,SR                         ; No interrupts during init...

    ; Clear console data area (Comment this out if not in ROM)
.CLEARDATA:
    move.l  #CURPOS,A1
    move.w  #$1E2,D1
    bra.s   .CLEARSTART
.CLEARLOOP
    move.l  #0,(A1)+
.CLEARSTART
    dbra.w	D1,.CLEARLOOP

    move.l  #VBLANK_HANDLER,IRQ2_HANDLER      ; Install ISR

    ; Setup Palette
    move.b  #%00000000,(PORT_WREG_SETUP,A0)   ; Start at palette register 0
    move.b  #$90,(PORT_WREG_SETUP,A0)         ; .. in VDP register 16
    move.b  #BACKGROUND1,(PORT_WPALETTE,A0)   ; 0 R2 R1 R0 0 B2 B1 B0 
    move.b  #BACKGROUND2,(PORT_WPALETTE,A0)   ; 0 0  0  0  0 G2 G1 G0
    move.b  #FOREGROUND1,(PORT_WPALETTE,A0)   ; 0 R2 R1 R0 0 B2 B1 B0 
    move.b  #FOREGROUND2,(PORT_WPALETTE,A0)   ; 0 0  0  0  0 G2 G1 G0
    
    move.b  #%00010000,(PORT_WREG_SETUP,A0)   ; Select FG1, BG 0
    move.b  #$87,(PORT_WREG_SETUP,A0)         ; .. In VDP register 7

    move.b  #%00001010,(PORT_WREG_SETUP,A0)   ; Select 64K DRAM, disable sprites
    move.b  #$88,(PORT_WREG_SETUP,A0)         ; .. In VDP register 8
    
    ; Set pattern generator table to 0x1000
    move.b  #2,(PORT_WREG_SETUP,A0)           ; bits 16-11 of 0x1000
    move.b  #$84,(PORT_WREG_SETUP,A0)         ; .. to register 4

    ; Set pattern layout table to page 0
    move.b  #VDP_REG2_PAGE0,(PORT_WREG_SETUP,A0)
    move.b  #$82,(PORT_WREG_SETUP,A0)         ; .. to register 2

    ; Set PAL/NTSC mode (TODO should be runtime configurable...)
    move.b  #DISPMODE,(PORT_WREG_SETUP,A0)    ; Write PAL/NTSC mode
    move.b  #$89,(PORT_WREG_SETUP,A0)         ; .. to register 9
    
    ; Set up to write VRAM at 0x1000
    ; 0x1000 equates to 00001000000000000, which is split across the writes as:
    ; Write 1: bits 16-14 = (00000)000  = 0
    ; Write 2: bits 7-0   = 00000000    = 0
    ; Write 3: bits 13-8  = (01)010000  = $50 ($40 is write-enable)
    move.b  #0,(PORT_WREG_SETUP,A0)           ; VRAM Base at 0
    move.b  #$8E,(PORT_WREG_SETUP,A0)         ; > register 14
    move.b  #0,(PORT_WREG_SETUP,A0)           ; Set VRAM A0-A7
    move.b  #$50,(PORT_WREG_SETUP,A0)         ; Set VRAM A8-A13, and write enable

    ; Load font to pattern table 
    lea     __FONT_BEGIN,A1
    move.l  #__FONT_END,D0
    sub.l   A1,D0
    bra.s   .PATTERN_FILL

.PATTERN_FILL_LOOP
    move.b  (A1)+,(A0)                        ; Copy data
    nop                                       ; Small slow-down needed here..
    nop
    nop
    nop
    nop
    nop
    nop
.PATTERN_FILL:
    dbra.w  D0,.PATTERN_FILL_LOOP
   
    ; Clear the main memory buffer and copy to the VRAM 
    bsr.s   CLEARBUFFER
    lea     BUFFER,A1
    clr.b   D0
    bsr.w   BUFFERFLIP

    ; Set text mode 1, enable interrupts and turn display on
    move.b  #%00000100,(PORT_WREG_SETUP,A0)   ; Write DG=0,IE2=0,IE1=0,M5=0,M4=0,M3=0
    move.b  #$80,(PORT_WREG_SETUP,A0)         ; To register 0

    move.b  #%01110000,(PORT_WREG_SETUP,A0)   ; Write BL=1,IE0=1,M1=1,M2=0,SI=0,MAG=0
    move.b  #$81,(PORT_WREG_SETUP,A0)         ; To register 1

    andi.w   #~$0200,SR                       ; Enable interrupts...

    move.l  #SZHEADER,A1
.PRINTLOOP
    move.b  (A1)+,D0
    beq.s   .PRINTDONE
     
    bsr.w   V9958_CON_PUTCHAR
    bra.s   .PRINTLOOP
.PRINTDONE

    movem.l (A7)+,D0-D1/A0-A1
    rts


; Clear buffer (private)
;
; Modifies: D1, A1
CLEARBUFFER:
    move.w  #DWDISPLAYSIZE,D1             ; Display size in longwords
    move.l  #BUFFER,A1
    bra.s   .ZEROBUF_START
.ZEROBUF_LOOP:
    move.l  #0,(A1)+                      ; Clear 4 characters
.ZEROBUF_START:
    dbra.w  D1,.ZEROBUF_LOOP
    rts


; Clear the screen
;
; Arguments:
;   None
;
; Modifies: 
;   None
;
; This depends on the implementation of CLEARBUFFER (i.e. 
; the register sizing therein). If that func changes, 
; this needs to be updated!
;
; TODO Maybe there's a more efficient way to do this
; (rather than doing the whole copy/flip). Look into that.
V9958_CON_CLRSCR::
    move.w  D1,-(A7)
    move.l  A0,-(A7)
    ori.w   #$0200,SR                      ; Disable interrupts
    bsr.s   CLEARBUFFER                    ; Clear
    andi.w  #~$200,SR                      ; And re-enable...
    move.w  #0,CURPOS
    move.l  (A7)+,A0
    move.w  (A7)+,D1
    
    ; Now we've cleared, we need to copy the whole buffer and flip
    lea.l   BUFFER,A1
    move.b  CURRENTPAGE,D0
    not.b   D0
    bsr.w   BUFFERFLIP
    rts


V9958_CON_PRINT:
    move.l  D0,-(A7)

.PRINTLOOP
    move.b  (A0)+,D0
    beq.s   .PRINTDONE
     
    bsr.w   V9958_CON_PUTCHAR
    bra.s   .PRINTLOOP
.PRINTDONE

    move.l  (A7)+,D0
    rts

V9958_CON_PRINTLN:
    bsr.s   V9958_CON_PRINT                 ; Print callers message
    move.l  A0,-(A7)                        ; Stash A0 to restore later
    
    lea     SZ_CR,A0                        ; Load CR...
    bsr.s   V9958_CON_PRINT                 ; ... and print it
        
    move.l  (A7)+,A0                        ; Restore A0
    rts

V9958_CON_SETCURSOR:
    tst.b   D0
    beq.s   V9958_CON_HIDECURSOR
    bra.s   V9958_CON_SHOWCURSOR

V9958_CON_INSTALLHANDLERS::
    move.l  #V9958_CON_PRINT,EFP_PRINT
    move.l  #V9958_CON_PRINTLN,EFP_PRINTLN
    move.l  #V9958_CON_PUTCHAR,EFP_PRINTCHAR
    move.l  #V9958_CON_CLRSCR,EFP_CLRSCR
    move.l  #V9958_CON_SETCURSOR,EFP_SETCURSOR
    rts

; Show the cursor
;
; Arguments:
;   None
;
; Modifies:
;   Nothing
V9958_CON_SHOWCURSOR::
    move.b  #1,SHOWCURSOR
    rts


; Hide the cursor
;
; Arguments:
;   None
;
; Modifies:
;   Nothing
V9958_CON_HIDECURSOR::
    move.b  #0,SHOWCURSOR
    rts


; Internal sub to copy the main memory buffer to the current
; back-buffer page of VRAM. Used at init and on scroll.
;
; This also sets the visible page to be the destination
; page, for display at the next VBLANK.
;
; Arguments:
;   D0.B  Page to flip to (0 for 0, nonzero for 1)
;   A0    VDP Port Base  
;   A1    Main memory buffer
;
; Trashes:
;   Nothing
;
BUFFERFLIP:
    move.l  D1,-(A7)
    ori.w   #$0200,SR                         ; Cannot be interrupted for a bit...

    ; Set up to write VRAM at 0x0
    move.b  #VRAM_HIGH,(PORT_WREG_SETUP,A0)   ; VRAM Base at 0
    move.b  #$8E,(PORT_WREG_SETUP,A0)         ; > register 14
    move.b  #VRAM_LOW,(PORT_WREG_SETUP,A0)    ; Set VRAM A0-A7

    ; Set CURRENTPAGE to the destination page
    move.b  D0,CURRENTPAGE
    beq.s   .PAGEZERO

    ; Page 1
    move.b  #VRAM_MID_PAGE1_W,(PORT_WREG_SETUP,A0)
    bra.s   .GOGOGO

.PAGEZERO:
    move.b  #VRAM_MID_PAGE0_W,(PORT_WREG_SETUP,A0)
    
.GOGOGO    
    move.w  DISPLAYSTART,D0
    move.w  #DISPLAYSIZE,D1

    bra.s   .COPY
.COPYLOOP
    move.b  (A1,D0),(A0)                      ; Must slow down here.
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    addq.w  #1,D0
    cmpi.w  #DISPLAYSIZE,D0
    bne.s   .COPY

    moveq.l #0,D0
  
.COPY
    dbra.w  D1,.COPYLOOP  

    andi.w  #~$0200,SR                        ; Go for interrupts again...
    move.l  (A7)+,D1                          ; ... and we're done.  
    rts


; Internal - Translate the buffer position in D1.W into the relevant
; VRAM position based on the setting of CURRENTPAGE and the
; current display start (in D2.W) , and set up the VDP for a VRAM 
; write there.
;
; Interrupts should be disabled while this happens!
;
; Arguments:
;   A0      VDP Port base address
;   D1.W    Buffer position (CURPOS)
;   D2.W    Display start position (DISPLAYSTART)
;
; Modifies:
;   VDP Registers
;
SETUP_VRAM_WRITE:
    move.w  D3,-(A7)
 
    ; Write this character to the current VRAM page too
    move.w  D1,D3
    sub.w   D2,D3
    bge.s   .WRITEVRAM

    ; Negative, add display size
    addi.w  #DISPLAYSIZE,D3

.WRITEVRAM
    ; HIGH is 0
    ; LOW is D3.B
    ; MID is ((D3.W & 0x3F00) >> 8) | 0x40 for page zero
    ; MID is ((D3.W & 0x3F00) >> 8) | 0x60 for page one
    move.b  #0,(PORT_WREG_SETUP,A0)       ; High is zero
    move.b  #$8E,(PORT_WREG_SETUP,A0)     ; > register 14
    move.b  D3,(PORT_WREG_SETUP,A0)       ; Low is D2.B

    ; Calculate middle bits
    andi.w  #$3F00,D3                     ; Mask bits...
    lsr.w   #8,D3                         ; And shift...
    
    tst.b   CURRENTPAGE
    beq.s   .PAGEZERO
  
    ; We're in page 1
    ori.b   #$60,D3                       ; Set page and write bits
    bra.s   .DOIT

.PAGEZERO
    ori.b   #$40,D3                       ; Just set write bit
   
.DOIT 
    move.b  D3,(PORT_WREG_SETUP,A0)       ; Set VRAM A8-A13...
    move.w  (A7)+,D3
    rts


; Put a character to the screen
;
; Arguments:
;   D0.B  The character
;
; Modifies
;   D0.B  Possibly trashed
;
; Register alloc in function:
;   A1    Buffer
;   D1.W  CURPOS (buffer pointer)
;   D2.W  DISPLAYSTART (start pointer)
; 
V9958_CON_PUTCHAR::
    ; Ignoring linefeeds (for legacy compatibility)
    cmp.b   #10,D0
    bne.s   .NOTIGNORED
  
    rts

.NOTIGNORED
    movem.l D1-D2/A0-A1,-(A7)
    
    move.l  #PORT_RWDATA,A0               ; Use A0 as port base register
    move.w  CURPOS,D1                     ; Load current pointer
 
    ; Is this a carriage-return?
    cmp.b   #13,D0
    bne.s   .NOTCR

    ; Yes - handle CR
    clr.l   D2                            ; Find how far until start
    move.w  D1,D2                         ; of next line.
    divu.w  #LINELENGTH,D2                ; d1 = LINELENGTH - d1 % LINELENGTH                 
    swap    D2
    move.w  #LINELENGTH,D1
    sub.w   D2,D1

    move.b  #0,D0                         ; Recursively clear to EOL
    bra.s   .CLREOL                       ; (TODO Non-recursive would be faster...)
.CLREOL_LOOP
    bsr.s   V9958_CON_PUTCHAR
.CLREOL
    dbra.w  D1,.CLREOL_LOOP

    bra.w   .DONE
.NOTCR
    ; No, is it a backspace?
    cmp.b    #8,D0
    bne.s   .NOTBS

    ; Yes - handle backspace
    lea.l   BUFFER,A1                     ; Get buffer
    move.w  DISPLAYSTART,D2               ; Load start of display pointer
    cmp.w   D1,D2                         ; Are we at display start?
    beq.w   .DONE                         ; Yes - Ignore BS

    ori.w   #$0200,SR                     ; Disable interrupts for a sec
    subq.w  #1,D1                         ; Back a space

    bsr.w   SETUP_VRAM_WRITE              ; Clear from VRAM
    move.b  #0,(A0)                       ; Overwrite character
    nop                                   ;   but not too fast!
    nop  
    nop  
    nop  
    nop
    nop
    nop
    move.b  #0,(A0)                       ; Overwrite possible cursors
    nop  
    nop  
    nop  
    nop  
    nop
    nop
    nop
    move.b  #0,(A0)                       ; This can go one byte out-of-bounds in
    nop                                   ; VRAM, but the display doesn't extend
    nop                                   ; for the whole page anyway...
    nop  
    nop  
    nop
    nop
    nop

    andi.w  #~$0200,SR                    ; Go ahead with the interrupts...
    move.b  #0,(A1,D1)                    ; Clear from buffer
    move.w  D1,CURPOS                     ; Store new position

    andi.w  #~$0200,SR
    bra.w   .DONE

.NOTBS
    ; No - Just print
    lea.l   BUFFER,A1                     ; Get buffer
    move.w  DISPLAYSTART,D2               ; And current DISPLAYSTART
    
    move.b  D0,(A1,D1)                    ; Buffer this character

.WRITEVRAM
    ori.w   #$0200,SR                     ; No interrupts for a sec...
    bsr.w   SETUP_VRAM_WRITE              ; Setup to write to correct position for D2
    move.b  D0,(A0)                       ; And write,
    nop                                   ;   but not too fast!
    nop  
    andi.w  #~$0200,SR                    ; Go ahead with the interrupts...
    
    addq.w  #1,D1

    cmp.w   #DISPLAYSIZE,D1               ; Are we at end of buffer?
    bne.s   .CHECKSCROLL                  ; Nope, go to check scroll

    move.w  #0,D1                         ; Yep, reset pointer

.CHECKSCROLL
    move.w  D1,CURPOS                     ; Store new pointer
    
    cmp.w   D2,D1                         ; Wrapped back to start of display?
    bne.s   .DONE                         ; Nope, we're done

    ; Let's do some scrolling...
    addi.w  #LINELENGTH,D2                ; Scroll...
    cmp.w   #DISPLAYSIZE,D2               ; Reached end of the buffer?
    bne.s   .STORESTART                   ; Nope - on we go...

    move.w  #0,D2                         ; Yes - wrap around

.STORESTART
    move.w  D2,DISPLAYSTART               ; Save new start so we can reuse D2

    ; Clear the line...
    adda.l  D1,A1                         ; Point to start of line
    move.w  #DWLINELENGTH,D2              ; Counter is line length
    bra.s   .CLEARLINE
.CLEARLINE_LOOP
    move.l  #0,(A1)+                      ; Clear four characters
.CLEARLINE
    dbra.w  D2,.CLEARLINE_LOOP

    ; Now we've scrolled, we need to copy the whole buffer and flip
    lea.l   BUFFER,A1
    move.b  CURRENTPAGE,D0
    not.b   D0
    bsr.w   BUFFERFLIP

.DONE
    movem.l (A7)+,D1-D2/A0-A1
    rts


; Vertical blanking interval ISR
;
; Not using local labels here as some of this code is modified
; by other routines, so labels are used to address those bits
; that need to be visible externally...
;
VBLANK_HANDLER::
    movem.l  D0-D2/A0,-(A7)
    move.l  #PORT_RWDATA,A0               ; Use A0 as port base register

    move.b  SHOWCURSOR,D0                 ; Skip cursor if not displayed
    beq.s   .SETPAGE

    ; Sort out the cursor first...
    move.b  CURSORCOUNT,D0
    addq.b  #1,D0
    cmpi.b  #CURSORDELAY,D0
    bne.s   .CHECKSHOW

    move.w  CURPOS,D1                     ; Time to show the low cursor!
    move.w  DISPLAYSTART,D2
    bsr.w   SETUP_VRAM_WRITE
    move.b  #CURSORLOW,(A0)
    nop
    nop
    nop
    nop

    bra.s   .CURSORDONE 

.CHECKSHOW
    cmpi.b  #CURSORDELAY2,D0
    bne.s   .CURSORDONE
    
    move.w  CURPOS,D1                     ; Time to show the high cursor!
    move.w  DISPLAYSTART,D2
    bsr.w   SETUP_VRAM_WRITE
    move.b  #CURSORHIGH,(A0)
    nop
    nop
    nop
    nop

    move.b  #0,D0

.CURSORDONE:
    move.b  D0,CURSORCOUNT
 
.SETPAGE
    ; Set pattern layout table to current page
    tst.b   CURRENTPAGE
    beq.s   .PAGEZERO

    ; Is page one
    move.b  #VDP_REG2_PAGE1,(PORT_WREG_SETUP,A0)
    move.b  #$82,(PORT_WREG_SETUP,A0)     ; .. to register 2

    bra.s   .DONE

.PAGEZERO
    ; Is page zero
    move.b  #VDP_REG2_PAGE0,(PORT_WREG_SETUP,A0)
    move.b  #$82,(PORT_WREG_SETUP,A0)     ; .. to register 2
  
.DONE 
    ; Ack interrupt
    move.b  #0,(PORT_WREG_SETUP,A0)       ; Write 0 (SR#0)...
    move.b  #143,(PORT_WREG_SETUP,A0)     ; ... to register 15 (with high bit set)
    move.b  (PORT_WREG_SETUP,A0),D0       ; And read status into it (clear interrupt flag)
    nop
    nop
    nop
    
    movem.l (A7)+,D0-D2/A0
    rte

; TODO this should be in .bss but for some reason that screws up Kermits
; .bss load address and bloats the binary, figure out why...
;CURPOS        dc.w      0
;DISPLAYSTART  dc.w      0
;BUFFER        dcb.b     1920,0
;CURSORCOUNT   dc.w      0
;CURRENTPAGE   dc.b      0
;SHOWCURSOR    dc.b      0

; ROM code has its own data block at 0x500 - 0xC8A (0x78A bytes, 0x1E2 longs)!
CURPOS        equ       $500
DISPLAYSTART  equ       $502
CURSORCOUNT   equ       $504
CURRENTPAGE   equ       $506
SHOWCURSOR    equ       $508
BUFFER        equ       $50A

; TODO this should be in .rodata, but same issue as above.
SZID          dc.b    "Video board identified: V9958", 10, 13, 0
SZNOID        dc.b    "No video output found", 10, 13, 0
SZHEADER      dc.b    "                                ___ ___ _", 13
              dc.b    " ___ ___ ___ __ ___       _____|  _| . | |_",13
              dc.b    "|  _| . |_ -| _| . |     |     | . | . | '_|",13
              dc.b    "|_| |___|___|__|___|_____|_|_|_|___|___|_,_|",13
              dc.b    "                   |_____| Snapshot Firmware",13
              dc.b    13,13, 0
SZ_CR         dc.b    $D, 0


;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|      Xosera Video
;------------------------------------------------------------
; Copyright (c)2021 Ross Bamford & contributors
; See top-level LICENSE.md for licence information.
;
; Xosera 106x30 text console.
;------------------------------------------------------------
;
    include "../../../shared/rosco_m68k_public.asm"
    include "../rosco_m68k_private.asm"
    include "xosera_equates.asm"

LINELENGTH        equ   106      
LINECOUNT         equ   30
DISPLAYSIZE       equ   LINELENGTH*LINECOUNT
DWDISPLAYSIZE     equ   DISPLAYSIZE/4
CURPOS            equ   $500      ; dword
DISPLAYSTART      equ   $502      ; dword
BUFFER            equ   $504      ; 3180 bytes
                                  ; 16 bytes remaining...

    section .text

; TODO this needs to actually identify Xosera, but works for now.
HAVE_XOSERA::
    move.l  A0,-(A7)
    jsr     INSTALL_TEMP_BERR_HANDLER

    move.l  #XVID_BASE,A0
    move.b  (XVID_DATA,A0),D0

    tst.b   BERR_FLAG
    bne.s   .NOXVID

    move.l  #1,D0
    bra.s   .DONE

.NOXVID
    clr.l   D0
    
.DONE
    jsr     RESTORE_BERR_HANDLER
    move.l  (A7)+,A0
    rts


; Initialize the console
XOSERA_CON_INIT::
    movem.l D1-D2/A0-A1,-(A7)
    move.l  #XVID_BASE,A0                     ; Use A0 as port base register

    ori.w   #$0200,SR                         ; No interrupts during init...

    ; TODO Disable display

    bsr.s   XVID_SYNC                         ; detect Xosera responding
    ; if sync failed - fail the init
    tst.w   D0
    beq.s   .DONE 

    move.w  #$B007,D0                         ; set special constant
    movep.w D0,(XVID_CONST,A0)
    move.w  #$8180,D0                         ; Reconfigure Xosera for config #1 (848x480)
    movep.w D0,(XVID_BLIT_CTRL,A0)

    bsr.s   XVID_SYNC                         ; detect Xosera responding again
    ; if sync failed - fail the init
    tst.w   D0
    beq.s   .DONE 

.SYNC_DONE
    ; Clear console data area
.CLEARDATA:
    move.l  #CURPOS,A1
    move.w  #$320,D1
    bra.s   .CLEARSTART
.CLEARLOOP
    move.l  #0,(A1)+
.CLEARSTART
    dbra.w	D1,.CLEARLOOP

    ; Clear the main memory buffer and copy to the VRAM 
;    bsr.s   CLEARBUFFER
    lea     BUFFER,A1
    clr.b   D0
    bsr.w   BUFFERFLIP

    ; TODO enable display

    andi.w   #~$0200,SR                       ; Enable interrupts...

    move.l  #SZHEADER,A1
.PRINTLOOP
    move.b  (A1)+,D0
    beq.s   .PRINTDONE
     
    bsr.w   XVID_CON_PUTCHAR
    bra.s   .PRINTLOOP
.PRINTDONE

    move.l  #1,D0                             ; Success

.DONE
    andi.w   #~$0200,SR                       ; Enable interrupts...

    movem.l (A7)+,D1-D2/A0-A1
    rts


; Delay for D0.w loops...
; Modifies D0.
DELAY:
    bra.s   .DELAYSTART
.DELAYLOOP
    nop
    nop
    nop
    nop
    nop
.DELAYSTART
    dbra.w  D0,.DELAYLOOP
    rts


; Xosera Sync (private)
; 
; Modifies: D0, D1
;
; Returns: D1.w = zero if failed
XVID_SYNC:
    move.w  #100,D1                           ; try 100 times

.SYNC_LOOP
    move.w  #$55AA,D0
    movep.w D0,(XVID_CONST,A0)                ; Do sync checks
    movep.w (XVID_CONST,A0),D0                
    cmp.w   #$55AA,D0
    bne.s   .SYNC_NEXT

    move.w  #$AA55,D0
    movep.w D0,(XVID_CONST,A0)
    movep.w (XVID_CONST,A0),D0                
    cmp.w   #$AA55,D0
    bne.s   .SYNC_NEXT
    rts                                       ; return D0 non-zero

.SYNC_NEXT
    move.w  #10000,D0                         ; Wait a while
    bsr.s   DELAY
    
.SYNC_START
    dbra.w  D1,.SYNC_LOOP
    
    ; Fell through loop, so sync failed - fail the sync
    clr.w   D0                                ; return D0 zero
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
XVID_CON_CLRSCR:
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
    bsr.w   BUFFERFLIP
    rts


XVID_CON_PRINT:
    move.l  D0,-(A7)

.PRINTLOOP
    move.b  (A0)+,D0
    beq.s   .PRINTDONE
     
    bsr.w   XVID_CON_PUTCHAR
    bra.s   .PRINTLOOP
.PRINTDONE

    move.l  (A7)+,D0
    rts

XVID_CON_PRINTLN:
    bsr.s   XVID_CON_PRINT                 ; Print callers message
    move.l  A0,-(A7)                       ; Stash A0 to restore later
    
    lea     SZ_CR,A0                       ; Load CR...
    bsr.s   XVID_CON_PRINT                 ; ... and print it
        
    move.l  (A7)+,A0                       ; Restore A0
    rts

XVID_CON_SETCURSOR:
    ; TODO implement this!
    rts

XOSERA_CON_INSTALLHANDLERS::
    move.l  #XVID_CON_PRINT,EFP_PRINT
    move.l  #XVID_CON_PRINTLN,EFP_PRINTLN
    move.l  #XVID_CON_PUTCHAR,EFP_PRINTCHAR
    move.l  #XVID_CON_CLRSCR,EFP_CLRSCR
    move.l  #XVID_CON_SETCURSOR,EFP_SETCURSOR
    rts

; Internal sub to copy the main memory buffer to
; VRAM. Used at init and on scroll.
;
; Arguments:
;   A0    Xosera Base  
;   A1    Main memory buffer
;
; Trashes:
;   Nothing
;
BUFFERFLIP:
    movem.l D0-D2,-(A7)
    ori.w   #$0200,SR                         ; Cannot be interrupted for a bit...

    ; TODO disable screen

    ; Set up to write VRAM at 0x0
    clr.w   D1
    movep.w D1,(XVID_WR_ADDR,A0)            ; Setup VRAM write
    
.GOGOGO    
    move.w  DISPLAYSTART,D0
    move.w  #DISPLAYSIZE,D1

    bra.s   .COPY
.COPYLOOP
    clr.w   D2
    move.b  (A1,D0),D2
    or.w    #$0A00,D2
    movep.w D2,(XVID_DATA,A0)
    addq.w  #1,D0
    cmpi.w  #DISPLAYSIZE,D0
    bne.s   .COPY

    moveq.l #0,D0
  
.COPY
    dbra.w  D1,.COPYLOOP  

    ; TODO re-enable screen

    andi.w  #~$0200,SR                        ; Go for interrupts again...
    movem.l (A7)+,D0-D2
    rts


; Internal - Translate the buffer position in D1.W into the relevant
; VRAM position based on the setting of CURRENTPAGE and the
; current display start (in D2.W) , and set up Xosera for a VRAM 
; write there.
;
; Interrupts should be disabled while this happens!
;
; Arguments:
;   A0      Xosera base address
;   D1.W    Buffer position (CURPOS)
;   D2.W    Display start position (DISPLAYSTART)
;
; Modifies:
;   Xosera Registers
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
    movep.w D3,(XVID_WR_ADDR,A0)       ; Setup VRAM write
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
;   A0    Xosera base
;   A1    Buffer
;   D1.W  CURPOS (buffer pointer)
;   D2.W  DISPLAYSTART (start pointer)
; 
XVID_CON_PUTCHAR::
    ; Ignoring linefeeds (for legacy compatibility)
    cmp.b   #10,D0
    bne.s   .NOTIGNORED
  
    rts

.NOTIGNORED
    movem.l D1-D2/A0-A1,-(A7)
    
    move.l  #XVID_BASE,A0               ; Use A0 as Xosera base
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
    bsr.s   XVID_CON_PUTCHAR
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

    move.w  #$0A20,D0
    movep.w D0,(XVID_DATA,A0)             ; Overwrite character

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

    and.w   #$00FF,D0
    or.w    #$0A00,D0
    movep.w D0,(XVID_DATA,A0)             ; And write,
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
    move.w  #LINELENGTH,D2                ; Counter is line length
    bra.s   .CLEARLINE
.CLEARLINE_LOOP
    move.b  #0,(A1)+                      ; Clear character
.CLEARLINE
    dbra.w  D2,.CLEARLINE_LOOP

    ; Now we've scrolled, we need to copy the whole buffer and flip
    lea.l   BUFFER,A1
    bsr.w   BUFFERFLIP

.DONE
    movem.l (A7)+,D1-D2/A0-A1
    rts

    section .rodata
SZHEADER      dc.b    "                                ___ ___ _",13
              dc.b    " ___ ___ ___ __ ___       _____|  _| . | |_",13
              dc.b    "|  _| . |_ -| _| . |     |     | . | . | '_|",13
              dc.b    "|_| |___|___|__|___|_____|_|_|_|___|___|_,_|",13
              dc.b    "Xosera v0.12       |_____|  Firmware 2.0.DEV",13
              dc.b    13,13, 0
SZ_CR         dc.b    $D, 0



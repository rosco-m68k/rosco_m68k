;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____| Xosera ANSI Console
;  __ __
; |  |  |___ ___ ___ ___ ___
; |-   -| . |_ -| -_|  _| .'|
; |__|__|___|___|___|_| |__,|
;
; Xark's Open Source Enhanced Retro Adapter
;
; - "Not as clumsy or random as a GPU, an embedded retro
;    adapter for a more civilized age."
;------------------------------------------------------------
; Copyright (c)2021 Xark & contributors
; See top-level LICENSE.md for licence information.
;
; Xosera ANSI/VT100-esque text console.
;------------------------------------------------------------
; vim: set et ts=8 sw=8
;

                ifnd  TEST_FIRMWARE             ; building for firmware

                include "../../../shared/rosco_m68k_public.asm"
                include "../rosco_m68k_private.asm"

                else                            ; building for RAM testing

                include "rosco_m68k_public.asm"

                endif

                include "xosera_m68k_defs.inc"

XANSI_CON_DATA          equ     $500            ; XANSI console data area
XANSI_CON_DATA_END      equ     $57F            ; 128 bytes reserved (~0x60 used currently)

                section .text

                ifnd  TEST_FIRMWARE             ; building for firmware

; This verifies it is safe to touch Xosera memory (something HW responding via DTACK)
XANSI_HAVE_XOSERA::
                move.l  a0,-(sp)
                jsr     INSTALL_TEMP_BERR_HANDLER

                move.l  #XM_BASEADDR,a0
                move.b  (a0),d0

                tst.b   BERR_FLAG
                bne.s   .NOXVID

                moveq.l #1,d0
                bra.s   .DONE

.NOXVID
                moveq.l #0,d0

.DONE
                jsr     RESTORE_BERR_HANDLER
                move.l  (sp)+,a0
                rts

                endif

; assembly EFP entry points (C should already preserve regs other than d0-d1/a0-a1)

; Input:        A0
; Modified:     A0
XANSI_CON_PRINT::
                movem.l d0-d1/a1,-(sp)

                move.l  a0,-(sp)
                jsr     xansiterm_PRINT
                addq.l  #4,sp
                move.l  d0,a0

                movem.l (sp)+,d0-d1/a1
                rts

; Input:        A0
; Modified:     A0
XANSI_CON_PRINTLN::
                movem.l d0-d1/a1,-(sp)

                move.l  a0,-(sp)
                jsr     xansiterm_PRINTLN
                addq.l  #4,sp
                move.l  d0,a0

                movem.l (sp)+,d0-d1/a1
                rts

; Input:        D0
; Modified:     -
XANSI_CON_PRINTCHAR::
                movem.l d0-d1/a0-a1,-(sp)

                move.l  d0,-(sp)
                jsr     xansiterm_PRINTCHAR
                addq.l  #4,sp

                movem.l (sp)+,d0-d1/a0-a1
                rts

; Input:        D0
; Modified:     -
XANSI_CON_SETCURSOR::
                movem.l d0-d1/a0-a1,-(sp)

                move.l  d0,-(sp)
                jsr     xansiterm_SETCURSOR
                addq.l  #4,sp

                movem.l (sp)+,d0-d1/a0-a1
                rts


; Input:        -
; Modified:     D0
; NOTE: XANSI_CON_INPUTCHAR needs to be fast for 115.2Kbaud kermit, so in asm
XANSI_CON_INPUTCHAR::
                movem.l d2/a1-a2,-(sp)

                ifnd    TEST_FIRMWARE
                lea.l   XANSI_CON_DATA.w,a2
                else
                lea.l   _private_xansiterm_data,a2
                endif

                tst.b   2(a2)                   ; check if not query (send_index < 0)
                bmi.s   .NOQUERY

                movem.l d1/a0,-(sp)
                jsr     xansiterm_RECVQUERY     ; return char in d0
                movem.l (sp)+,d1/a0

                movem.l (sp)+,d2/a1-a2
                rts
.NOQUERY
                moveq.l #32,d2                  ; check 32 times before updating cursor
                move.l  8(a2),a1                ; a1=checkinput
.CHECKLOOPFAST
                jsr     (a1)                    ; checkinput
                tst.b   d0
                bne.s   .GOTCHARFAST

                subq.l  #1,d2
                bne.s   .CHECKLOOPFAST

.CHECKSLOW
                movem.l d1/a0,-(sp)
                jsr     xansiterm_UPDATECURSOR
                movem.l (sp)+,d1/a0

                moveq.l #32,d2                  ; update cursor every 32 checks
                move.l  8(a2),a1                ; a1=checkinput
.CHECKLOOP
                jsr     (a1)                    ; checkinput
                tst.b   d0
                bne.s   .GOTCHAR

                subq.l  #1,d2
                bne.s   .CHECKLOOP

                bra.s   .CHECKSLOW

.GOTCHAR
                move.l  4(a2),a1                ; a1=inputchar
                jsr     (a1)                    ; inputchar

                movem.l d0-d1/a0,-(sp)
                jsr     xansiterm_ERASECURSOR
                movem.l (sp)+,d0-d1/a0

                movem.l (sp)+,d2/a1-a2
                rts

.GOTCHARFAST
                move.l  4(a2),a1                ; a1=inputchar
                jsr     (a1)                    ; inputchar

                movem.l (sp)+,d2/a1-a2
                rts

; Input:        -
; Modified:     D0
XANSI_CON_CHECKINPUT::
                movem.l d1/a0-a1,-(sp)

                ifnd    TEST_FIRMWARE
                lea.l   XANSI_CON_DATA.w,a1
                else
                lea.l   _private_xansiterm_data,a1
                endif

                tst.b   2(a1)                   ; check for query (send_index >= 0)
                bpl.s   .CHARREADY

                move.l  8(a1),a0                ; a0=checkinput
                jsr     (a0)                    ; checkinput
                tst.b   d0
                bne.s   .CHARREADY

                jsr     xansiterm_UPDATECURSOR

                moveq.l #0,d0
                bra.s   .CHECKDONE

.CHARREADY
                jsr     xansiterm_ERASECURSOR

                moveq.l #1,d0
.CHECKDONE
                movem.l (sp)+,d1/a0-a1
                rts

; Initialize XANSI console (return zero if Xosera not responding, true on success)
; Input:        -
; Modified:     D0
XANSI_CON_INIT::
                movem.l d1-d3/a0-a1,-(sp)

                move.w  sr,d3                   ; save SR
                ori.w   #$0200,sr               ; no interrupts during init...

                jsr     xansiterm_INIT          ; return in d0

                tst.b   d0
                beq.s   .INITDONE

                ; replace EFP functions
                move.l  #XANSI_CON_PRINT,EFP_PRINT.w
                move.l  #XANSI_CON_PRINTLN,EFP_PRINTLN.w
                move.l  #XANSI_CON_PRINTCHAR,EFP_PRINTCHAR.w
                move.l  #XANSI_CON_SETCURSOR,EFP_SETCURSOR.w
                ; xansiterm_INIT will have saved previous input handlers (to wrap them)
                move.l  #XANSI_CON_INPUTCHAR,EFP_INPUTCHAR.w
                move.l  #XANSI_CON_CHECKINPUT,EFP_CHECKINPUT.w

.INITDONE
                move.w  d3,sr                   ; restore SR

                movem.l (sp)+,d1-d3/a0-a1
                rts

;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2020-2021 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; Default ANSI versions of FW_MOVEXY and FW_CLRSCR.
;------------------------------------------------------------
    section .text

; TODO this could do with cleaning up!
ANSI_MOVEXY::
    movem.l D0-D2/A0,-(A7)
    move.w  D1,D2                       ; Use D2 for coords..

    lea.l   ANSI_START_SZ,A0            ; Load ANSI initiator...
    bsr.w   FW_PRINT                    ; ... and print it

    eor.l   D0,D0                       ; Zero D0

    move.b  D2,D0                       ; Get Y from D1 into D0
    move.l  #10,-(A7)                   ; Stack base (10)...
    move.l  D0,-(A7)                    ; ... and Y coord
    bsr.w   print_unsigned              ; ... and print

    moveq   #ANSI_SEP,D0                ; Load separator...
    bsr.w   FW_PRINTCHAR                ; ... and print it

    eor.l   D0,D0                       ; Zero D0 again

    move.w  D2,D0                       ; Get coords into D0
    lsr.w   #8,D0                       ; Shift right to get X
    move.l  D0,(A7)                     ; Replace Y on stack with X...
    bsr.w   print_unsigned              ; ... and print

    addq    #8,A7                       ; Cleanup stack

    moveq   #ANSI_XYEND,D0              ; Load XY end command
    bsr.w   FW_PRINTCHAR                ; ... and print it

    movem.l (A7)+,D0-D2/A0              ; Restore regs
    rts                                 ; and done!

ANSI_CLRSCR::
    move.l  A0,-(A7)
    lea.l   ANSI_CLR_SZ,A0              ; Load ANSI Clear Screen...
    bsr.w   FW_PRINT                    ; ... and print it
    move.l  (A7)+,A0
    rts

    section .rodata

ANSI_START_SZ dc.b        $1B, "[", 0
ANSI_CLR_SZ   dc.b        $1B, "[H", $1B, "[2J" ,0   ; per DEC, [2J does not home cursor, so added [H
ANSI_SEP      equ         ';'
ANSI_XYEND    equ         'H'

;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2023 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; EFP handlers for rosco_m68k keyboard
;------------------------------------------------------------

    include "../../../shared/rosco_m68k_public.asm"

    section .text

INSTALL_KEYBOARD_HANDLERS::
    move.l  #.KEYBOARD_CHECK,EFP_CHECKINPUT
    move.l  #.KEYBOARD_INPUT,EFP_INPUTCHAR
    rts

.KEYBOARD_CHECK:
    move.l  A0,-(A7)
    move.l  A1,-(A7)
    move.l  #keyboard_device,A0
    jsr     CHAR_DEV_CHECKCHAR
    move.l  (A7)+,A1
    move.l  (A7)+,A0
    rts
    
.KEYBOARD_INPUT:
    move.l  A0,-(A7)
    move.l  A1,-(A7)
    move.l  #keyboard_device,A0
    jsr     CHAR_DEV_RECVCHAR
    move.l  (A7)+,A1
    move.l  (A7)+,A0
    rts



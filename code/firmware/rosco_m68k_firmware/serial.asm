;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2022 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; This is UART stuff for the serial driver.
;------------------------------------------------------------
    include "../../shared/rosco_m68k_public.asm"
    include "rosco_m68k_private.asm"

    section .text

; Send a single character via UART
;
; Trashes: Nothing
; Modifies: Nothing
SENDCHAR::
    move.l  A1,-(A7)
    move.l  EFP_SENDCHAR,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts

; Receive a single character via UART.
; Ignores overrun errors.
;
; Trashes: Nothing
; Modifies: D0 (return)
RECVCHAR::
    move.l  A1,-(A7)
    move.l  EFP_RECVCHAR,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts

; TODO Fix these for r2x, or remove them!
; Enable the transmitter
ENABLE_XMIT::
    ifd REVISION1X
    bset.b  #0,MFP_TSR
    endif
    rts

; Disable the transmitter
DISABLE_XMIT::
    ifd REVISION1X
    bclr.b  #0,MFP_TSR
    endif
    rts

; Enable the receiver
ENABLE_RECV::
    ifd REVISION1X
    bset.b  #0,MFP_RSR
    endif 
    rts

; Disable the receiver
DISABLE_RECV::
    ifd REVISION1X
    bclr.b  #0,MFP_RSR
    endif
    rts

;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2021 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; This is low-level UART stuff and exception handlers for the
; MC68901 serial driver.
;------------------------------------------------------------
    include "../../../shared/rosco_m68k_public.asm"
    include "../rosco_m68k_private.asm"

    section .text

; Send a single character via UART
;
; Trashes: MFP_UDR
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
; Trashes: MFP_UDR
; Modifies: D0 (return)
RECVCHAR::
    move.l  A1,-(A7)
    move.l  EFP_RECVCHAR,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rts

; Enable the transmitter
ENABLE_XMIT::
    bset.b  #0,MFP_TSR
    rts

; Disable the transmitter
DISABLE_XMIT::
    bclr.b  #0,MFP_TSR
    rts

; Enable the receiver
ENABLE_RECV::
    bset.b  #0,MFP_RSR        
    rts

; Disable the receiver
DISABLE_RECV::
    bclr.b  #0,MFP_RSR
    rts


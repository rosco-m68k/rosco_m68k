;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v1                 
;------------------------------------------------------------
; Copyright (c)2019 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; This is low-level UART stuff and exception handlers for the
; serial driver. Some of this could probably be moved to C 
; eventually.
;------------------------------------------------------------
    include "../equates.S"

    section .text


SENDCHAR::
.BEGIN
    move.b  MFP_TSR,D1            ; Get TSR
    btst    #7,D1                 ; Is buffer empty bit set?
    beq.s   .BEGIN                ; No - loop until it is

    move.b  D0,MFP_UDR            ; Put func arg in UDR
    rts

RECVCHAR::
    bclr.b  #7,MFP_GPDR           ; Lower RTS
.BEGIN
    move.b  MFP_RSR,D0            ; Get RSR
    btst    #7,D0                 ; Is buffer_full bit set?
    beq.s   .BEGIN                ; No - loop until it is...
    
    bset.b  #7,MFP_GPDR           ; Raise RTS
    eor     D0,D0                 ; Clear D0
    move.b  MFP_UDR,D0            ; Get the data
    rts

; Enable the transmitter and turn on GPIO #2.
ENABLE_XMIT::
    bset.b  #0,MFP_TSR
    bclr.b  #2,MFP_GPDR                 ; :LED on
    rts

; Disable the transmitter and turn off GPIO #2.
DISABLE_XMIT::
    bclr.b  #0,MFP_TSR
    bset.b  #2,MFP_GPDR                 ; :LED off
    rts

; Enable the receiver and turn on GPIO #3.
ENABLE_RECV::
    bset.b  #0,MFP_RSR        
    bclr.b  #3,MFP_GPDR                 ; :LED on
    rts

; Disable the receiver and turn off GPIO #3.
DISABLE_RECV::
    bclr.b  #0,MFP_RSR
    bset.b  #3,MFP_GPDR                 ; :LED off
    rts


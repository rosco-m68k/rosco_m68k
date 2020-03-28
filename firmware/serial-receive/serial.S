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
    include "../shared/equates.S"

    section .text

; Send a single character via UART
;
; Trashes: MFP_UDR
; Modifies: Nothing
SENDCHAR::
    move.l  D1,-(A7)              ; Save D1
.BEGIN
    bset.b  #7,MFP_GPDR           ; Raise (inhibit) RTS
    move.b  MFP_TSR,D1            ; Get TSR
    btst    #7,D1                 ; Is buffer empty bit set?
    beq.s   .BEGIN                ; No - loop until it is

    move.b  D0,MFP_UDR            ; Put func arg in UDR
    move.l  (A7)+,D1              ; Restore D1
    rts

; Receive a single character via UART.
; Ignores overrun errors.
;
; Trashes: MFP_UDR
; Modifies: D0 (return)
RECVCHAR::
    bclr.b  #7,MFP_GPDR           ; Lower RTS
.BEGIN
    move.b  MFP_RSR,D0            ; Get RSR
    btst    #7,D0                 ; Is buffer_full bit set?
    bne.s   .GOTCHR               ; Yes - Go to receive character

    btst    #6,D0                 ; Else, do we have an overrun error?
    bne.s   .GOTERR               ; .. Yes - handle that
    bra.s   .BEGIN                ; .. No - Just loop

.GOTERR
    move.b  MFP_UDR,D0            ; Empty buffer
    bchg.b  #1,MFP_GPDR           ; And toggle I1
    bra.s   .BEGIN                ; And continue testing...
    
.GOTCHR
    move.b  MFP_UDR,D0            ; Get the data
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


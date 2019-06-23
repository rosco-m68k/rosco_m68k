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

; These two *must* be kept in sync with the values in serial.c
; TODO find a way to not repeat these values...
BUF_SIZE      equ       4096
BUF_MASK      equ       BUF_SIZE-1

; Exception handler for transmit buffer empty (vector 0x4A).
TX_EMPTY_HANDLER::
    move.l  A0,-(A7)          ; Save regs...
    move.l  D0,-(A7)
    move.l  D1,-(A7)

    eor.l   D0,D0             ; Zero D0
    move.w  read_pointer,D0   ; Get read pointer
    move.w  write_pointer,D1  ; and write pointer
    cmp.w   D0,D1             ; Are they equal?
    beq.s   .DISABLE_XMIT     ; Nothing to send if so...

    lea.l   tx_buffer,A0      ; Get the tx buffer
    add.l   D0,A0             ; point to the next byte to read
    move.b  (A0),MFP_UDR      ; And send it to the UART.
    
    add.w   #1,D0             ; Incremement the read pointer
    and.w   #BUF_MASK,D0      ; Keep it in range
    move.w  D0,read_pointer   ; And store back to the variable

    bra.s   .DONE             ; Fin

.DISABLE_XMIT:
    bsr.s   DISABLE_XMIT      ; Disable the transmitter

.DONE:
    move.l  (A7)+,D1          ; Restore regs
    move.l  (A7)+,D0
    move.l  (A7)+,A0
    rte                       ; We're outta here.

; Enable the transmitter and turn on GPIO #2.
ENABLE_XMIT::
    bset.b  #0,MFP_TSR
    bclr.b  #2,MFP_GPDR                 ; :LED off
    rts

; Disable the transmitter and turn off GPIO #2.
DISABLE_XMIT::
    bclr.b  #0,MFP_TSR
    bset.b  #2,MFP_GPDR                 ; :LED on
    rts

; Hook the handlers into the appropriate vectors.
INIT_SERIAL_HANDLERS::
    lea     TX_EMPTY_HANDLER,A0
    move.l  A0,$128
    rts


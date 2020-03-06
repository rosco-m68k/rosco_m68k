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
    include "../../shared/equates.S"

    section .text

; These two *must* be kept in sync with the values in serial.c
; TODO find a way to not repeat these values...
BUF_SIZE      equ       4096
BUF_MASK      equ       BUF_SIZE-1

; Exception handler for transmit buffer empty (vector 0x4A).
TX_EMPTY_HANDLER:
    movem.l D0-D1/A0,-(A7)        ; Save regs
    bsr.w   CRITICAL_BEGIN        ; This is a critical section

    eor.l   D0,D0                 ; Zero D0
    move.w  tx_read_pointer,D0    ; Get read pointer
    move.w  tx_write_pointer,D1   ; and write pointer
    cmp.w   D0,D1                 ; Are they equal?
    beq.s   .DISABLE_XMIT         ; Nothing to send if so...

    lea.l   tx_buffer,A0          ; Get the tx buffer
    add.l   D0,A0                 ; point to the next byte to read
    move.b  (A0),MFP_UDR          ; And send it to the UART.
    
    add.w   #1,D0                 ; Incremement the read pointer
    and.w   #BUF_MASK,D0          ; Keep it in range
    move.w  D0,tx_read_pointer    ; And store back to the variable

    bra.s   .DONE                 ; Fin

.DISABLE_XMIT:
    bsr.s   DISABLE_XMIT          ; Disable the transmitter

.DONE:
    bsr.w   CRITICAL_END          ; End of critical section
    movem.l (A7)+,D0-D1/A0        ; Restore regs
    move.b  #~$4,MFP_ISRA         ; Clear interrupt-in-service
    rte                           ; We're outta here.


; Enable the transmitter and turn on GPIO #2.
ENABLE_XMIT::
    bset.b  #0,MFP_TSR
    move.b  #1,tx_enabled
    bclr.b  #2,MFP_GPDR                 ; :LED on
    rts

; Disable the transmitter and turn off GPIO #2.
DISABLE_XMIT::
    bclr.b  #0,MFP_TSR
    move.b  #0,tx_enabled
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


RX_FULL_HANDLER:
    movem.l D0-D1/A0,-(A7)        ; Save regs

    move.b  MFP_RSR,D0            ; Get RSR
    move.b  MFP_UDR,D1            ; And the data

    btst    #7,D0                 ; Is buffer_full bit set?
    beq.s   .DONE                 ; Spurious interrupt maybe..? So just leave
  
    eor     D0,D0                 ; Zero D0
    move.w  rx_write_pointer,D0   ; Get write pointer
    lea.l   rx_buffer,A0          ; Get rx buffer
    add.l   D0,A0                 ; Point to next write location
    move.b  D1,(A0)               ; And store byte from serial there

    add.w   #1,D0                 ; Incremement the write pointer
    and.w   #BUF_MASK,D0          ; Keep it in range
    move.b  #~$10,MFP_ISRA        ; Clear interrupt-in-service
    move.w  D0,rx_write_pointer   ; And store back to the variable

.DONE:
    movem.l (A7)+,D0-D1/A0        ; Restore regs
    rte


RX_ERROR_HANDLER:
; TODO
    movem.l D0-D7/A0-A6,-(A7)
    bsr.s   DISABLE_RECV
    move.b  MFP_RSR,-(A7)
    move.b  MFP_UDR,-(A7)
    jmp     handleRxError
    movem.l (A7)+,D0-D7/A0-A6
    move.b  #~$8,MFP_ISRA         ; Clear interrupt-in-service

    rte


; Hook the handlers into the appropriate vectors.
;
; Trashes: A0
INIT_SERIAL_HANDLERS::
; hook up tx empty handler
    lea     TX_EMPTY_HANDLER,A0
    move.l  A0,$128

; hook up rx error handler
    lea     RX_ERROR_HANDLER,A0
    move.l  A0,$12C

; hook up rx buffer full handler
    lea     RX_FULL_HANDLER,A0
    move.l  A0,$130
    rts


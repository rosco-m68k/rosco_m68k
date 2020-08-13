    section .text

    include "../../shared/equates.S"

; Exception handler for transmit error (vector 0x49)
TX_ERROR_HANDLER:
    move.b  #~$2,MFP_ISRA         ; Clear interrupt-in-service
    rte

; Exception handler for transmit buffer empty (vector 0x4A).
TX_EMPTY_HANDLER:
    movem.l D0-D1/A0,-(A7)        ; Save regs

    lea     TXBUFFER,A0
    bsr.s   BUFFER_AVAIL          ; Is there a character in the buffer?
    tst.b   D0
    beq.s   .DONE                 ; ... nope.. Bail.

    bsr.s   BUFFER_READ           ; ... yes - send it
    move.b  D0,MFP_UDR

.DONE
    movem.l (A7)+,D0-D1/A0        ; Restore regs
    move.b  #~$4,MFP_ISRA         ; Clear interrupt-in-service
    rte
    

; Exception handler for receiver error (vector 0x4B)
RX_ERROR_HANDLER:
    bchg.b  #1,MFP_GPDR           ; Toggle red LED
    move.l  D0,-(A7)
    move.b  MFP_RSR,D0            ; Read register to clear error
    move.l  (A7)+,D0
    move.b  #~$8,MFP_ISRA         ; Clear interrupt-in-service
    rte


; Exception handler for receive buffer full (vector 0x4C)
RX_FULL_HANDLER:
    movem.l D0-D1/A0,-(A7)        ; Save regs
    move.b  MFP_RSR,D0            ; Get RSR

    lea     RXBUFFER,A0
    move.b  MFP_UDR,D0            ; Get the data
    jsr     BUFFER_WRITE

    movem.l (A7)+,D0-D1/A0        ; Restore regs
    move.b  #~$10,MFP_ISRA        ; Clear interrupt-in-service
    rte


; Hook the handlers into the appropriate vectors.
;
; Trashes: A0
INIT_SERIAL_HANDLERS::
; hook up tx error handler
    lea     TX_ERROR_HANDLER,A0
    move.l  A0,$124

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


RECVCHAR::
    lea     RXBUFFER,A0
.BLOCK
    jsr     BUFFER_AVAIL
    tst.b   D0
    beq.s   .BLOCK
    jsr     BUFFER_READ
    rts


; This *always* buffers the argument, and then does a manual
; "priming" of the UART if the tx buffer is empty. In the
; latter case, it also cancels any pending TX empty interrupt.
;
; This lets us not have to worry about whether the tx 
; buffer is empty because it just emptied, or because this
; is the first character we're sending after a while. This
; also means we don't care whether the argument is the next
; character that should be sent or not.
;
SENDCHAR::
    ; 1) We need to not be interrupted by the reader of the buffer
    andi.b  #$FB,MFP_IMRA           ; Mask empty interrupt
    
    ; 2) We always buffer the character
    lea     TXBUFFER,A0
    move.b  7(A7),D0
    bsr.w   BUFFER_WRITE

    ; 3) If UART TX buffer is empty, we'll send next character from buffer manually
    btst.b  #7,MFP_TSR            ; Buffer empty?
    beq.s   .DONE                 ; No - just leave
    
    bsr.w   BUFFER_READ
    move.b  D0,MFP_UDR            ; Yes, send next char...
    move.b  #~$4,MFP_IPRA         ; ... and ensure no pending interrupt

.DONE
    ori.b   #4,MFP_IMRA           ; Unmask empty interrupt
    rts


GOFASTER::
    andi.b  #$FE,MFP_TSR          ; Disable transmitter
    andi.b  #$FE,MFP_RSR          ; ... and receiver

    move.b  #1,MFP_TDDR           ; Timer D count is 1 for 57.6KHz, divided to 28800 baud
    move.b  #$71,MFP_TCDCR        ; Enable timer C with /200 and D with /4 prescaler
    
    ; USART setup
    move.b  #$88,MFP_UCR          ; Use /16 clock, async, 8N1

    ori.b   #1,MFP_TSR            ; Enable transmitter
    ori.b   #1,MFP_RSR            ; ... and receiver
    rts
   
    section .data
 
TXBUFFER    dcb.b     258,0
RXBUFFER    dcb.b     258,0


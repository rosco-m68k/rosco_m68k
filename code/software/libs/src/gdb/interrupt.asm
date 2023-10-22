;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|         libraries
;------------------------------------------------------------
; Copyright (c)2023 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; interrupt for buffered DUART for debugger
;
; This is **not** general purpose, it's specifically wired to
; yank the breakpoint trap when Ctrl-C is received...
;
; The bits that do that are commented (there's one for each
; UART).
;
; See comments in gdb-support.c about potentially simplifying
; this whole piece...
;------------------------------------------------------------

        section .text
        align 2
; DUART register offsets
DUART_MRA       equ     $00
DUART_CSRA      equ     $02
DUART_SRA       equ     $02
DUART_CRA       equ     $04
DUART_RBA       equ     $06
DUART_IMR       equ     $0a
DUART_ISR       equ     $0a
DUART_MRB       equ     $10
DUART_SRB       equ     $12
DUART_CSRB      equ     $12
DUART_CRB       equ     $14
DUART_RBB       equ     $16

; DUART interrupt vector address
VECADDR         equ     $45<<2


; C callable - void duart_install_interrupt(CHAR_DEVICE *device, RingBuffer *uart_a, RingBuffer *uart_b)
;
; If you don't want to install for both UARTs, pass NULL for either RingBuffer pointer.
;
duart_install_interrupt::
        movem.l A0-A1/D0,-(A7)

        move.w  SR,D0                           ; Save SR
        or.w    #$0700,SR                       ; No interrupts for a bit

        move.l  16(A7),A0                       ; Get BASEADDR structure
        move.l  (A0),A0                         ; Get base address

        move.l  20(A7),A1                       ; Get RingBuffer A pointer
        move.l  A1,RINGBUF_A                    ; Store it
        beq.s   .uartb                          ; Skip setup if it's NULL

        ; Ensure UART A is set up just like we like it...
        move.b  #$88,DUART_CSRA(A0)             ; 115K2
        move.b  #$10,DUART_CRA(A0)              ; Reset to MR1A
        move.b  #$13,DUART_MRA(A0)              ; Ensure No RTS, RxRDY, Char, No parity, 8 bits
        move.b  #$07,DUART_MRA(A0)              ; (Normal, No TX CTS/RTS, 1 stop bit)

.uartb
        move.l  24(A7),A1                       ; Get RingBuffer B pointer
        move.l  A1,RINGBUF_B                    ; Dereference and store it
        beq.s   .done                           ; Skip setup if it's NULL

        ; Ensure UART B is set up just like we like it...
        move.b  #$88,DUART_CSRB(A0)             ; 115K2
        ;move.b  #$BB,DUART_CSRB(A0)             ; 9600
        move.b  #$10,DUART_CRB(A0)              ; Reset to MR1B
        move.b  #$13,DUART_MRB(A0)              ; Ensure No RTS, RxRDY, Char, No parity, 8 bits
        move.b  #$07,DUART_MRB(A0)              ; (Normal, No TX CTS/RTS, 1 stop bit)
        ;move.b  #$93,DUART_MRB(A0)              ; RTS, RxRDY, Char, No parity, 8 bits
        ;move.b  #$37,DUART_MRB(A0)              ; (Normal, TX CTS/RTS, 1 stop bit)

.done
        move.l  A0,BASEADDR                     ; Store BASEADDR base pointer
        move.l  VECADDR,CHAIN                   ; Store existing handler
        move.l  #HANDLER,VECADDR                ; And install new one

        move.b  #$28,DUART_IMR(A0)              ; Enable RXRDY/RXFULL interrupt and keep counter going
        move.w  D0,SR                           ; Re-enable interrupts

        movem.l (A7)+,A0-A1/D0
        rts


; C callable - void remove_interrupt(void)
;
duart_remove_interrupt::
        movem.l D0/A0-A1,-(A7)

        move.w  SR,D0                           ; Save SR
        or.w    #$0700,SR                       ; No interrupts for a bit

        move.l  CHAIN,VECADDR                   ; Restore original handler
        move.l  BASEADDR,A0                     ; Get BASEADDR structure
        move.b  #$08,DUART_IMR(A0)              ; Just keep counter going

        move.w  D0,SR                           ; Re-enable interrupts
        movem.l (A7)+,D0/A0-A1
        rts


; The interrupt handler (also chains to the original handler)
HANDLER:
        movem.l D0-D1/A0-A2,-(A7)
        move.l  BASEADDR,A0                     ; Load BASEADDR pointer
        move.l  #duart_buffer_char,A1           ; Buffer routine in A1
        move.l  RINGBUF_A,A2                    ; UART A RingBuffer in A2
        cmp.l   #0,A2                           ; Is the pointer NULL?
        beq.s   .uartB                          ; Skip to DUART B if so...

;; UART A
.loopA
        move.b  DUART_ISR(A0),D0
        btst    #1,D0                           ; Check if ready bit is set
        beq.s   .uartB                          ; Just bail now if not (and go check UART B)

        move.b  DUART_SRA,D0                    ; Check if error bits are set
        and.b   #$F0,D0
        beq.s   .contA                          ; Continue if not...
        bsr.s   .error                          ; ... else branch error subroutine

.contA
        move.b  DUART_RBA(A0),D0                ; Grab character from A receive buffer


        ; DEBUGGER SPECIFIC
        cmp.b   #3,D0
        bne.s   .do_buffer_a
        jsr     breakpoint
        ; /DEBUGGER SPECIFIC

.do_buffer_a:
        jsr     (A1)                            ; Call duart_buffer_char

        bra.s   .loopA                          ; And continue testing...

; .error is a subroutine, used by both A and B
.error
        move.b  D0,D1                           ; Every day I'm shufflin' (registers)
        btst    #4,D1                           ; Overrun error?
        beq.s   .notoverrun        
        move.b  #$40,DUART_CRA(A0)              ; Reset overrun error status

.notoverrun
        ifd ERROR_REPORTING

        btst    #5,D1                           ; Parity error?
        beq.s   .notparity

        move.b  #'P',D0
        jsr     (A1)                            ; Call duart_buffer_char
        move.b  #'?',D0
        jsr     (A1)                            ; Call buffer_char

.notparity
        btst    #6,D1                           ; Frame error?
        beq.s   .notframe

        move.b  #'F',D0
        jsr     (A1)                            ; Call duart_buffer_char
        move.b  #'?',D0
        jsr     (A1)                            ; Call duart_buffer_char

.notframe
        btst    #7,D1                           ; Break?
        beq.s   .notbreak

        move.b  #'B',D0
        jsr     (A1)                            ; Call duart_buffer_char
        move.b  #'?',D0
        jsr     (A1)                            ; Call duart_buffer_char

.notbreak
        endif ; ERROR_REPORTING
        rts
        
;; UART B
.uartB
        move.l  RINGBUF_B,A2                    ; UART B RingBuffer in A2
        cmp.l   #0,A2                           ; Is the pointer NULL?
        beq.s   .chain                          ; Skip to chained handler if so...

.loopB
        move.b  DUART_ISR(A0),D0
        btst    #5,D0                           ; Check if ready bit is set
        beq.s   .chain                          ; Just bail now if not (and go check timer tick)

        move.b  DUART_SRB,D0                    ; Check if error bits are set
        and.b   #$F0,D0
        beq.s   .contB                          ; Continue if not...
        bsr.s   .error                          ; ... else branch error subroutine

.contB        
        move.b  DUART_RBB(A0),D0                ; Grab character from B receive buffer

        ; DEBUGGER SPECIFIC
        cmp.b   #3,D0
        bne.s   .do_buffer_b
        jsr     breakpoint
        ; /DEBUGGER SPECIFIC

.do_buffer_b:
        jsr     (A1)                            ; Call duart_buffer_char

        bra.s   .loopB                          ; And continue testing...

.chain
        movem.l (A7)+,D0-D1/A0-A2               ; Restore regs...
        move.l  CHAIN,-(A7)                     ; And "return to" the original ISR
        rts


        section .bss
        align 2
RINGBUF_A   dc.l        0                       ; Ringbuffer for UART A
RINGBUF_B   dc.l        0                       ; Ringbuffer for UART B
BASEADDR    dc.l        0                       ; DUART base address from CHAR_DEVICE struct     
CHAIN       dc.l        0                       ; Chained ISR (timer tick probably)


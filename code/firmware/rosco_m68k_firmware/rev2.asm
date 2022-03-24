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
; This is the r2 board-specific code.
; It contains the revision-specific exception handlers
; and routines, aside from the DUART initialisation and
; DUART I/O.
;------------------------------------------------------------
    include "../../shared/rosco_m68k_public.asm"
    include "rosco_m68k_private.asm"

    ifnd REVISION1X

    section .text

    ifnd NO_68681

START_HEART::
    move.l  SDB_UARTBASE,A0
    move.b  #$08,DUART_IMR(A0)        ; Unmask counter interrupt
    rts

STOP_HEART::
    move.l  SDB_UARTBASE,A0
    move.b  #$00,DUART_IMR(A0)        ; Mask all interrupts
    rts

    endif


;------------------------------------------------------------
; Exception handlers    
TICK_HANDLER::
    move.l  D0,-(A7)                  ; Save D0
    move.l  A0,-(A7)
    move.l  SDB_UARTBASE,A0           ; Check if this is a counter interrupt...
    move.b  R_ISR(A0),D0
    btst    #3,D0   
    bne.s   .COUNTER                  ; Continue if so,
    
    move.l  (A7)+,A0                  ; Else restore regs...
    move.l  (A7)+,D0
    rte                               ; ...and bail.

.COUNTER

    move.l  D1,-(A7)                  ; Save D1

    ; Increment upticks
    move.l  SDB_UPTICKS,D0            ; Read SDB dword at 12
    add.l   #1,D0                     ; Increment
    move.l  D0,SDB_UPTICKS            ; And write back
    
    ; Heartbeat
    move.l  SDB_UARTBASE,A0           ; And fetch UART base pointer

    move.w  SDB_TICKCNT,D0            ; Read SDB word at 8
    tst.w   D0                        ; Is LSB zero?
    bne.s   .TICK_HANDLER_DONE        ; Done if not
    
    ; counted to zero, so toggle indicator 0 (if allowed) 
    ; and reset counter
    move.b  SDB_SYSFLAGS,D1           ; Get sysflags (high byte)
    btst    #1,D1                     ; Is sysflag bit 1 set?
    beq.s   .TICKRESET                ; bail now if not...

    move.b  SDB_INTFLAGS,D1
    tst.b   D1                        ; Is INTFLAGS zero?
    beq.s   .TURNON                   ; If so, go to turn on
    
    ; If here, LED is already on, turn it off
    move.b  #$20,W_OPR_RESETCMD(A0)   ; Turn it off
    move.b  #0,D1
    bra.s   .LEDDONE                  ; And we're done

.TURNON
    ; LED is off, turn it on
    move.b  #$20,W_OPR_SETCMD(A0)     ; Turn it on
    move.b  #1,D1
    
.LEDDONE
    move.b  D1,SDB_INTFLAGS

.TICKRESET
    move.w  #50,D0                    ; Reset counter

.TICK_HANDLER_DONE:

    sub.w   #$1,D0                    ; Decrement counter...
    move.w  D0,SDB_TICKCNT            ; ... and write back to SDB
    move.l  (A7)+,D1                  ; Restore D1

    move.b  R_STOPCNTCMD(A0),D0       ; Clear ISR[3]
    move.l  (A7)+,A0                  ; Restore A0
    move.l  (A7)+,D0                  ; Restore D0

    rte                               ; We're done


BUS_ERROR_HANDLER::
    or.w    #0700,SR                  ; Disable exceptions

    move.l  SDB_UARTBASE,A0
    move.b  #$00,DUART_IMR(A0)        ; Mask all interrupts
    move.b  #$00,DUART_OPCR(A0)       ; All GPIOs are output

    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED
    move.l  #100000,D0                ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED
    move.l  #200000,D0                ; Wait a while
    bsr.w   BUSYWAIT

    bra.s   BUS_ERROR_HANDLER
    
    rte                               ; Never reached


ADDRESS_ERROR_HANDLER::
    or.w    #0700,SR                  ; Disable exceptions

    move.l  SDB_UARTBASE,A0
    move.b  #$00,DUART_IMR(A0)        ; Mask all interrupts
    move.b  #$00,DUART_OPCR(A0)       ; All GPIOs are output

    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED
    move.l  #200000,D0                ; Wait a while
    bsr.w   BUSYWAIT

    bra.s   ADDRESS_ERROR_HANDLER
    
    rte                               ; Never reached


ILLEGAL_INSTRUCTION_HANDLER::
    or.w    #0700,SR                  ; Disable exceptions

    move.l  SDB_UARTBASE,A0
    move.b  #$00,DUART_IMR(A0)        ; Mask all interrupts
    move.b  #$00,DUART_OPCR(A0)       ; All GPIOs are output

    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$08,W_OPR_SETCMD(A0)     ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$08,W_OPR_RESETCMD(A0)   ; Turn off red LED
    move.l  #200000,D0                ; Wait a while
    bsr.w   BUSYWAIT

    bra.s   ILLEGAL_INSTRUCTION_HANDLER
    
    rte                               ; Never reached

    endif

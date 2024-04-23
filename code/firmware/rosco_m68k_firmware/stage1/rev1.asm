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
; This is the r1 board-specific code.
; It contains the revision-specific exception handlers
; and routines, aside from the MPF initialisation and
; MFP I/O.
;------------------------------------------------------------
    include "../../../shared/rosco_m68k_public.asm"
    include "rosco_m68k_private.asm"

    ifd REVISION1X

    section .text

START_HEART::
    bset.b  #5,MFP_IMRB               ; Unmask Timer C interrupt
    rts

STOP_HEART::
    bclr.b  #5,MFP_IMRB               ; Mask Timer C interrupt
    rts


;------------------------------------------------------------
; Exception handlers    
TICK_HANDLER::
    move.l  D0,-(A7)                  ; Save D0

    ; Increment upticks
    move.l  SDB_UPTICKS,D0            ; Read SDB dword at 12
    add.l   #1,D0                     ; Increment
    move.l  D0,SDB_UPTICKS            ; And write back
    
    ; Heartbeat
    move.w  SDB_TICKCNT,D0            ; Read SDB word at 8
    tst.w   D0                        ; Is it zero?
    bne.s   .TICK_HANDLER_DONE        ; Done if not
    
    ; counted to zero, so toggle indicator 0 (if allowed) 
    ; and reset counter
    move.b  SDB_SYSFLAGS,D0           ; Get sysflags (high byte)
    and.b   #1,D0                     ; Mask bit 0 to toggle with flags
    eor.b   D0,MFP_GPDR               ; Toggle GPDR

    move.w  #50,D0                    ; Reset counter

.TICK_HANDLER_DONE:

    sub.w   #$1,D0                    ; Decrement counter...
    move.w  D0,SDB_TICKCNT            ; ... and write back to SDB

    move.b  #~$20,MFP_ISRB            ; Clear interrupt-in-service
    move.l  (A7)+,D0                  ; Restore D0

    rte                               ; We're done


BUS_ERROR_HANDLER::
    or.w    #0700,SR                  ; Disable exceptions

    move.b  #0,MFP_IERA               ; Disable MFP interrupts
    move.b  #0,MFP_IERB               
    move.b  #$FF,MFP_DDR              ; All GPIOs are output
    
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #100000,D0                ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #200000,D0                ; Wait a while
    bsr.w   BUSYWAIT

    bra.s   BUS_ERROR_HANDLER
    
    rte                               ; Never reached


ADDRESS_ERROR_HANDLER::
    or.w    #0700,SR                  ; Disable exceptions

    move.b  #0,MFP_IERA               ; Disable MFP interrupts
    move.b  #0,MFP_IERB               
    move.b  #$FF,MFP_DDR              ; All GPIOs are output
    
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #200000,D0                ; Wait a while
    bsr.w   BUSYWAIT

    bra.s   ADDRESS_ERROR_HANDLER
    
    rte                               ; Never reached


ILLEGAL_INSTRUCTION_HANDLER::
    or.w    #0700,SR                  ; Disable exceptions

    move.b  #0,MFP_IERA               ; Disable MFP interrupts
    move.b  #0,MFP_IERB               
    move.b  #$FF,MFP_DDR              ; All GPIOs are output

    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$FD,MFP_GPDR             ; Turn on red LED
    move.l  #50000,D0                 ; Wait a while
    bsr.w   BUSYWAIT
    move.b  #$FF,MFP_GPDR             ; Turn off red LED
    move.l  #200000,D0                ; Wait a while
    bsr.w   BUSYWAIT

    bra.w   ILLEGAL_INSTRUCTION_HANDLER
    
    rte                               ; Never reached

    endif

;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v1                 
;------------------------------------------------------------
; Copyright (c)2020 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; Syscall implementations for rosco_m68k firmware
;
; Syscall interface is accessed via TRAP #14
;
; D1 is expected to contain the function code. Other arguments
; depend on the specific function - See README for details.
;------------------------------------------------------------

    section .text


INIT_SYSCALLS::
    move.l  #SYSCALL_HANDLER,$b8      ; Install syscall handler on TRAP #14
    rts


SYSCALL_HANDLER:
    nop
    nop
    cmp.l   #0,D1                     ; FC == 0?
    beq.s   .PRINT                    ;   PRINT if so...
    cmp.l   #1,D1                     ; FC == 1?
    beq.s   .PRINTLN                  ;   PRINTLN if so...
    cmp.l   #2,D1                     ; FC == 2?
    beq.s   .SENDCHAR                 ;   SENDCHAR if so...
    cmp.l   #3,D1                     ; FC == 3?
    beq.s   .RECVCHAR                 ;   RECVCHAR if so...
    rte                               ; That's all for now...

.PRINT
    move.l  A1,-(A7)
    move.l  $414,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rte

.PRINTLN
    move.l  A1,-(A7)
    move.l  $418,A1
    jsr     (A1)
    move.l  (A7)+,A1
    rte

.SENDCHAR
    bsr.w   SENDCHAR
    rte

.RECVCHAR
    bsr.w   RECVCHAR
    rte

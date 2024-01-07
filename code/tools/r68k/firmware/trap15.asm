;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2020-2023 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; TRAP #15 - Easy68K-compatible system calls for r68k
;            This code sets up the illegal instruction trap
;            for the r68k code to catch
;
; Note that when compiled in this code reserves three SDB
; bytes for configuration at 0x410-0x412.
;------------------------------------------------------------
    include "rosco_m68k_public.asm"
    
    section .text

; TRAP 15 provides access to Easy68K-compatible tasks
;
; D0 is expected to contain the task number (function code). Other arguments
; depend on the specific function - See README for details.
EASY68K_TRAP_15_HANDLER::
    move.l  D0,-(A7)                    ; Save function code
    
    cmp.l   #20,D0                      ; Is function code in range?
    bhi.s   .DONE                       ; Nope, leave...

    add.l   #$F0F0F0D0,D0
    move.l  D7,-(A7)
    move.l  D6,-(A7)
    move.l  D0,D7
    move.l  #$AA55AA55,D6
    illegal
    move.l  (A7)+,D6
    move.l  (A7)+,D7
    
    move.l  (A7)+,D0                    ; Restore function code
    
.DONE
    rte                                 ; That's all for now...
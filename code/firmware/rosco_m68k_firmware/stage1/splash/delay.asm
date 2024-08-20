;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2020-2024 Ross Bamford & contributors
; See rosco_m68k LICENSE.md for licence information.
;
; Delay routine for splash animation
;------------------------------------------------------------

; Delay for n 10ms timer ticks
; 
; Trashes: D0
; Modifies: Nothing
    include "../../../../shared/rosco_m68k_public.asm"

    section .text.MC_DELAY_MSEC_10
MC_DELAY_MSEC_10::
    move.l  (4,A7),D0                 ; Get 10ms delay count from the stack into D0
    add.l   SDB_UPTICKS.w,D0          ; add to current timer counter for time finished
.DELAYWAIT
    cmp.l   SDB_UPTICKS.w,D0          ; compare current time with time finished
    bcc.s   .DELAYWAIT                ;  ... while it's < (unsigned)
    
    rts
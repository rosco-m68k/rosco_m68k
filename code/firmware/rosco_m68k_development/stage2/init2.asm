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
; This is the initialization code for stage 2. 
;------------------------------------------------------------
    include "../../../shared/equates.S"

    section .text.init
    org     $2000

START::
    move.l  $414,A7                     ; Stack to top of RAM
    lea.l   linit,A0
    jsr     (A0)
    lea.l   lmain,A0
    jmp     (A0)                        ; Stage 2 is go


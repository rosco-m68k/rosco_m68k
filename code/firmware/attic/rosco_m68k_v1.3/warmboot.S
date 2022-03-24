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
; This is the warm reboot vector. It gets installed at $4 
; (replacing the cold boot vector) during the cold boot
; process (see main1.c).
;
; This vector simply prints a banner and then calls out to
; the PROGRAM_LOADER from the EFP table (by default, this is
; the compressed stage 2 / Kermit loader in ROM).
;------------------------------------------------------------
    section .text

warm_boot::
    move.l  $0,A7                 ; Reset stack
    lea.l   BANNER,A0             ; Load banner...
    jsr     FW_PRINT              ; And print it
    move.l  $448,A0               ; Get address from PROGRAM_LOADER_EFP...
    jmp     (A0)                  ; ... and gogogo!

    section .rodata

BANNER  dc.b  $D, $A, $D, $A 
        dc.b  $1B, "[0m**********************", $D, $A
        dc.b  $1B, "[1;37mrosco_m68k - Warm boot", $D, $A
        dc.b  $1B, "[0m**********************"
        dc.b  $D, $A, $D, $A, 0

;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2021 Ross Bamford and contributors
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
    include "../../shared/rosco_m68k_public.asm"

    section .text

warm_boot::
    bsr.s   load_sp               ; Load stack pointer
    lea.l   BANNER,A0             ; Load banner...
    jsr     FW_PRINT              ; ... and print it
    bra.s   hot_boot_no_load_sp

hot_boot::
    bsr.s   load_sp               ; Load stack pointer
hot_boot_no_load_sp:
    move.l  EFP_PROGLOADER,A0     ; Get address from FW_PROGRAM_LOADER...
    jmp     (A0)                  ; ... and gogogo!

load_sp:
    move.l  (A7)+,D0
    move.l  SDB_MEMSIZE,A7        ; Reset stack to first memory block size...
    add.l   #RAMBASE,A7           ; ... plus the base of that block
    move.l  D0,-(A7)
    rts


    section .rodata

BANNER  dc.b  $D, $A, $D, $A 
        dc.b  $1B, "[0m",    "**********************", $D, $A
        dc.b  $1B, "[1;37m", "rosco_m68k - Warm boot", $D, $A
        dc.b  $1B, "[0m",    "**********************", $D, $A
        dc.b  $D, $A, 0

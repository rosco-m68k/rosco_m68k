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
; This is the warm reboot vector. It gets installed at $4 
; (replacing the cold boot vector) during the cold boot
; process (see main1.c).
;
; This vector simply prints a banner and then calls out to
; the PROGRAM_LOADER from the EFP table (by default, this is
; the compressed stage 2 / Kermit loader in ROM).
;------------------------------------------------------------
    include "../../shared/rosco_m68k_public.asm"
    include "rosco_m68k_private.asm"

    section .text

; Print warm boot banner, load stack pointer, and jump to program loader
;
warm_boot::
    move.l  VECTORS_LOAD,A7       ; Reset stack from reset stack pointer
    move.l  SDB_CPUINFO,D0        ; get cpu info from sdb
    and.l   #$e0000000,D0         ; just the high three bits

    cmp.l   #$40000000,D0         ; if it's less than 020...
    blt.s   .cachedone            ; don't disable caches...

    mc68020
    move.l  #$00000808,D0         ; Clear and disable all caches
    movec.l D0,cacr

.cachedone
    mc68000    
    lea.l   BANNER,A0             ; Load banner...
    jsr     FW_PRINT              ; ... and print it
    bra.s   hot_boot_no_load_sp   ; Continue to program loader

; Load stack pointer and jump to program loader
;
hot_boot::
    move.l  VECTORS_LOAD,A7       ; Reset stack from reset stack pointer
hot_boot_no_load_sp:
    move.l  EFP_PROGLOADER,A0     ; Get address from FW_PROGRAM_LOADER...
    jmp     (A0)                  ; ... and gogogo!


    section .rodata

BANNER  dc.b  $D, $A, $D, $A 
        dc.b  $1B, "[0m",    "**********************", $D, $A
        dc.b  $1B, "[1;37m", "rosco_m68k - Warm boot", $D, $A
        dc.b  $1B, "[0m",    "**********************", $D, $A
        dc.b  $D, $A, 0

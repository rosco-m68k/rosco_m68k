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
; Global equates for firmware code
;------------------------------------------------------------

; Version (embedded into firmware at 0xFC0400)
; MSW is flags, LSW is split into major (MSB) and minor (LSB)
;
; Flags:
; bit 0 - 14: Reserved
; bit 15    : Snapshot version
RELEASE_VER equ     $80000110

; EFP table addresses
EFP_PRINT		equ    $420
EFP_PRINTLN		equ    $424
EFP_PRINTCHAR   equ    $428
EFP_HALT		equ    $42C
EFP_SENDCHAR    equ    $430
EFP_RECVCHAR    equ    $434
EFP_CLRSCR      equ    $438
EFP_MOVEXY      equ    $43C

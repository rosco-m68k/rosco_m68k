;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       software v2
;------------------------------------------------------------
; Copyright (c)2021 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;------------------------------------------------------------
;
    section .text                     ; This is normal code

reboot_to_init::
    or.w    #$0700,SR
    move.l  $00e00000,A7
    move.l  $00e00004,A0
    reset
    jmp     (A0)


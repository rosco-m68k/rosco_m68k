;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|    firmware v1.2
;------------------------------------------------------------
; Copyright (c)2020 Ross Bamford See top-level LICENSE.md for licence
; information.
;
; This is the initialization code. The loader jumps into this code after the
; "program" is received via serial.
;
; The first section is position independent, but will be loaded by the
; firmware loader at $00040000 (or $00028000 prior to firmware 1.2). This
; section copies the rest of the loaded code to $1000, and then jumps to it.
;
; The second section (after RELOCATED_START) is executed next, based at $1000.
; This just calls out to __kinit to initialize .data and .bss, and then does a
; jump straight into kmain (the user program).
;
; All of this is depending on a bit of linker magic - see rosco_m68k_kernel.ld
; to see how that works.
;------------------------------------------------------------
    include "../../shared/equates.S"

    section .init

; NOTE: Loaded at $00040000 (or $00028000 in firmware prior to r1.2), but init
; code is position-independent.


START::                           ; position-independent load addr
    move.b  MFP_GPDR,D0           ; Get GPDR
    or.b    #2,D0                 ; Turn off I1
    and.b   D1,D0                 ; Mask with flags
    move.b  D0,MFP_GPDR           ; Set GPDR
    move.l  $414,A7               ; Reset stack to top of memory

    lea.l   START(PC),A0          ; PC-rel source addr (load addr)
    lea.l   _init,A1              ; absolute dest addr (run addr)
    move.l  #_postinit_end,D0     ; init section absolute end addr
    sub.l   A1,D0                 ; subtract dest addr for init length
    lsr.l   #2,D0                 ; convert to long words
    subq.l  #1,D0                 ; subtract 1 for dbra
.INIT_LOOP:
    move.l  (A0)+,(A1)+           ; copy long word from source to dest
    dbra    D0,.INIT_LOOP         ; loop until end of postinit

    jmp     _postinit             ; jump to copied postinit at run addr

    section .postinit

POSTINIT:                         ; running from copied run addr location
    move.l  #_data_end,D0         ; absolute data end addr from linker
    sub.l   A1,D0                 ; subtract dest addr for code+data length
    lsr.l   #2,D0                 ; convert to long words
    move.l  D0,D1                 ; copy for outer loop
    swap    D1                    ; swap for 64K chunk count
    bra.b   .COPY_START           ; branch to loop test first

.COPY_LOOP:
    move.l  (A0)+,(A1)+           ; copy long word from source to dest
.COPY_START
    dbra    D0,.COPY_LOOP         ; inner loop
    dbra    D1,.COPY_LOOP         ; outer loop

PREMAIN:
    move.l  $0004,-(A7)           ; push (soft) reset vector if kmain returns
    lea.l   __kinit,A0
    jsr     (A0)                  ; prepare C environment
    lea.l   kmain,A0
    jmp     (A0)                  ; Fly user program, Fly!

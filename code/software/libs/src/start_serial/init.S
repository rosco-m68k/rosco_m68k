;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;     |_____|       firmware v1.2
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

; Stack and all registers can be trashed at this point, the machine is your
; own...
START::
    bset.b  #1,MFP_GPDR           ; turn off red LED

    move.l  #_STACK_TOP,A7        ; reset stack (from linker script)

    lea.l   START(PC),A0          ; source addr, PC-rel. start (load addr)
    lea.l   _init,A1              ; target addr, abs. start (run addr)
    move.l  #_data_end,D0         ; use code+data length from linker
    sub.l   A1,D0                 ; use code+data length from linker
    lsr.l   #2,D0                 ; convert to long words
    subq.l  #1,D0                 ; convert to zero based length for dbf
    move.l  D0,D1                 ; copy for outer loop
    swap    D1                    ; swap for outer 64K loop count
.COPY_LOOP:
    move.l  (A0)+,(A1)+           ; copy long word from source to target
    dbra     D0,.COPY_LOOP        ; inner loop for up to 64K
    jmp     _postinit             ; NOTE: jump to *relocated* to continue

    section .postinit
                                  ; NOTE: code will have been copied from
                                  ; above, but now in new relocated segment at
                                  ; run addr, vs load addr and copy continues
                                  ; but, since we crossed segments, we need to
                                  ; use manual branch offset since assembler
                                  ; (wisely) won't branch between segments
    dbra     D1,*-12              ; outer loop to .COPY_LOOP for > 64K

PREMAIN:
    move.l  $0004,-(A7)           ; push (soft) reset vector if kmain returns
    lea.l   __kinit,A0
    jsr     (A0)                  ; prepare C environment
    lea.l   kmain,A0
    jmp     (A0)                  ; Fly user program, Fly!

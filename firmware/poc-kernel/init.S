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
; This is the initialization code. The loader jumps into this
; code after the "kernel" is received via serial.
;
; The first section is linked to be run at $28000, where the
; loader loads the code. This section copies the rest of the
; loaded code to $1000, and then jumps to it.
;
; The second section (after RELOCATED_START) is executed
; next, based at $1000. This just calls out to kinit to 
; initialize .data and .bss, and then does a jump straight
; into kmain (see kmain.c).
;
; All of this is depending on a bit of linker magic - see 
; rosco_m68k_kernel.ld to see how that works. 
;------------------------------------------------------------
    include "../shared/equates.S"

    section .init
    org     $28000

; Stack and all registers can be trashed at this point,
; the machine is your own...
START::
    bset.b  #1,MFP_GPDR                 ; Turn off red LED

    move.l  #RAMLIMIT,A7                ; Reset stack 
    move.l  #_init_end,A0               ; End of init into A0 (source)
    move.l  #_code,A1                   ; target into A1 (destination)

.COPY_LOOP:    
    move.l  (A0)+,(A1)+                 ; Copy source to dest, with postincrement.
    cmp.l   #_end,A1                    ; Done?
    bhi.s   .COPY_DONE                  ; ... Yep, break
    bra.s   .COPY_LOOP                  ; ... Nope, loop again...
   
.COPY_DONE:
    jmp     _code                       ; Jump to copied code

RELOCATED_START:

    section .text
    org $1000

PREMAIN:
    bsr.w   kinit
    jmp     kmain

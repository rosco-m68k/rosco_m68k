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
; The first section is linked to be run at $40000, where the
; loader loads the code. This section copies the rest of the
; loaded code to $1000, and then jumps to it.
;
; The second section (after RELOCATED_START) is executed
; next, based at $1000. This just calls out to __kinit to 
; initialize .data and .bss, and then does a jump straight
; into kmain (the user program).
;
; All of this is depending on a bit of linker magic - see 
; rosco_m68k_kernel.ld to see how that works. 
;------------------------------------------------------------
    include "../../shared/equates.S"

    section .init
; NOTE: Loaded at $28000, but copy oop has been made position-independent.

; Stack and all registers can be trashed at this point,
; the machine is your own...
START::
    bset.b  #1,MFP_GPDR                 ; Turn off red LED

    move.l  #_STACK_TOP,A7              ; Reset stack (from linker script)
    lea.l   RELOCATED_START(pc),A0      ; End of init into A0 PC-rel (source)
    move.l  #_postinit,A1               ; target into A1 (destination)

.COPY_LOOP:    
    move.l  (A0)+,(A1)+                 ; Copy source to dest, with post-increment.
    cmp.l   #_data_end,A1               ; Done?
    bls.s   .COPY_LOOP                  ; Nope - loop again...
  
.COPY_DONE:
    jmp     _postinit                   ; Jump to copied code

RELOCATED_START:

    section .postinit
    org $4000

PREMAIN:
    move.l  $FC0004,-(A7)               ; Push reset vector in case kmain returns
    lea.l   __kinit,A0
    jsr    (A0)
    lea.l   kmain,A0
    jmp     (A0)                        ; Fly user program, Fly!

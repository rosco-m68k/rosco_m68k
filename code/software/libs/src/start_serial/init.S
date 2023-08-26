;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|           stdlibs
;------------------------------------------------------------
; Copyright (c)2020-2021 Ross Bamford See top-level LICENSE.md 
; for licence information.
;
; This is the initialization code. The loader jumps into this code after the
; "program" is received via serial.
;
; The first section is position independent, but will be loaded by the
; firmware loader at $00040000. This section copies the rest of the loaded 
; code to $2000, and then jumps to it.
;
; The second section (after RELOCATED_START) is executed next, based at $1000.
; This just calls out to __kinit to initialize .data and .bss, and then does a
; jump straight into kmain (the user program).
;
; All of this is depending on a bit of linker magic - see rosco_m68k_kernel.ld
; to see how that works.
;
; GCC global constructors/destructors (with attributes and 
; __cxa_atexit) are supported here, too.
;------------------------------------------------------------
    include "../../shared/rosco_m68k_public.asm"

    section .init

; NOTE: Loaded at $00040000 but init code is position-independent.

START::                           ; position-independent load addr
    move.l  SDB_MEMSIZE,A7        ; Reset stack to top of memory

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
    ; Save existing program exit EFP
    ; Cannot use stack as we may jump directly with exit() or abort(),
    ; from arbitrarily nested code...
    move.l  EFP_PROG_EXIT,SAVE_PROG_EXIT

    ; And set up new one at POSTMAIN
    move.l  #.POSTMAIN,EFP_PROG_EXIT
 
    lea.l   __kinit,A0
    jsr     (A0)                  ; prepare C environment
    bsr.s   CALL_CTORS            ; Call global constructors
    lea.l   kmain,A0
    jsr     (A0)                  ; Fly user program, Fly!

.POSTMAIN:
    ; Restore EFP_PROG_EXIT
    move.l  SAVE_PROG_EXIT,EFP_PROG_EXIT
    move.l  #0,-(A7)              ; Call __cxa_finalize with NULL dso_handle
    lea.l   __cxa_finalize,A0
    jsr     (A0)
    add.l   #4,A7
    bsr.s   CALL_DTORS            ; Call global destructors
    move.l  $0004,A0              ; And jump to soft reset
    jmp     (A0) 

CALL_CTORS::
    movem.l A2-A4,-(A7)

    move.l  #_ctors,A2
    move.l  #_ctors_end,A3

.LOOP
    sub.l   #4,A3

    cmp.l   A2,A3
    bcs.s   .DONE

    move.l  (A3),A4
    jsr     (A4)

    bra.s   .LOOP

.DONE
    movem.l (A7)+,A2-A4
    rts


CALL_DTORS::
    movem.l A2-A4,-(A7)

    move.l  #_dtors,A2
    move.l  #_dtors_end,A3

.LOOP
    cmp.l   A3,A2
    beq.s   .DONE

    move.l  (A2),A4
    jsr     (A4)

    add.l   #4,A2
    bra.s   .LOOP

.DONE
    movem.l (A7)+,A2-A4
    rts

    section .bss,bss
    align  4

SAVE_PROG_EXIT  ds.l  1


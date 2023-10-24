;
; vim: set et ts=8 sw=8
;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|
; ------------------------------------------------------------
; Copyright (c) 2020 Xark
; MIT License
; ------------------------------------------------------------

; This adds a small (~1 KiB) 680x0 exception handler stub so that if a
; CPU exception occurs (i.e., a crash) it will print the CPU PC address where
; the exception occurred along with registers on the default output device.
; Often with just the PC crash address you can narrow down the source code
; causing the problem with e.g:
;
; m68k-elf-addr2line -e myprogram.elf 0x1234
;
; This will often give a line "near" the problem (usually after the actual
; cause), but is still very helpful.
;
; You can also look for the PC crash address in the ".dis" disassembly, which
; if debug information is enabled will show the source with corresponding asm
; code (and match up PC crash address).
;
; TO USE: Link with program -ldebug_stub, #include <debug_stub.h> and call
; debug_stub() at program startup.  This will install the exception handlers
; (with no other noticeable effect).  After this, a program crash will invoke
; a debug_stub exception handler which will print CPU state at the time of the
; crash on the default output device, and then warm-reset back to the loader.

                include "../rosco_m68k_public.asm"
                include "../rosco_m68k_private.asm"

                section .text
                align  2
debug_stub::
                moveq.l #10,d0
                lea.l   8.w,a1
                lea.l   .buserr_hdlr(pc),a0
.setvecloop     move.l  a0,(a1)+
                add.l   #.addrerr_hdlr-.buserr_hdlr,a0
                subq.l  #1,d0
                bne     .setvecloop
                rts

.buserr_str     dc.b    "Bus error",0
.addrerr_str    dc.b    "Address error",0
.illegal_str    dc.b    "Illegal instruction",0
.divzero_str    dc.b    "Division by zero",0
.chkinst_str    dc.b    "CHK instruction",0
.trapinst_str   dc.b    "TRAPV instruction",0
.privil_str     dc.b    "Privilege violation",0
.trace_str      dc.b    "Trace",0
.Ainstr_str     dc.b    "$Axxx instruction",0
.Finstr_str     dc.b    "$Fxxx instruction",0

.exintro_str    dc.b    13,10,7,"*** Software Failure: ",0
.exfa_str       dc.b    " (fault addr ",0
.exfa2_str      dc.b    ")",0
.expc_str       dc.b    13,10,"PC=",0
.exop_str       dc.b    " op=",0
.exsr_str       dc.b    "     SR=",0
.exus_str       dc.b    "    USP=",0
.crlf_str       dc.b    13,10,0

                align   2
; NOTE: These handlers targets must all be the exact same size
.buserr_hdlr    or.w    #$0700,sr
                movem.l d0-d7/a0-a7,-(sp)
                moveq.l #0<<1,d2
                bra.b   .debug_dump
.addrerr_hdlr   or.w    #$0700,sr
                movem.l d0-d7/a0-a7,-(sp)
                moveq.l #1<<1,d2
                bra.b   .debug_dump
.illegal_hdlr   or.w    #$0700,sr
                movem.l d0-d7/a0-a7,-(sp)
                moveq.l #2<<1,d2
                bra.b   .debug_dump
.divzero_hdlr   or.w    #$0700,sr
                movem.l d0-d7/a0-a7,-(sp)
                moveq.l #3<<1,d2
                bra.b   .debug_dump
.chkinst_hdlr   or.w    #$0700,sr
                movem.l d0-d7/a0-a7,-(sp)
                moveq.l #4<<1,d2
                bra.b   .debug_dump
.trapinst_hdlr  or.w    #$0700,sr
                movem.l d0-d7/a0-a7,-(sp)
                moveq.l #5<<1,d2
                bra.b   .debug_dump
.privil_hdlr    or.w    #$0700,sr
                movem.l d0-d7/a0-a7,-(sp)
                moveq.l #6<<1,d2
                bra.b   .debug_dump
.trace_hdlr     or.w    #$0700,sr
                movem.l d0-d7/a0-a7,-(sp)
                moveq.l #7<<1,d2
                bra.b   .debug_dump
.Ainstr_hdlr    or.w    #$0700,sr
                movem.l d0-d7/a0-a7,-(sp)
                moveq.l #8<<1,d2
                bra.b   .debug_dump
.Finstr_hdlr    or.w    #$0700,sr
                movem.l d0-d7/a0-a7,-(sp)
                moveq.l #9<<1,d2

        ; double check above sizes all match
        if      (.Finstr_hdlr-.buserr_hdlr)!=(.addrerr_hdlr-.buserr_hdlr)*9
                fail    "exception handler target size mismatch"
        endif

.debug_dump     move.w  16<<2(sp),-2(sp)  ; SR
                move.l  16<<2+2(sp),a0
                move.l  a0,-6(sp)         ; PC
                move.w  (a0),-8(sp)       ; Opcode
                clr.l   -12(sp)           ; Fault
                cmp.w   #2<<1,d2          ; fault for addr & bus error only
                bge     .nofault
                move.l  16<<2+10(sp),-12(sp) ; Fault
                bra     .nofault

; NOTE: Table placed here so byte displacement branches above can reach
.except_strtbl  dc.w    .buserr_str-.except_strtbl
                dc.w    .addrerr_str-.except_strtbl
                dc.w    .illegal_str-.except_strtbl
                dc.w    .divzero_str-.except_strtbl
                dc.w    .chkinst_str-.except_strtbl
                dc.w    .trapinst_str-.except_strtbl
                dc.w    .privil_str-.except_strtbl
                dc.w    .trace_str-.except_strtbl
                dc.w    .Ainstr_str-.except_strtbl
                dc.w    .Finstr_str-.except_strtbl

.nofault        sub.l   #12,sp                  ; room on stack for temps
                lea.l   stub_print(pc),a1
                lea.l   .exintro_str(pc),a0
                jsr     (a1)                    ; print exception name
                move.w	.except_strtbl(pc,d2.w),d0
                lea.l   .except_strtbl(pc,d0.w),a0
                jsr     (a1)
                move.l  (sp),d2                 ; ex_fault
                beq     .nofault2
                lea.l   .exfa_str(pc),a0
                jsr     (a1)
                bsr     printhex                ; print fault address (if any)
                lea.l   .exfa2_str(pc),a0
                jsr     (a1)
.nofault2       lea.l   .expc_str(pc),a0
                jsr     (a1)
                move.l  6(sp),d2                ; ex_pc
                bsr     printhex                ; print PC
                lea.l   .exop_str(pc),a0
                jsr     (a1)
                move.l  6(sp),a0                ; ex_pc
                move.l  (a0),d2                 ; into upper word
                moveq.l #4,d3                   ; 4 digits
                bsr     printhex_n              ; print opcode
                lea.l   .exsr_str(pc),a0
                jsr     (a1)
                move.l  10(sp),d2               ; ex_sr into upper word
                moveq.l #4,d3                   ; 4 digits
                bsr     printhex_n              ; print SR
                lea.l   .exus_str(pc),a0
                jsr     (a1)
                add.l   #12,sp                  ; restore stack
                move.l  usp,a0
                move.l  a0,d2
                bsr     printhex                ; print USP
                lea.l   .crlf_str(pc),a0
                jsr     (a1)
                moveq.l #0,d4                   ; register counter (a reg >= 8)
                lea.l   stub_prchar(pc),a0
                move.l  a7,a2
.regloop        moveq.l #"d",d0
                cmp.b   #8,d4
                blt     .notareg
                moveq.l #"a",d0
.notareg        jsr     (a0)                    ; print "d" or "a"
                move.l  d4,d0
                and.b   #7,d0
                bsr     hexdigit
                jsr     (a0)                    ; print register number
                moveq.l #"=",d0
                jsr     (a0)
                move.l  (a2)+,d2
                bsr     printhex
                addq.l  #1,d4
                move.b  d4,d0
                and.b   #3,d0
                beq     .preol
                moveq.l #" ",d0
                jsr     (a0)
                bra     .regloop
.preol          moveq.l #13,d0
                jsr     (a0)
                moveq.l #10,d0
                jsr     (a0)
                cmp.b   #16,d4
                blt     .regloop
                and.w   #$F0FF,sr               ; Re-enable interrupts
                move.l  4.w,a0                  ; And warmboot
                jmp     (a0)

; prints hex number, enter with d2.l, alters a0, d0, d2 & d3
printhex        moveq.l #8,d3
printhex_n      lea.l   stub_prchar(pc),a0
.hexloop        rol.l   #4,d2
                move.b  d2,d0
                and.w   #$F,d0
                bsr     hexdigit
                jsr     (a0)
                subq.b  #1,d3
                bne     .hexloop
                rts
hexdigit        cmp.b   #10,d0
                blt     .notalpha
                addq.b  #7,d0
.notalpha       add.w   #"0",d0
                rts

; print char, and echo on UART if different EFP function for PRINTCHAR and SENDCHAR
stub_prchar     move.l  a0,-(sp)                ; save ptr to this function
                move.l  EFP_PRINTCHAR.w,a0     ; print char to CONSOLE/UART
                jsr     (a0)
                cmp.l   EFP_SENDCHAR.w,a0      ; is CONSOLE same as UART?
                beq     .skip_uart              ; skip UART if PRINTCHAR == SENDCHAR
                move.l  EFP_SENDCHAR.w,a0      ; print char to UART
                jsr     (a0)      
.skip_uart      move.l  (sp)+,a0                ; restore ptr to this function
                rts

; print string, and echo on UART if different EFP function for PRINTCHAR and SENDCHAR
stub_print      move.l  a1,-(sp)                ; save ptr to this function
                move.l  a0,-(sp)                ; save ptr to string
                move.l  EFP_PRINT.w,a1         ; print to CONSOLE/UART
                jsr     (a1)
                move.l  EFP_PRINTCHAR.w,a1     ; load PRINTCHAR
                cmp.l   EFP_SENDCHAR.w,a1      ; is CONSOLE same as UART?
                move.l  (sp)+,a0                ; restore ptr to string
                beq     .skip_uart              ; skip UART if PRINTCHAR == SENDCHAR
                move.l  EFP_SENDCHAR.w,a1      ; print string to UART
.pr_loop        move.b  (a0)+,d0                ; load string char
                beq.s   .skip_uart              ; if zero, branch done
                jsr     (a1)                    ; print char
                bra.s   .pr_loop                ; loop
.skip_uart      move.l  (sp)+,a1                ; restore ptr to this function
                rts

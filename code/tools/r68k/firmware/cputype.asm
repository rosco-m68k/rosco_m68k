;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2022 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; New CPU detection code for firmware, now relying on 
; supported instructions vs the old method (of parsing bus
; error frame types).
;------------------------------------------------------------
;
    include "rosco_m68k_public.asm"
    section .text                     ; This is normal code

; Initialise the CPU type in the SDB. Intended to be called
; directly from INITSDB (and before any video is setup - this
; uses the video area as scratch).
;
INIT_CPU_TYPE::
    movem.l D0-D1/A0,-(A7)            ; Save regs

    move.l  $10,IISAVED               ; Save illegal instruction handler
    move.l  $2C,FLSAVED               ; Save F-line too (for move16 test)
    move.l  #IIHANDLER,$10            ; and install our temporary one...
    move.l  #IIHANDLER,$2C            ; ... to both vectors

    clr.b   IIFLAG                    ; Reset illegal flag
    move.l  #.CONT0,CONTADDR          ; Set up continue address
    clr.w   D0
    mc68010
    movec   D0,VBR                    ; Try to set VBR
    mc68000
.CONT0:
    tst.b   IIFLAG                    ; Was it illegal?
    beq.s   .TRY010                   ; Go on for 010 and up if not...

    clr.l   D0                        ; Else it's an 000
    bra.w   .DONE

.TRY010:
    clr.b   IIFLAG                    ; Reset illegal flag
    move.l  #.CONT1,CONTADDR          ; Set up continue address
    mc68020
    extb    D0                        ; Try EXTB
    mc68000
.CONT1:
    tst.b   IIFLAG                    ; Was it illegal?
    beq.s   .TRY020                   ; Go on for 020 and up if not...

    move.l  #$20000000,D0             ; Else it's an 010
    bra.w   .DONE

.TRY020:
    clr.b   IIFLAG                    ; Reset illegal flag
    move.l  #.CONT2,CONTADDR          ; Set up continue address
    mc68020
    callm   #0,MODULE                 ; Do module call
    mc68000
.CONT2:
    tst.b   IIFLAG                    ; Was it illegal?
    bne.s   .TRY030                   ; Go on for 030 and up if so...

    move.l  #$40000000,D0             ; Else it's an 020
    bra.s   .DONE         

.TRY030:
    clr.b   IIFLAG                    ; Reset illegal flag
    move.l  #.CONT3,CONTADDR          ; Set up continue address
    lea     M16BUF,A0

    ; TODO Once F-Line is properly supported in HW on Pro, this can 
    ; switch to using MOVE16 (and no longer need supervisor mode):
    ;
    ; mc68040
    ; move16  (A0)+,(A0)+               ; Try MOVE16
    ; mc6800
    ;
    ; Will need to invert the branch (to beq) to .TRY040 at that
    ; point!

    mc68030
    pmove   MMUSR,M16BUF              ; Try PMOVE
    mc68000
.CONT3:
    tst.b   IIFLAG                    ; Was it illegal?
    bne.s   .TRY040                   ; Go on for 040 and up if so...

    move.l  #$60000000,D0             ; Else it's an 030
    bra.s   .DONE

.TRY040:
    clr.b   IIFLAG                    ; Reset illegal flag
    move.l  #.CONT4,CONTADDR          ; Set up continue address
    movea.l #M16BUF,A0
    movep.w D0,(0,A0)                 ; Try MOVEP
.CONT4:
    tst.b   IIFLAG                    ; Was it illegal?
    beq.s   .IS040                    ; It's 040 if not

    move.l  #$A0000000,D0             ; Else it's an 060
    bra.s   .DONE

.IS040:
    move.l  #$80000000,D0

.DONE
    move.l  SDB_CPUINFO,D1            ; Get CPUINFO from SDB
    and.l   #$1FFFFFFF,D1             ; Zero high three bits
    or.l    D1,D0                     ; Set them to indicate 010
    move.l  D0,SDB_CPUINFO            ; And update the SDB 

    move.l  IISAVED,$10               ; Restore original handler
    move.l  FLSAVED,$2C               ; for both II and FL

    movem.l (A7)+,D0-D1/A0            ; Restore regs
    rts                               ; And return

MODENTRY:
    dc.w    $7000                     ; Save A7 (essentially no-op)
    mc68020
    rtm     A7                        ; Just return    
    mc68000

IIHANDLER:
    move.b  #1,IIFLAG                 ; Set the flag
    move.l  CONTADDR,(2,A7)           ; Update continue PC
    rte

    section .rodata
MODULE    dc.l    $0                  ; Option 0, Type 0, Rest ignored
          dc.l    MODENTRY            ; Entry word at MODENTRY
SZCPU     dc.b    'MC680', 0

M16BUF    equ     $500
IISAVED   equ     $510
FLSAVED   equ     $514
CONTADDR  equ     $518
IIFLAG    equ     $51C


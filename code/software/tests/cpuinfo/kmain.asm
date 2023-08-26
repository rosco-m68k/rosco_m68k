; *************************************************************
; Copyright (c) 2022 Ross Bamford
; *************************************************************
;
    section .text                     ; This is normal code

kmain::
    move.l  $10,IISAVED               ; Save illegal instruction handler
    move.l  $2C,FLSAVED               ; Save F-line too (for move16 test)
    move.l  #IIHANDLER,$10            ; and install our temporary one...
    move.l  #IIHANDLER,$2C            ; ... to both vectors

    move.l  #.CONT0,CONTADDR          ; Set up continue address
    clr.w   D0
    mc68010
    movec   D0,VBR                    ; Try to set VBR
    mc68000
.CONT0:
    tst.b   IIFLAG                    ; Was it illegal?
    beq.s   .TRY010                   ; Go on for 010 and up if not...

    clr.b   CPUTYPE                   ; Else it's an 000
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

    move.b  #1,CPUTYPE                ; Else it's an 010
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

    move.b  #2,CPUTYPE                ; Else it's an 020
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

    move.b  #3,CPUTYPE                ; Else it's an 030
    bra.s   .DONE

.TRY040:
    clr.b   IIFLAG                    ; Reset illegal flag
    move.l  #.CONT4,CONTADDR          ; Set up continue address
    movea.l #M16BUF,A0
    movep.w D0,(0,A0)                 ; Try MOVEP
.CONT4:
    tst.b   IIFLAG                    ; Was it illegal?
    beq.s   .IS040                    ; It's 040 if not

    move.b  #6,CPUTYPE                ; Else it's an 060
    bra.s   .DONE

.IS040:
    move.b  #4,CPUTYPE

.DONE
    move.l  #17,D0                    ; Function code 17 (PRINTSZ_NUM)
    clr.l   D1                        ; Put CPU type into D1, mul by 10 for display
    move.b  CPUTYPE,D1
    mulu.w  #10,D1
    move.l  #SZCPU,A1                 ; Get prefix string into A1
    trap    #15                       ; And print

    move.l  IISAVED,$10               ; Restore original handler
    move.l  FLSAVED,$2C               ; for both II and FL

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

    section .rodata,text
MODULE    dc.l    $0                  ; Option 0, Type 0, Rest ignored
          dc.l    MODENTRY            ; Entry word at MODENTRY
SZCPU     dc.b    'MC680', 0

    section .bss,bss
M16BUF    ds.l    4
IISAVED   ds.l    1
FLSAVED   ds.l    1
CONTADDR  ds.l    1
IIFLAG    ds.b    1 
CPUTYPE   ds.b    1


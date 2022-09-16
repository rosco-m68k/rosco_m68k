;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2020-2021 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; Stubs for calling SD functions in the EFP from C,
; using the BBSD prototypes from stage 1.
;------------------------------------------------------------
    include "../../../../shared/rosco_m68k_public.asm"

SD_check_support::
    move.l  #0,D0
    trap    #13
    cmp.l   #$1234FEDC,D0
    beq.s   .OK
    move.l  #0,D0
    bra.s   .DONE
.OK
    move.l  #1,D0
.DONE
    rts
    
SD_initialize::
    movem.l A0-A1,-(A7)
    move.l  (12,A7),A1
    move.l  EFP_SD_INIT,A0
    jsr     (A0)
    movem.l (A7)+,A0-A1
    rts

SD_read_block::
    movem.l A0-A2/D1,-(A7)
    move.l  (20,A7),A1
    move.l  (24,A7),D1
    move.l  (28,A7),A2
    move.l  EFP_SD_READ,A0
    jsr     (A0)
    movem.l (A7)+,A0-A2/D1
    rts

SD_write_block::
    movem.l A0-A2/D1,-(A7)
    move.l  (20,A7),A1
    move.l  (24,A7),D1
    move.l  (28,A7),A2
    move.l  EFP_SD_REG,A0
    jsr     (A0)
    movem.l (A7)+,A0-A2/D1
    rts
  
SD_read_register::
    movem.l A0-A2/D1,-(A7)
    move.l  (20,A7),A1
    move.l  (24,A7),D1
    move.l  (28,A7),A2
    move.l  EFP_SD_READ,A0
    jsr     (A0)
    movem.l (A7)+,A0-A2/D1
    rts

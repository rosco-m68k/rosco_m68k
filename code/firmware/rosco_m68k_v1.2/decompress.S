    section .text

decompress_stage2::
    move.l  D2,-(A7)
    movea.l 8(A7),A0
    move.l  #8628,D0
    movea.l #$2000,A1
    move.l  #65536,D1
    jsr     _LZG_Decode
    move    D2,D0
    move.l  (A7)+,D2
    rts

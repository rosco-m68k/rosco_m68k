    section .text

decompress_stage2::
    move.l  D2,-(A7)
    movea.l 8(A7),A0      ; Source address
    move.l  12(A7),D0     ; Source length
    movea.l #$2000,A1     ; Target address
    move.l  #$F0000,D1    ; Arbitrary artifical target limit...
    jsr     _LZG_Decode   ; Do the unzip
    move    D2,D0         ; ... and return the size
    move.l  (A7)+,D2
    rts

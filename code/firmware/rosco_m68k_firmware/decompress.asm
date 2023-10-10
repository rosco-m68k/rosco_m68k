    section .text

decompress_stage2::
    move.l  D2,-(A7)
    movea.l 8(A7),A0            ; Source address
    move.l  12(A7),D0           ; Source length
    movea.l #STAGE2_LOAD,A1     ; Target address
    move.l  #$10000,D1          ; Limit to the top of on-board memory
    jsr     _LZG_Decode         ; Do the unzip
    move    D2,D0               ; ... and return the size
    move.l  (A7)+,D2
    rts

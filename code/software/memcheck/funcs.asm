;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       software v1                 
;------------------------------------------------------------
; Copyright (c)2020 Ross Bamford
; See top-level LICENSE.md for licence information.
;------------------------------------------------------------

    section .text

; Determine CPU type and return in D0.L
;
GET_CPU_ID::
    ; Save regs and setup
    move.l  D1,-(A7)        ; Stash D1
    moveq.l #0,D1           ; Zero it
    move.l  $10,-(A7)       ; Stash existing illegal insn handler
    move.l  #.ILLEGAL,$10   ; and set temporary one up

.CHECK060:
    ; is it an 060?
    ; TODO implement this when it can be tested

.CHECK040:
    ; is it an 040?
    ; TODO implement this when it can be tested

.CHECK030:
    ; is it an 030?
    ; TODO implement this when it can be tested

.CHECK020:
    ; is it an 020 (Does it have cache control register)?
    moveq.l #0,D1           ; Reset illegal instruction flag 
    movec.l CACR,D0         ; Can we read CACR?
    tst.b   D1              ; Was that an illegal instruction?
    bne.s   .CHECK010       ; Yep, go to 010 check...

    move.l  #2,D0           ; Indicate 020...
    bra.s   .DONE           ; ... and bail

.CHECK010:
    ; is it an 010 (Does it have vector base register)?
    moveq.l #0,D1           ; Reset illegal instruction flag 
    movec.l VBR,D0          ; Can we read VBR?
    tst.b   D1              ; Was that an illegal instruction?
    bne.s   .IS000          ; Yep, assume vanilla 68000...

    move.l  #1,D0           ; Indicate 010...
    bra.s   .DONE           ; ... and bail

.IS000
    ; it must be a 68000
    move.l  #0,D0           ; Set return value

.DONE
    move.l  (A7)+,$10       ; Restore illegal insn handler
    move.l  (A7)+,D1        ; Restore D1
    rts                     ; Fin

.ILLEGAL
    move.l  (2,A7),D1       ; Get stacked PC
    addq.l  #4,D1           ; Increment by 4
    move.l  D1,(2,A7)       ; And restack       
    move.b  #1,D1           ; Set flag
    
    rte

BERR_HANDLER::
    move.w  D0,-(A7)
    move.w  ($8,A7),D0                ; Get format
    and.w   #$F000,D0                 ; Mask vector
    cmp.w   #$8000,D0                 ; Is it an 010 BERR frame?
    bne.w   .LFRAME                   ; Assume it's a longer (later CPU) frame if not
                                      ; For 020, this would be either A000 or B000 -
                                      ; for our purposes, they are equivalent. 
                                      ; TODO this might need checking again on later
                                      ; CPUs!

    move.w  ($A,A7),D0                ; If we're here, it's an 010 frame...                
    bset    #15,D0                    ; ... so just set the RR (rerun) flag
    move.w  D0,($A,A7)
    bra.s   .DONE 

.LFRAME:
    move.w  ($C,A7),D0                ; If we're here, it's an 020 frame...                
    bclr    #8,D0                     ; ... we only care about data faults here... Hopefully :D
    move.w  D0,($C,A7)    

.DONE
    move.b  #1,BERRFLAG
    move.w  (A7)+,D0
    rte


INSTALL_BERR_HANDLER::
    move.l  $8,SAVEDHANDLER
    move.l  #BERR_HANDLER,$8
    rts

RESTORE_BERR_HANDLER::
    move.l  SAVEDHANDLER,$8
    rts

    section .data,data
    align   2
SAVEDHANDLER    dc.l  0


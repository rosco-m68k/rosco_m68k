* NOTE! This program will no longer work with the current board design!
*-----------------------------------------------------------
* Title      : Initial ROM test code for rosco_m68k
* Written by : Ross Bamford
* Date       : 2019/05/19
* Description: Runs through IO space, then RAM space, repeatedly. 
*              This should cause bliking lights on prototype board.
*-----------------------------------------------------------
    ORG     $FC0000
    
    dc.l    $FFFFF
    dc.l    $FC0008
    
START:
    move.l  #$FC0000, A1            ; Store top of IO space in A1
    move.l  #$100000, A2            ; Store top of RAM in A2
    or.w    #$0700, SR              ; Disable interrupts

IOINIT:
    movea.l #$F80000, A0            ; Start at bottom of IO space
IOLOOP:
    move.l  (A0)+, D0               ; Read memory
    cmpa.l  A0, A1                  ; Have we reached top of IO space?
    beq.s   RAMINIT                 ; Run through RAM if so
    bra.s   IOLOOP                  ; Otherwise, carry on looping...

RAMINIT:
    movea.l #0, A0                  ; Start at bottom of RAM space
RAMLOOP:
    move.l  (A0)+, D0               ; Read memory
    cmpa.l  A0, A2                  ; Have we reached top of RAM space?
    beq.s   IOINIT                  ; Go back to doing IO if so
    bra.s   RAMLOOP                 ; Otherwise, carry on looping...
    
    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

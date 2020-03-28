* NOTE: This program will no longer work with the current board design!
*
*-----------------------------------------------------------
* Title      : rosco_m68k RAM check
* Written by : Ross Bamford
* Date       : 27/04/2019
* Description: Count actual RAM and put count at bottom of RAM.
*-----------------------------------------------------------
    org     $FC0000
RESET:
    dc.l    $100000     ; Stack (top of on-board RAM)
    dc.l    $FC0008     ; Initial PC (start of ROM)
    
START:
    move.l  #$100000, A0    ; Top of RAM + 1 into loop counter
    move.l  0, D7           ; Use D7 for count

LOOP:    
    move.l  A0, D0          ; Have we reached zero?
    tst.l   D0
    beq.s   HALT            ; Halt if so
    move.b  -(A0), D0       ; Read byte from mem (predecrement A0)
    not.b   D0              ; Negate it
    move.b  D0, (A0)        ; Write it back 
    
    move.b  (A0), D1        ; Read back again
    cmp.l   D0, D1          ; Is it negated?
    bne.s   LOOP            ; Skip following code if not
    
    addi.l  #1, D7          ; Otherwise, add to the count
    bra.s   LOOP            ; Next iteration
         
HALT:
    move.l  D7, $0          ; Store result at bottom of RAM
    stop    #$2700
    
   


    
    END    START        ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

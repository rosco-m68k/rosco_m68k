*-----------------------------------------------------------
* Title      : rosco_m68k RAM test
* Written by : Ross Bamford
* Date       : 27/04/2019
* Description: Fill RAM (backwards) with incrementing longwords, then read them back.
*              This avoids reading potential bus noise as valid data.
*              After a successful RAM test, also runs through IO to give visual feedback
*              on the decoder LEDs.
*              Will halt the CPU on error, loop forever otherwise. 
*-----------------------------------------------------------
    include "equates.x68"
    
    org     $FC0000
RESET:
    dc.l    $100000     ; Stack (top of on-board RAM)
    dc.l    $FC0008     ; Initial PC (start of ROM)
    
START:
    move.l  #$100000, A0    ; Top of RAM + 1 into loop counter
    move.l  #0, D7          ; Use D7 for value

; Init MFP
    move.b  #$01, MFP_DDR   ; Set GPIO 0 to output
    move.b  #$00, MFP_GPDR  ; Turn GPIO 0 on initially
    move.b  #$00, D5        ; D5 stores current value of GPDR  
    
FILLLOOP:
    move.l  D7, -(A0)       ; Write value

    move.l  A0, D0          ; Have we reached zero?
    tst.l   D0
    beq.s   CHECK           ; Start check if so
        
    addi.l  #1, D7          ; Otherwise, increment the value
    bra.s   FILLLOOP        ; and loop
    
CHECK:
    move.l  #$100000, A0    ; Top of RAM + 1 into loop counter
    move.l  #0, D7           ; Use D7 for value
    
CHECKLOOP:
    move.l  -(A0), D0       ; Read value
    
    cmp.l  D0, D7           ; Is value as expected?
    bne.s  HALT             ; Halt if not

    move.l  A0, D0          ; Have we reached zero?
    tst.l   D0
    beq.s   IOINIT          ; Run through IO space if so
        
    addi.l  #1, D7          ; Otherwise, increment the value
    bra.s   CHECKLOOP       ; and loop

; This is here just to have some visual feedback on the decoder LEDs that we're still alive...
IOINIT:
    move.l  #$F80000, A0    ; Start at bottom of IO space
    move.l  #$FC0000, A1    ; Store top of IO space in A1
    
    not.b   D5              ; Toggle GPIO 0...
    move.b  D5, MFP_GPDR    ; ... of the MFP.    
    
IOLOOP:
    move.l  (A0)+, D0       ; Read memory
    cmpa.l  A0, A1          ; Have we reached top of IO space?
    beq.s   START           ; Restart program if so
    bra.s   IOLOOP          ; Otherwise, carry on looping...
    
         
HALT:
    stop    #$2700
    
   


    
    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~

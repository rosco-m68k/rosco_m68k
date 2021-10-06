MFPBASE     equ     $F80000

  ifd REVISION_0
MFP_GPDR    equ     MFPBASE+$01
MFP_IERA    equ     MFPBASE+$31
MFP_IERB    equ     MFPBASE+$09
MFP_ISRB    equ     MFPBASE+$05
  else
MFP_GPDR    equ     MFPBASE+$01
MFP_IERA    equ     MFPBASE+$07
MFP_IERB    equ     MFPBASE+$09
MFP_ISRB    equ     MFPBASE+$11
  endif

    section .text

; Entry point here!
kmain::
    moveq.l   #1,D1                   ; PRINTLN function code
    lea.l     TESTMSG,A0              ; String to print in A0
    trap      #14                     ; Firmware trap

    move.w  #$2700,SR                 ; Disable interrupts
    movea.l #$20000,A0                ; Use $20000 as vector base...
    movec.l A0,VBR                    ; ... and load into VBR
    move.l  #TICK_HANDLER,$20114      ; Set up tick handler
    and.w   #$F2FF,SR                 ; Enable interrupts (except video)

.LOOP
    bra.s   .LOOP

GENERIC_HANDLER:
    rte

TICK_HANDLER:
    move.l  D0,-(A7)                  ; Save D0
    move.w  $408,D0                   ; Read SDB byte 8
    tst.w   D0                        ; Is it zero?
    bne.s   .TICK_HANDLER_DONE        ; Done if not
    
    ; counted to zero, so toggle indicator 0 and reset counter
    bchg.b  #0,MFP_GPDR             
    move.w  #25,D0
    
.TICK_HANDLER_DONE:
    sub.w   #$1,D0                    ; Decrement counter...
    move.w  D0,$408                   ; ... and write back to SDB
    move.l  (A7)+,D0                  ; Restore D0
    move.b  #~$20,MFP_ISRB            ; Clear interrupt-in-service
    rte                               ; We're done

TESTMSG:
    dc.b  "68010-test - Test for 68010 vector base register (VBR)",$D,$A,$D,$A
    dc.b  " - If you have a 68010 the green LED (I0) should flash quickly",$D,$A
    dc.b  " - If you have a 68000 the red LED (I1) should flash in groups of 3",$D,$A,$D,$A

    dc.b  "(reset to restart system)",$D,$A
    dc.b  0

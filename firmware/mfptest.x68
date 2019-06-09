*-----------------------------------------------------------
* Title      : MFP Test for rosco_m68k
* Written by : Ross Bamford
* Date       : 28/04/2019
* Description: Basic machine set-up and prep for a kernel
*-----------------------------------------------------------
    include "equates.x68"
    
    org     ROMBASE
RESET:
    dc.l    RAMLIMIT                    ; 00: Stack (top of on-board RAM)
    dc.l    INIT_PC                     ; 01: Initial PC (start of ROM)
    
VECTORS:
    dc.l    GENERIC_HANDLER             ; 02: Bus Error
    dc.l    GENERIC_HANDLER             ; 03: Address Error
    dc.l    GENERIC_HANDLER             ; 04: Illegal Instruction
    dc.l    GENERIC_HANDLER             ; 05: Divide by Zero
    dc.l    GENERIC_HANDLER             ; 06: CHK Instruction
    dc.l    GENERIC_HANDLER             ; 07: TRAPV Instruction
    dc.l    GENERIC_HANDLER             ; 08: Privilege Violation
    dc.l    GENERIC_HANDLER             ; 09: Trace
    dc.l    GENERIC_HANDLER             ; 0A: Line 1010 Emulator
    dc.l    GENERIC_HANDLER             ; 0B: Line 1111 Emulator
    dc.l    RESERVED_HANDLER            ; 0C: Reserved
    dc.l    RESERVED_HANDLER            ; 0D: Reserved
    dc.l    GENERIC_HANDLER             ; 0E: Format error (MC68010 Only)
    dc.l    GENERIC_HANDLER             ; 0F: Uninitialized Vector
    
    dcb.l   8,RESERVED_HANDLER          ; 10-17: Reserved
    
    dc.l    GENERIC_HANDLER             ; 18: Spurious Interrupt
    
    dcb.l   7,INTERRUPT_HANDLER         ; 19-1F: Level 1-7 Autovectors
    dcb.l   16,TRAP_HANDLER             ; 20-2F: TRAP Handlers
    dcb.l   16,RESERVED_HANDLER         ; Remaining Reserved vectors
    dcb.l   192,UNMAPPED_USER_HANDLER   ; User vectors
    
* First of all, copy the exception table to RAM at 0x0.
* 68010 VBR defaults to that location anyway for 68000 compatibility.
START:
    or.w    #$0700, SR      ; Disable interrupts for now    
    move.l  #START, A0      ; Start into A0 (source)
    move.l  #$400, A1       ; 0x400 into A1 (destination)

ISR_COPY_LOOP:    
    move.l  A1, D0          ; Have we reached destination zero?
    tst.l   D0
    beq.s   ISR_COPY_DONE   ; Halt if so
    
    move.l  -(A0), -(A1)    ; Copy long source to dest, with predecrement.
    bra.s   ISR_COPY_LOOP   ; Next iteration

ISR_COPY_DONE:
* Set up the MFP
* GPIOs
    move.b  #$FF, MFP_DDR   ; All GPIOs are output
    move.b  #$FE, MFP_GPDR  ; Turn on GPIO #0
    
* Timer setup - Timer D controls serial clock
    move.b  #$18, MFP_TDDR  ; Timer D count is 0x18 (24) for 9600 baud
    move.b  #$01, MFP_TCDCR ; Timer D uses /4 prescaler
    
* USART setup
    move.b  #$08, MFP_UCR   ; Fundamental clock, 8N1
    move.b  #$01, MFP_TSR   ; Enable transmitter
    
    lea.l   HELLOWORLD, A0  ; Load message
    lea.l   MESSAGEEND, A1  ; And end of message
    
    bsr.s   PRINT
    
    move.b  #$FC, MFP_GPDR  ; Turn on GPIO #1
        
* And we're done for now.
IDLE:
    stop    #$2300
    bra.s   IDLE

* Subroutines
*
* PRINT expects A0 to point to the start of a message, and A1 to point after last character
PRINT:
    btst.b  #7, MFP_TSR     ; Is buffer empty?
    beq.s   PRINT           ; Busywait if not
    
    move.b  (A0)+, D0       ; Get next character
    move.b  D0, MFP_UDR     ; Give it to the MFP
    cmpa    A1, A0          ; Last character sent?
    bge.s   PRINT           ; Loop if not
    
    rts                     ; We're done
    
* Exception handlers    
GENERIC_HANDLER:
    move.l  #$2BADB105, $404
    rte
    
RESERVED_HANDLER:
    move.l  #$0BADC0DE, $404
    rte
    
UNMAPPED_USER_HANDLER:
    move.l  #$002BAD05, $404
    rte
    
INTERRUPT_HANDLER:
    move.l  #$0BADF00D, $404
    rte

TRAP_HANDLER:
    move.l  #$C001C0DE, $404
    rte

HELLOWORLD      dc.b    'Hello, World!'
MESSAGEEND:
    
    END    START        ; last line of source
  




*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~

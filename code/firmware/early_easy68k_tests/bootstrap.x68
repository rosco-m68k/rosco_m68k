*-----------------------------------------------------------
* Title      : rosco_m68k Hardware Bootstrap
* Written by : Ross Bamford
* Date       : 28/04/2019
* Description: This sets up exception handlers, inits the UART,
*              and sets up MFP Timer C as the system tick.
*              It also sets up the basic System Data Block,
*              prints the new banner over the serial terminal,
*              and then idles, flashing I0 every 100 ticks.
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
    
    dcb.l   7,INTERRUPT_HANDLER         ; 19-1F: Level 1-4 Autovectors
    dcb.l   16,TRAP_HANDLER             ; 20-2F: TRAP Handlers
    dcb.l   16,RESERVED_HANDLER         ; 30-3F: Remaining Reserved vectors
    dcb.l   4,UNMAPPED_USER_HANDLER     ; 40-43: MFP GPIO #0-3 (Not used)
    dc.l    UNMAPPED_USER_HANDLER       ; 44: MFP Timer D (Not used)
    dc.l    TICK_HANDLER                ; 45: MFP Timer C (System tick)
    dcb.l   2,UNMAPPED_USER_HANDLER     ; 46-47: MFP GPIO #4-5 (Not used)
    dc.l    UNMAPPED_USER_HANDLER       ; 48: MFP Timer B (Not used)
    dcb.l   2,UNMAPPED_USER_HANDLER     ; 49-4A: Transmitter status (Not used)
    dcb.l   2,UNMAPPED_USER_HANDLER     ; 4B-4C: Receiver status (Not used)
    dc.l    UNMAPPED_USER_HANDLER       ; 4D: Timer A (Not used)
    dcb.l   2,UNMAPPED_USER_HANDLER     ; 4E-4F: MFP GPIO #6-7 (Not used)
    dcb.l   176,UNMAPPED_USER_HANDLER   ; 50-FF: Unused user vectors
    
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
    bsr.s   INITMFP         ; Initialise MC68901
    bsr.s   INITSDB         ; Initialise System Data Block
    
    bsr.s   PRINT_BANNER

    move.b  #$FD, MFP_GPDR  ; Turn on GPIO #1 (Red LED)  
    and.w   #$F0FF, SR      ; Enable interrupts
        
* And we're done for now.
IDLE:
    stop    #$2300
    bra.s   IDLE

*******************************************************************************
* Subroutines
*
* Show banner
*
* Trashes: D0, MFP_UDR
* Modifies: A0 (Will point to address after null terminator)
PRINT_BANNER:
    lea.l   SZ_BANNER0, A0  ; Load first string into A0
    
    bsr.s   EARLY_PRINTLN   ; Print all the banner lines
    bsr.s   EARLY_PRINTLN   ; This works because EARLY_PRINT
    bsr.s   EARLY_PRINTLN   ; leaves A0 pointing to the next
    bsr.s   EARLY_PRINTLN   ; character in memory ;-)
    bsr.s   EARLY_PRINTLN
    bsr.s   EARLY_PRINTLN
    
    rts                     ; We're done

* PRINT null-terminated string pointed to by A0
*
* Only used during early init; Buffered serial driver will take
* over the UART later on...
*
* Trashes: D0, MFP_UDR
* Modifies: A0 (Will point to address after null terminator)
EARLY_PRINT:
    move.b  (A0)+, D0       ; Get next character
    tst.b   D0              ; Is it null?
    beq.s   _PRINT_DONE     ; ... we're done if so.

_BUFF_WAIT:
    btst.b  #7, MFP_TSR     ; Is transmit buffer empty?
    beq.s   _BUFF_WAIT      ; Busywait if not
    
    move.b  D0, MFP_UDR     ; ... otherwise, give character to the MFP
    bra.s   EARLY_PRINT     ; and loop
_PRINT_DONE:    
    rts                     ; We're done
    
* PRINT null-terminated string pointed to by A0 followed by CRLF.
*
* Only used during early init; Buffered serial driver will take
* over the UART later on...
*
* Trashes: D0, MFP_UDR
* Modifies: A0 (Will point to address after null terminator)
EARLY_PRINTLN:
    bsr.s   EARLY_PRINT     ; Print callers message
    move.l  A0, -(A7)       ; Stash A0 to restore later
    
    lea     SZ_CRLF, A0     ; Load CRLF...
    bsr.s   EARLY_PRINT     ; ... and print it
        
    move.l  (A7)+, A0       ; Restore A0
    rts
    
* Initialise System Data Block
*
INITSDB:
    move.l  #$B105D47A, $400 ; Magic at $400
    move.l  #$C001C001, $404 ; OK OSHI Code at $404
    move.w  #100,       $408 ; Heartbeat flash counter at 100 (1 per second)
    rts

* Initialise MFP
*
* Trashes: D0
* Modifies: MFP Regs
INITMFP:
* GPIOs
    move.b  #$FF, MFP_DDR   ; All GPIOs are output
    
* Timer setup - Timer D controls serial clock, C is kernel tick
    move.b  #$5C, MFP_TCDR  ; Timer C count is 92 for 50Hz
    move.b  #$0C, MFP_TDDR  ; Timer D count is 12 for 19.2KHz
    move.b  #$71, MFP_TCDCR ; Enable timer C with /200 and D with /4 prescaler
    
* USART setup
    move.b  #$08, MFP_UCR   ; Fundamental clock, async, 8N1
    move.b  #$05, MFP_TSR   ; Set pin state high and enable transmitter

* Interrupt setup - Enable timer C interrupt for kernel tick
    move.l  #MFP_VECBASE, D0
    move.b  D0, MFP_VR
    or.b    #$20, MFP_IERB  ; Enable Timer C interrupt...
    move.b  #$20, MFP_IMRB  ; ... and unmask it.
    
* Indicate success and return
    move.b  #$FE, MFP_GPDR  ; Turn on GPIO #0 (Green LED)
    rts

    
*******************************************************************************
* Exception handlers    
TICK_HANDLER:    
    move.w  $408, D0
    tst.l   D0
    bne.s   _MFP_HANDLER_DONE
    
    ; counted to zero, so toggle indicator 0 and reset counter
    bchg.b  #0, MFP_GPDR
    move.w  #100, D0
    
_MFP_HANDLER_DONE:
    sub.l   #$1, D0
    move.w  D0, $408
    rte    
    
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


*******************************************************************************
* Consts 
SZ_BANNER0      dc.b    '                                 ___ ___ _   ', 0
SZ_BANNER1      dc.b    ' ___ ___ ___ ___ ___       _____|  _| . | |_ ', 0
SZ_BANNER2      dc.b    '|  _| . |_ -|  _| . |     |     | . | . | `_|', 0
SZ_BANNER3      dc.b    '|_| |___|___|___|___|_____|_|_|_|___|___|_,_|', 0 
SZ_BANNER4      dc.b    '                    |_____|                  ', 0
SZ_INITDONE     dc.b    'Hardware initialisation complete', 0

SZ_CRLF         dc.b    $D, $A, 0

    END    START        ; last line of source








*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~

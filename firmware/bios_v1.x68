*-----------------------------------------------------------
* Title      : rosco_m68k BIOS v1
* Written by : Ross Bamford
* Date       : 28/04/2019
* Description: Basic machine set-up and prep for a kernel
*-----------------------------------------------------------
    org     $FC0000
RESET:
    dc.l    $FFFFF                      ; 00: Stack (top of on-board RAM)
    dc.l    $FC0400                     ; 01: Initial PC (start of ROM)
    
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
    move.l  #START, A0       ; Here into A0 (source)
    move.l  #$400, A1       ; 0x400 into A1 (destination)

ISR_COPY_LOOP:    
    move.l  A1, D0          ; Have we reached destination zero?
    tst.l   D0
    beq.s   ISR_COPY_DONE   ; Halt if so
    
    move.l  -(A0), -(A1)    ; Copy long source to dest, with predecrement.
    bra.s   ISR_COPY_LOOP   ; Next iteration

ISR_COPY_DONE:
* Now set up the BIOS data block. This is a reserved area of RAM from 0x400
* to 0x500 (256 bytes) that will be used to store assorted stuff.
*
* Currently, it looks like this:
*
*			typedef struct {
*				uint32_t magic;
*				uint32_t oshi_code;
*				uint8_t reserved[248];
*			} __BIOS_DATA_BLOCK;
*   
    move.l  #$B105D47A, $400        
    move.l  #$0,        $404
    
* Test that we can TRAP to our TRAP_HANDLER. Should put 0xC001C0DE in the 
* BDB's oshi_code (at address $404).    
    trap    #$0

* And we're done for now.
    stop    #$2700

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
    
    END    START        ; last line of source
  
*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~

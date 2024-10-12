;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|          firmware
;------------------------------------------------------------
; Copyright (c)2024 The rosco_m68k OSP
; See top-level LICENSE.md for licence information.
;
; General purpose ring buffer.
;------------------------------------------------------------
        
        section .text
        align 2
; ASM callable - pass character in D0, buffer in A2
;
; Arguments:
;
;   A2   - RingBuffer pointer
;   D0.B - The character
;
ring_buffer_char_a::
        movem.l A0/D1-D2,-(A7)                  ; Stash regs
        bsr.s   __internal_ring_buffer_char     ; Call base routine (no saved regs)
        movem.l (A7)+,A0/D1-D2                  ; Restore regs
        rts                                     ; Fin.

__internal_ring_buffer_char::
        lea.l   6(A2),A0                        ; Point A0 to the data buffer
        move.w  2(A2),D1                        ; Get the current write pointer into D1
        move.w  4(A2),D2                        ; Get mask into D2
        move.b  D0,(A0,D1)                      ; Buffer the character
        addi.w  #1,D1                           ; Increment write pointer...
        and.w   D2,D1                           ; ... keep it within range
        move.w  D1,2(A2)                        ; ... and store it back in the struct
        rts                                     ; Fin.

; C-callable - pass RingBuffer pointer and the character to buffer on the stack
;
; void ring_buffer_char(RingBuffer *rb, unsigned char *c)
;
ring_buffer_char::
        movem.l D2/A2,-(A7)                     ; Stash regs
        move.l  12(A7),A2                       ; Load internal buffer into A2
        move.b  19(A7),D0                       ; Load character into D0.B
        bsr.s   __internal_ring_buffer_char     ; Call base routine (no saved regs)
        movem.l (A7)+,D2/A2
        rts


; C-callable - pass RingBuffer pointer and a 1K buffer pointer on the stack. Returns actual count.
;
; uint16_t ring_unbuffer(RingBuffer *rb, uint8_t *outBuffer)
;
ring_unbuffer::
        movem.l D2-D4,-(A7)
        move.w  SR,D4                           ; Save SR
        or.w    #$0700,SR                       ; No interrupts for a bit

        move.l  16(A7),A0                       ; Load internal buffer into A0
        move.l  20(A7),A1                       ; Load out buffer into A1
        clr.l   D0                              ; Zero return value

        move.w  (A0)+,D1                        ; D1 is R pointer
        move.w  (A0)+,D2                        ; D2 is W pointer
        move.w  (A0)+,D3                        ; D3 is mask

.loop
        cmp.w   D2,D1                           ; Are pointers equal?
        beq.s   .done                           ; Leave now if so...

        move.b  (A0,D1),(A1)+                   ; Copy byte into out buffer
        addi.w  #1,D0                           ; Increment return value (count)
        addi.w  #1,D1                           ; Increment read pointer...
        and.w   D3,D1                           ; ... and wrap is > size
        bra.s   .loop                           ; Let's go again!

.done:
        move.l  16(A7),A0                       ; Re-fetch RingBuffer pointer
        move.w  D1,(A0)                         ; Store updated read pointer
        move.w  D4,SR                           ; Re-enable interrupts
        movem.l (A7)+,D2-D4
        rts


; C-callable - pass RingBuffer pointer and a byte buffer pointer on the stack. Returns actual count.
;
; uint16_t ring_unbuffer_char(RingBuffer *rb, uint8_t *outBuffer)
;
ring_unbuffer_char::
        movem.l D2-D4,-(A7)
        move.w  SR,D4                           ; Save SR
        or.w    #$0700,SR                       ; No interrupts for a bit

        move.l  16(A7),A0                       ; Load internal buffer into A0
        move.l  20(A7),A1                       ; Load out buffer into A1
        clr.l   D0                              ; Zero return value

        move.w  (A0)+,D1                        ; D1 is R pointer
        move.w  (A0)+,D2                        ; D2 is W pointer
        move.w  (A0)+,D3                        ; D3 is mask

        cmp.w   D2,D1                           ; Are pointers equal?
        beq.s   .done                           ; Leave now if so...

        move.b  (A0,D1),(A1)+                   ; Copy byte into out buffer
        addi.w  #1,D0                           ; Increment return value (count)
        addi.w  #1,D1                           ; Increment read pointer...
        and.w   D3,D1                           ; ... and wrap is > size

        move.l  16(A7),A0                       ; Re-fetch RingBuffer pointer
        move.w  D1,(A0)                         ; Store updated read pointer
.done:
        move.w  D4,SR                           ; Re-enable interrupts
        movem.l (A7)+,D2-D4
        rts


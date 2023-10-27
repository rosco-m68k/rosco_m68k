;*
;*------------------------------------------------------------
;*                                  ___ ___ _
;*  ___ ___ ___ ___ ___       _____|  _| . | |_
;* |  _| . |_ -|  _| . |     |     | . | . | '_|
;* |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;*                     |_____|            kernel
;* ------------------------------------------------------------
;* Copyright (c)2023 Ross Bamford and contributors
;* See top-level LICENSE.md for licence information.
;*
;* General bitmap
;* ------------------------------------------------------------
;*

  section .text
  
; void bitmap_set_c(uint32_t *bitmap, uint32_t bit);
bitmap_set_c::
  move.l    4(a7),a1                      ; Get bitmap into a1
  move.l    8(a7),d0                      ; And bit # into d0

; Set a bit.
;
; Arguments:
;   a1      - The bitmap
;   d0      - Bit number
;
; Modifies:
;   nothing
;
bitmap_set::
  move.l    d1,-(a7)                      ; Stash regs
  move.l    d0,-(a7)

  move.l    #1,d1                         ; Start with one
  and.l     #$1f,d0                       ; Mask bit number to 5-bits
  lsl.l     d0,d1                         ; And shift left into a bit mask

  move.l    (a7),d0                       ; Restore d0 (don't pop)
  lsr.l     #5,d0                         ; Shift it right by 5 to get long index
  lsl.l     #2,d0                         ; And left again to get byte index

  or.l      d1,(a1,d0.l)                  ; Set the bit

  move.l    (a7)+,d0                      ; And we're done!  
  move.l    (a7)+,d1
  rts


; void bitmap_clear_c(uint32_t *bitmap, uint32_t bit);
bitmap_clear_c::
  move.l    4(a7),a1                      ; Get bitmap into a1
  move.l    8(a7),d0                      ; And bit # into d0

; Clear a bit.
;
; Arguments:
;   a1      - The bitmap
;   d0      - Bit number
;
; Modifies:
;   nothing
;
bitmap_clear::
  move.l    d1,-(a7)                      ; Stash regs
  move.l    d0,-(a7)

  move.l    #1,d1                         ; Start with one
  and.l     #$1f,d0                       ; Mask bit number to 5-bits
  lsl.l     d0,d1                         ; And shift left into a bit mask
  not.l     d1

  move.l    (a7),d0                       ; Restore d0 (don't pop)
  lsr.l     #5,d0                         ; Shift it right by 5 to get long index
  lsl.l     #2,d0                         ; And left again to get byte index
  
  and.l     d1,(a1,d0.l)                  ; Clear the bit
  
  move.l    (a7)+,d0                      ; And we're done!  
  move.l    (a7)+,d1
  rts

; void bitmap_flip_c(uint32_t *bitmap, uint32_t bit);
bitmap_flip_c::
  move.l    4(a7),a1                      ; Get bitmap into a1
  move.l    8(a7),d0                      ; And bit # into d0

; Flip a bit.
;
; Arguments:
;   a1      - The bitmap
;   d0      - Bit number
;
; Modifies:
;   nothing
;
bitmap_flip::
  move.l    d1,-(a7)                      ; Stash regs
  move.l    d0,-(a7)

  move.l    #1,d1                         ; Start with one
  and.l     #$1f,d0                       ; Mask bit number to 5-bits
  lsl.l     d0,d1                         ; And shift left into a bit mask

  move.l    (a7),d0                       ; Restore d0 (don't pop)
  lsr.l     #5,d0                         ; Shift it right by 5 to get long index
  lsl.l     #2,d0                         ; And left again to get byte index
  
  eor.l     d1,(a1,d0.l)                  ; Flip the bit
  
  move.l    (a7)+,d0                      ; And we're done!  
  move.l    (a7)+,d1
  rts


; int32_t bitmap_find_clear_c(uint32_t bitmap);
bitmap_find_clear_c::
  move.l    4(a7),d1

; Find a clear bit in a 32-bit number.
;
; The algorithm is a binary search for a byte with a clear bit, 
; then an unrolled loop through the bits in that byte to 
; find a clear bit. 
;
; I went this way to try and minimise the number of shifts (6+2n
; cycles) in the average case - trying to reduce cycle count and
; hopefully speed - but it needs benchmarking.
;
; The naive shift-and-test method is 160 cycles on shifts in the
; average case. A table would be fastest, but too big. There are
; various other methods which use more shifts and/or bitwise, but
; I think they'd all take more cycles.
;
; Again though, could do with actual calculation / testing vs
; the back-of-an-envelope calcs I've done currently 🤣
;
; The absolute worst-case for this is if no bits are free. In
; the slab alloc, this should never happen, because we use 
; separate lists for free and partial.
;
; The next worst case is bit 31 being free, which again will never
; happen in slab - that block is the slab metadata.
;
; **Note**: The public API does not guarantee ordering. However,
; this starts from LSB, and find_n_clear relies on this - so if
; this is changed, n_clear will need changing too!
;
; Arguments:
;   d1      - The bitmap
;
; Modifies:
;   d0      - Clear bit, or -1 if none (return value)
;   d1      - trashed
;
bitmap_find_clear::
  ; Check low word
  clr.l     d0                            ; Zero d0 for result
  cmp.w     #$FFFF,d1                     ; Is the low word all set?
  beq       .not_lw                       ; Go check high word if so

  ; Check low byte
  cmp.b     #$FF,d1                       ; otherwise, is the low byte all set?
  beq       .is_lw_not_lb                 ; go check high byte if so

  ; Clear bit in low word, low byte
  bra       .find_bit_in_byte             ; else, find clear bit in the low byte

.is_lw_not_lb:
  ; Clear bit in low word, high byte
  moveq.l   #8,d0                         ; Add 8 to d0 as starting bit num
  lsr.l     #8,d1                         ; Shift right by 8 for bit checking
  bra       .find_bit_in_byte             ; and check it

.not_lw:
  ; Not the low word - clear bit in high word
  moveq.l   #16,d0                        ; Add 16 to d0 as starting bit num
  lsr.l     #8,d1                         ; Shift right by 8...
  lsr.l     #8,d1                         ; ... plus 8 for 16

  ; Check low byte
  cmp.b     #$FF,d1                       ; is the low byte all set?
  beq       .is_hw_not_lb                 ; go check high byte if so

  ; Clear bit in low word, low byte
  bra       .find_bit_in_byte             ; else, go check low byte

.is_hw_not_lb:
  ; Clear bit in high word, high byte
  moveq.l   #24,d0                        ; Add 24 to d0 as starting bit num
  lsr.l     #8,d1                         ; shift right by another 8 for bit checking

; This looks for a free bit in the low byte of d1, and returns the bit num,
; or -1 if no free bits (which should never be the case in the real world).
;
.find_bit_in_byte:
  btst      #0,d1                         ; This is just an unrolled loop over the bits
  bne       .not_bit_zero                 ; which should be a tad quicker than looping
  rts

.not_bit_zero
  btst      #1,d1
  beq       .bit1

  btst      #2,d1
  beq       .bit2

  btst      #3,d1
  beq       .bit3

  btst      #4,d1
  beq       .bit4

  btst      #5,d1
  beq       .bit5

  btst      #6,d1
  beq       .bit6

  btst      #7,d1
  beq       .bit7

  move.l    #-1,d0
  rts

.bit1:
  addq.l    #1,d0
  rts

.bit2:
  addq.l    #2,d0
  rts

.bit3:
  addq.l    #3,d0
  rts

.bit4:
  addq.l    #4,d0
  rts

.bit5:
  addq.l    #5,d0
  rts

.bit6:
  addq.l    #6,d0
  rts

.bit7:
  addq.l    #7,d0
  rts


; int32_t bitmap_find_n_clear_c(uint32_t bitmap, uint8_t n);
bitmap_find_n_clear_c::
  move.l    4(a7),d1                      ; Get bitmap into d1
  move.l    8(a7),d0                      ; And n into d0

; Find a block of n contiguous clear bits in a 32-bit number.
;
; The algorithm is to `or` the bitmap with itself n times, 
; shiting right by one bit each time, and then looking for
; the first clear bit, which will be the lowest bit in a run
; of n bits.
;
; Not _massively_ efficient, but fine for small n values, which
; is all we'll realistically use it for (in the slab alloc).
;
; Arguments:
;   d0      - n
;   d1      - The bitmap
;
; Modifies:
;   d0      - Clear bit, or -1 if none (return value)
;   d1      - trashed
;
bitmap_find_n_clear::
  move.l    d2,-(a7)                      ; stash registers
  move.l    d1,d2                         ; copy n into d2 for shifting

  subi.b    #1,d0                         ; loop one less than n
  bra       .loop_start                   ; dbra induction 😊
.loop:
  lsr.l     d2                            ; shift d2 right by 1 position
  ori.l     #$80000000,d2                 ; always set high bit
  or.l      d2,d1                         ; or with the bitmap
.loop_start:
  dbra      d0,.loop                      ; loopity-loop

  bsr       bitmap_find_clear             ; Now, lowest bit is the start of a block of n 🥳
  move.l    (a7)+,d2                      ; restore regs
  rts

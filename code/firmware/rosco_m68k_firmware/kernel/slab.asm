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
;* Your basic slab allocator.
;* 
;* Manages slabs of 1KiB, which are split into blocks of
;* 32 bytes (for 32 blocks per slab).
;* ------------------------------------------------------------
;*

  section .text
  
; TODO all these should probably be in include files....
; they're bound to get out of step otherwise, which will be fun to debug 😅
;
LIST_NEXT   equ     $00                   ; These need to be kept in-step with
                                          ; values in list.h!

SLAB_BASE   equ     $10                   ; These need to be kept in-step with
SLAB_BMP    equ     $14                   ; values in slab.h!

NODE_NEXT   equ     $00                   ; These need to be kept in-step with
NODE_PREV   equ     $04                   ; values in list.h!
NODE_SIZE   equ     $08
NODE_TYPE   equ     $0C

NODE_TYPE_SLAB    equ     $200            ; Also in slab.h 🙄
SLAB_SIZE         equ     $400            ; 1KiB slabs
SLAB_META_START   equ     $3e0            ; Metadata in top block
SLAB_INIT_BMP     equ     $80000000       ; Initial slab bitmap - top block for metadata
SLAB_BASE_MASK    equ     $fffffc00

; Initialise the slab system.
;
; Must be called before using other functions.
; Slab depends on pmm, so before anything else
; is used, that must be initialized too.
;
slab_init::
  move.l    a0,-(a7)
  move.l    #partial_slabs,a0
  bsr       list_init
  move.l    #full_slabs,a0
  bsr       list_init
  move.l    (a7)+,a0
  rts


; void*   slab_alloc_c(uint8_t block_count);
slab_alloc_c::
  move.l  4(a7),d0

; Arguments:
;   d0    - block count
;
; Modififies:
;   a0    - trashed
;   d0    - address of (first) block - return value
;   d1    - trashed
;
slab_alloc::
  tst.b     d0                            ; Quick check - is d0 null?
  beq       .just_return                  ; just bail now if so...
  cmp.b     #31,d0                        ; Quick check - is d0 >31?
  bhi       .just_return_0                ; just bail now if so...

  move.l    d2,-(a7)                      ; Save regs
  move.l    a1,-(a7)
  jsr       disable_interrupts            ; disable interrupts while we fiddle with lists

  move.l    #partial_slabs,a0             ; Do we have a partial slab to use?
  move.l    LIST_NEXT(a0),a0              ; Check next pointer of head
  move.b    d0,d2                         ; Requested block count lives in d2

  ; Is there a slab with enough free contiguous blocks in the list?
  ; TODO is it worth optimizing this by keeping the list sorted by free count?
.loop
  cmp.l     #partial_tail,a0              ; Are we pointing to the list tail?
  beq       .alloc_slab                   ; If so, we'll need a new slab

  move.b    d2,d0                         ; Else, check this one. Free count into d0
  move.l    SLAB_BMP(a0),d1               ; Checking this slab's bitmap
  bsr       bitmap_find_n_clear           
  cmp.b     #-1,d0                        ; Did we find a slab?
  bne       .found                        ; Go work with that one if so

  move.l    LIST_NEXT(a0),a0              ; try next slab...
  bra       .loop                         ; ... and loop

.found:
  move.l    a0,a1                         ; a1 points to start of metadata
  sub.l     #SLAB_META_START,a0           ; a0 points to start of slab
  bra       .alloc_block                  ; and allocate block

.alloc_slab:
  ; No partial slab with enough space - alloc a new slab
  move.l    #SLAB_SIZE,-(a7)              ; Allocate a 1KiB block...
  bsr       pmm_alloc                     ; ...from the pmm
  add.l     #4,a7                         ; ... and cleanup stack

  tst.l     d0                            ; Did we get a NULL block from the pmm?
  beq       .nomem                        ; if so, fail fast, nothing we can do...

  move.l    d0,a1                         ; Else, mem pointer into a1
  add.l     #SLAB_META_START,a1           ; a1 points to start of last block in the slab for metadata

  move.l    #NODE_TYPE_SLAB,NODE_TYPE(a1) ; Set up type field
  move.l    #SLAB_SIZE,NODE_SIZE(a1)      ; and size field (whole slab size)
  move.l    d0,SLAB_BASE(a1)              ; Set up slab base address
  move.l    #SLAB_INIT_BMP,SLAB_BMP(a1)   ; And bitmap (top block always allocated to metadata)

  move.l    #partial_slabs,a0             ; Partial list head into a0
  bsr       list_add_head                 ; And add the new slab at head

  move.l    a1,a0                         ; a0 points to slab
  sub.l     #$3e0,a0                      ; back to beginning
  clr.l     d0                            ; and d0 points to block zero

.alloc_block:
  ; Here:
  ;    a0 - points to start of slab
  ;    a1 - points to start of slab metadata
  ;    d0 - Start of our free block
  ;    d2 - Number of blocks requested
  ;
  move.b    d2,d1                         ; Blocks requested is loop counter
  move.l    d0,-(a7)                      ; Stash free block while we set bits
  add.l     #SLAB_BMP,a1                  ; a1 points to bitmap  

.mark_loop:
  tst.b     d1                            ; Is counter zero?
  beq       .mark_done                    ; If so, done

  bsr       bitmap_set                    ; Mark this block as used
  addq.l    #1,d0                         ; Move to next bit
  subq.l    #1,d1                         ; Decrement counter
  bra       .mark_loop                    ; loop!

.mark_done:
  cmp.l     #$ffffffff,(a1)               ; Is this slab full?
  bne       .return_addr                  ; skip moving it to the full list if not

  move.l    a0,-(a7)                      ; Need to move the slab, so stash the start address
  sub.l     #SLAB_BMP,a1                  ; Point a1 back to start of metadata

  move.l    #partial_slabs,a0             ; Remove from partial list
  bsr       list_delete_head

  move.l    #full_slabs,a0                ; Add to full list
  bsr       list_add_head

  move.l    (a7)+,a0                      ; Restore a0 to start of block

.return_addr
  move.l    (a7)+,d0                      ; Restore d0
  lsl.l     #5,d0                         ; multiply by 32
  add.l     a0,d0                         ; And add block start to get final address

  move.l    (a7)+,a1                      ; Restore regs
  move.l    (a7)+,d2
  jsr       enable_interrupts             ; Re-enable interrupts
  rts                                     ; And done

.nomem:
  jsr       enable_interrupts             ; No memory - re-enable interrupts
  move.l    (a7)+,a1                      ; restore regs
  move.l    (a7)+,d2

.just_return_0:
  clr.l     d0                            ; Set return to null

.just_return:
  rts                                     ; and bail


; void    slab_free_c(void* addr, uint8_t block_count);
slab_free_c::
  move.l    4(a7),a0
  move.l    8(a7),d1

; Arguments:
;   a0    - Address of (first) block
;   d1    - block count
;
; Modififies:
;   a0    - trashed
;   d0    - trashed
;
slab_free::
  move.l    a1,-(a7)                      ; Save regs
  move.l    d1,-(a7)

  move.l    a0,d0                         ; Block address into d0
  and.l     #SLAB_BASE_MASK,d0            ; Get slab base address
  move.l    d0,a1                         ; Put that into a1

  move.l    a0,d0                         ; Block address into d1
  sub.l     a1,d0                         ; Subtract block start
  lsr.l     #5,d0                         ; Divide by 32 for first block number

  add.l     #SLAB_BMP+SLAB_META_START,a1  ; Point a1 to slab bitmap in metadata
  
  jsr       disable_interrupts            ; disable interrupts for bit

.mark_loop:
  tst.l     d1                            ; Is counter zero?
  beq       .mark_done                    ; If so, done

  bsr       bitmap_clear                  ; Mark this block as free
  addq.l    #1,d0                         ; Move to next bit
  subq.l    #1,d1                         ; Decrement counter
  bra       .mark_loop                    ; loop!

.mark_done:
  cmp.l     #SLAB_INIT_BMP,(a1)           ; Is this slab now empty?
  bne       .done                         ; We're done if not...

  sub.l     #SLAB_BMP,a1                  ; otherwise, a1 back to start of slab metadata
  move.l    a1,a0                         ; Node into a0
  bsr       list_node_delete              ; delete the node from the list
  sub.l     #SLAB_META_START,a1           ; point a1 back to start of slab
  move.l    #SLAB_SIZE,-(a7)              ; Stack the size for pmm call
  move.l    a1,-(a7)                      ; Stack the slab start address for pmm call
  bsr       pmm_free                      ; free it
  add.l     #8,a7                         ; Tidy up stack

.done:
  jsr       enable_interrupts             ; re-enable interrupts
  move.l    (a7)+,d1                      ; restore regs
  move.l    (a7)+,a1
  rts

  section .bss
partial_slabs::
partial_head:     ds.l    1
partial_tail:     ds.l    2

full_slabs::
full_head:        ds.l    1
full_tail:        ds.l    2


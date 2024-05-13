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
;* Doubly-linked list for ROM kernel. 
;* ------------------------------------------------------------
;*

  section .text
  
LIST_HEAD   equ     $00                   ; These need to be kept in-step with
LIST_TAIL   equ     $04                   ; the structs in list.h!
LIST_TPREV  equ     $08

NODE_NEXT   equ     $00
NODE_PREV   equ     $04
NODE_SIZE   equ     $08
NODE_TYPE   equ     $0C

; ListNode* list_node_insert_after_c(ListNode *target, ListNode *subject);
;
list_node_insert_after_c::
  move.l    4(a7),a0                      ; Argument 0 (target) into a0
  move.l    8(a7),a1                      ; Argument 1 (subject) into a1
  bsr       list_node_insert_after        ; Call assembly routine
  move.l    a1,d0                         ; Result in d0 for C
  rts                                     ; Fin


; Arguments:
;   a0    - Target node
;   a1    - Subject node
;
; Modifies:
;   a1    - Added node
;   d0    - trashed
;
list_node_insert_after::
  cmp.l     #$0,a0                        ; Is the target NULL?
  beq       .link_subject                 ; Just link the subject if so

  move.l    NODE_NEXT(a0),d0              ; Else, target existing next into d0
  move.l    a1,NODE_NEXT(a0)              ; And set subject as target next

.link_subject:
  cmp.l     #$0,a1                        ; Is the subject NULL?
  beq       .done                         ; Nothing more to do if so

  move.l    d0,NODE_NEXT(a1)              ; Else, set existing target next as subject next
  move.l    a0,NODE_PREV(a1)              ; And set target as the subject previous

  tst.l     d0                            ; Was target next NULL?
  beq       .done                         ; Done if so

  move.l    d0,a0                         ; Else, target next into a0
  move.l    a1,NODE_PREV(a0)              ; and set its previous to the subject

.done:
  rts                                     ; Fin
  

; ListNode* list_node_add_c(ListNode *head, ListNode *subject);
;
list_node_add_c::
  move.l    4(a7),a0                      ; Argument 0 (target) into a0
  move.l    8(a7),a1                      ; Argument 1 (subject) into a1
  bsr       list_node_add                 ; Call assembly routine
  move.l    a1,d0                         ; Result in d0 for C
  rts                                     ; Fin


; Arguments:
;   a0    - Target head node
;   a1    - Subject node
;
; Modifies:
;   a1    - Added node
;   d0    - trashed
;
list_node_add::
  cmp.l     #$0,a0                        ; Is target NULL?
  beq       .found_end                    ; We've "found the tail" if so...

.loop:                                    ; Otherwise we need to loop...
  move.l    NODE_NEXT(a0),d0              ; get current target next into d0
  beq       .found_end                    ; If NULL, we've found the tail if so (in a0)
  move.l    d0,a0                         ; Else, update current to next...
  bra       .loop                         ; ... and continue testing.

.found_end:
  bra       list_node_insert_after        ; Now the tail is in a0, so just insert


; ListNode* list_node_delete_c(ListNode *subject);
;
list_node_delete_c::
  move.l    4(a7),a0                      ; Argument 0 (subject) into a0
  bsr       list_node_delete              ; Call assembly routine
  move.l    a1,d0                         ; Result in d0 for C
  rts                                     ; Fin


; Arguments:
;   a0    - Subject node
;
; Modifies:
;   a1    - Deleted subject node
;
list_node_delete::
  cmp.l     #$0,a0                        ; Is subject NULL?
  bne       .delete                       ; If not, do the delete

  move.l    #$0,a1                        ; Else, just NULL out the return
  rts                                     ; and quit.

.delete:
  move.l    a2,-(a7)                      ; Save a2
  move.l    NODE_PREV(a0),a1              ; Node prev into a1
  move.l    NODE_NEXT(a0),a2              ; Next node into a2

  cmp.l     #$0,a1                        ; Is prev NULL?
  beq       .setupnext                    ; Skip setting previous node's next if so...
  move.l    a2,NODE_NEXT(a1)              ; Else, set previous node's next to this one's next

.setupnext:
  cmp.l     #$0,a2                        ; Is next NULL?
  beq       .finishup                     ; Skip setting next node's previous if so...
  move.l    a1,NODE_PREV(a2)              ; Set next node's previous to this one's previous

.finishup
  move.l    (a7)+,a2                      ; restore a2
  move.l    a0,a1                         ; And return in a1 for consistency...
  rts                                     ; Fin


; List* init_list_c(List* the_list);
;
; Modifies:
;   d0    - Return
;
list_init_c::
  move.l    4(a7),a0                      ; List* argument into a0
  move.l    a0,d0                         ; Set up return now
  bra       list_init                     ; And just jump to assembly func
  
  
; Arguments:
;
;   a0    - The list struct to initialize
;
; Modifies:
;   nothing
;
list_init::
  move.l    a1,-(a7)                      ; Save a1...
  lea       4(a0),a1                      ; ... and use it to store tail node pointer
  move.l    a1,LIST_HEAD(a0)              ; move tail node pointer into head node next
  move.l    #0,LIST_TAIL(a0)              ; zero out head node prev / tail node next
  move.l    a0,LIST_TPREV(a0)             ; move head node pointer into tail node prev
  move.l    (a7)+,a1                      ; restore a1
  rts                                     ; and done.

  
; ListNode* list_add_head_c(List* target, ListNode *subject);
;
; Modifies:
;   d0    - Return
;
list_add_head_c::
  move.l    4(a7),a0                      ; Target List argument into a0
  move.l    8(a7),a1                      ; Subject node argument into a1
  bsr       list_add_head                 ; Call assembly func
  move.l    a1,d0                         ; Fix up return
  rts                                     ; done.
  
  
; Arguments:
;
;   a0    - The target List*
;   a1    - The subject ListNode*
;
; Modifies:
;   nothing
;
list_add_head::
  bra       list_node_insert_after        ; This is just a node_insert_after the head node...
                                          ; Kinda pointless having the extra branch tbf... 🤷


; ListNode* list_delete_head_c(List* target);
;
; Modifies:
;   d0    - Return
;
list_delete_head_c::
  move.l    4(a7),a0                      ; Target List into a0
  bsr       list_delete_head              ; Call assembly func
  move.l    a1,d0                         ; Fix up return
  rts                                     ; Bye!
  
  
; Arguments:
;
;   a0    - The target List*
;
; Modifies:
;   a1    - Returns the deleted node
;
list_delete_head::
  move.l    NODE_NEXT(a0),a0              ; Move to first node
  tst.l     NODE_NEXT(a0)                 ; Is it the tail node?
  bne       list_node_delete              ; If not, do a node_delete

  move.l    #0,a1                         ; Else, just return NULL
  rts                                     ; and done.


; ListNode* list_add_tail_c(List* target, ListNode *subject);
;
; Modifies:
;   d0    - Return
;
list_add_tail_c::
  move.l    4(a7),a0                      ; Target list arg into a0
  move.l    8(a7),a1                      ; Subject node arg into a1
  bsr       list_add_tail                 ; Call assembly func
  move.l    a1,d0                         ; Fix up return
  rts                                     ; Fin
  
  
; Arguments:
;
;   a0    - The target List*
;   a1    - The subject ListNode*
;
; Modifies:
;   a0    - Trashed
;   d0    - Trashed
;
list_add_tail::
  add.l     #4,a0                         ; Point a0 to tail node
  move.l    NODE_PREV(a0),a0              ; And rewind to previous
  bra       list_node_insert_after        ; Just do a node_insert_after...


; ListNode* list_delete_tail_c(List* target);
;
; Modifies:
;   d0    - Return
;
list_delete_tail_c::
  move.l    4(a7),a0                      ; Target List into a0
  bsr       list_delete_tail              ; Call assembly func
  move.l    a1,d0                         ; Fix up return
  rts                                     ; Done
  
  
; Arguments:
;
;   a0    - The target List*
;
; Modifies:
;   a1    - Returns the deleted node
;
list_delete_tail::
  add.l     #4,a0                         ; Point a0 to tail node
  move.l    NODE_PREV(a0),a0              ; Move to previous node
  tst.l     NODE_PREV(a0)                 ; Is is the head node?
  bne       list_node_delete              ; If not, delete it

  move.l    #0,a1                         ; Else, just return NULL
  rts                                     ; done.

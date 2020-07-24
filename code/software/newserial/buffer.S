    section   .text

WRITEPTR    equ   $100
READPTR     equ   $101

; Buffers are 256 bytes of data plus two bytes for pointers
; Structure of a buffer is:
;
; 0 .. 0xFF - Data
; 0x100     - Write pointer
; 0x101     - Read pointer


; Write to buffer
;
; Arguments:
;   A0   - Buffer
;   D0.B - Character to write
; 
; Trashes:
;   D1
;
BUFFER_WRITE::
    clr.l     D1
    move.b    WRITEPTR(A0),D1
    move.b    D0,(A0,D1)
    addq.b    #1,D1
    move.b    D1,WRITEPTR(A0)
    rts
   

; Is character available?
;
; No internal checking is done for this, so you 
; should use this before reading...
;
; Arguments:
;   A0   - Buffer
;
; Modifies:
;   D0.B - Return, 0 if empty, nonzero if not
;
; Trashes:
;   D1
;
BUFFER_AVAIL::
    move.b    WRITEPTR(A0),D0
    move.b    READPTR(A0),D1
    sub.b     D1,D0
    rts


; Unconditionally read from buffer
;
; Note: This does no checking whether it makes sense
; to read (i.e. if a character is available) and will
; always read and increment the read pointer.
;
; The code that uses this must always check BUFFER_AVAIL
; first!
;
; Arguments
;   A0    - Buffer
;
; Modifies:
;   D0.B  - Return, character (or garbage if none).
;
; Trashes:
;   D1
;
BUFFER_READ::
    clr.l     D1
    move.b    READPTR(A0),D1
    move.b    (A0,D1),D0
    addq.b    #1,D1
    move.b    D1,READPTR(A0)
    rts


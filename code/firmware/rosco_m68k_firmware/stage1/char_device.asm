;------------------------------------------------------------
;                                  ___ ___ _   
;  ___ ___ ___ ___ ___       _____|  _| . | |_ 
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2023 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; Low-level support routines for character devices.
;------------------------------------------------------------

    section .text

GET_CHAR_DEVICE_COUNT::
    move.w  DEVICE_COUNT,D0
    rts

; **********************************
GET_CHAR_DEVICE::
    cmp.w   DEVICE_COUNT,D0
    bhs.s   .NO_DEVICE

    lea.l   DEVICE_BLOCKS,A1
    lsl.w   #5,D0
    add.w   D0,A1

    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+
    move.l  (A1)+,(A0)+

    move.b  #1,D0
    rts

.NO_DEVICE
    clr.b   D0
    rts
; **********************************

ADD_CHAR_DEVICE::
    move.w  DEVICE_COUNT,D0
    cmp.w   #15,D0
    bhi.w   .EPILOGUE

    lea.l   DEVICE_BLOCKS,A1
    lsl.w   #5,D0
    add.w   D0,A1

    ; Copy 32 bytes of device struct
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+
    move.l  (A0)+,(A1)+

    addi.w  #1,DEVICE_COUNT
    lsr.w   #5,D0               ; Re-shift for return value
.EPILOGUE:
    rts

; **********************************

CHAR_DEV_RECVCHAR::
    move.l  8(A0),A1
    jsr     (A1)
    rts

CHAR_DEV_SENDCHAR::
    move.l  12(A0),A1
    jsr     (A1)
    rts

CHAR_DEV_CHECKCHAR::
    move.l  4(A0),A1
    jsr     (A1)
    rts

CHAR_DEV_CTRL::
    move.l  24(A0),A1
    jsr     (A1)
    rts

; Get character device from C
;
; Trashes: D0
; Modifies: A0 (return)
GET_CHAR_DEVICE_C::
    move.l  D1,-(A7)
    move.l  8(A7),D0
    move.l  12(A7),A0
    jsr     GET_CHAR_DEVICE
    move.l  (A7)+,D1
    rts


; Call device check function from C
;
; Trashes: A0
; Modifies: D0 (return)
CHAR_DEV_CHECKCHAR_C::
    move.l  D1,-(A7)
    move.l  8(A7),A0
    jsr     CHAR_DEV_CHECKCHAR
    move.l  (A7)+,D1
    rts


; Call device receive function
;
; Trashes: A0
; Modifies: D0 (return)
CHAR_DEV_RECVCHAR_C::
    move.l  D1,-(A7)
    move.l  8(A7),A0
    jsr     CHAR_DEV_RECVCHAR
    move.l  (A7)+,D1
    rts


; Call device send function
;
; Trashes: D0, A0
; Modifies: Nothing
CHAR_DEV_SENDCHAR_C::
    move.l  D1,-(A7)
    move.l  8(A7),D0
    move.l  12(A7),A0
    jsr     CHAR_DEV_SENDCHAR
    move.l  (A7)+,D1
    rts    
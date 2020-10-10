;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|       firmware v1
;------------------------------------------------------------
; Copyright (c)2020 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; Block device IO - assembly parts
;------------------------------------------------------------
    include "../../../shared/equates.S"
    include "equates.S"
    section .text

TRAP_13_VECTOR      equ     $2D
TRAP_13_VECTOR_ADDR equ     TRAP_13_VECTOR*4

; TRAP 13 provides access to block device IO (SD Card currently)
;
; D0 is expected to contain the task number (function code). Other arguments
; depend on the specific function - See README for details.
;
; NOTE: Trashes A0, and allowed to modify arguments.
SDCARD_TRAP_13_HANDLER:
    cmp.l   #4,D0                       ; Is function code in range?
    bhi.s   .NOT_IMPLEMENTED            ; Nope, leave...

    add.l   D0,D0                       ; Multiply FC...
    add.l   D0,D0                       ; ... by 4...
    move.l  .JUMPTABLE(PC,D0),A0        ; ... and calc offset into table...
    jmp     (A0)                        ; ... then jump there

.JUMPTABLE:
    dc.l    CHECK_SDFAT                 ; FC == 0
    dc.l    SD_INIT                     ; FC == 1
    dc.l    SD_READ_BLOCK               ; FC == 2
    dc.l    SD_WRITE_BLOCK              ; FC == 3
    dc.l    SD_READ_REGISTER            ; FC == 4
.NOT_IMPLEMENTED:
    rte

* ************************************************************************** *
* ************************************************************************** *
; The individual handlers. These are responsible for handling the rte,
; and should not return to the main handler!
* ************************************************************************** *
CHECK_SDFAT:
    move.l  #$1234FEDC,D0               ; Move magic into D0
    rte

SD_INIT:
    move.l  EFP_SD_INIT,A0
    jsr     (A0)
    rte

SD_READ_BLOCK:
    move.l  EFP_SD_READ,A0
    jsr     (A0)
    rte

SD_WRITE_BLOCK:
    move.l  EFP_SD_WRITE,A0
    jsr     (A0)
    rte

SD_READ_REGISTER:
    move.l  EFP_SD_REG,A0
    jsr     (A0)
    rte

* ************************************************************************** *
* ************************************************************************** *
; EFP default handlers
* ************************************************************************** *
; Arguments:
;   A1  - Pointer to an SD struct
;
; Returns:
;   D0  - Result (0 failed, otherwise OK)
FW_SD_INIT:
    move.l  A1,-(A7)
    jsr     BBSD_initialize
    addq.l  #4,A7
    rts

; Arguments
;   A1  - Pointer to an SD struct
;   A2  - Pointer to 512-byte buffer
;   D1  - Block number to read
;
; Returns
;   D0  - 0 on success, else error code
FW_SD_READ:
    move.l  A2,-(A7)
    move.l  D1,-(A7)
    move.l  A1,-(A7)
    jsr     BBSD_read_block
    add.l   #12,A7
    rts

; Arguments
;   A1  - Pointer to an SD struct
;   A2  - Pointer to 512-byte buffer
;   D1  - Block number to write
;
; Returns
;   D0  - 0 on success, else error code
FW_SD_WRITE:
    move.l  A2,-(A7)
    move.l  D1,-(A7)
    move.l  A1,-(A7)
    jsr     BBSD_write_block
    add.l   #12,A7
    rts

; Arguments
;   A1  - Pointer to an SD struct
;   A2  - Pointer to register buffer
;   D1  - Register number to read
;
; Returns
;   D0  - 0 on success, else error code
FW_SD_REG:
    move.l  A2,-(A7)
    move.l  D1,-(A7)
    move.l  A1,-(A7)
    jsr     BBSD_readreg
    add.l   #12,A7
    rts

* ************************************************************************** *
* ************************************************************************** *
; Called to install the TRAP handlers; Trashes A0
* ************************************************************************** *
INSTALL_SDCARD_HANDLERS::
    ; Install TRAP handler
    lea     SDCARD_TRAP_13_HANDLER,A0
    move.l  A0,TRAP_13_VECTOR_ADDR

    ; Set up EFP pointers
    move.l  #FW_SD_INIT,EFP_SD_INIT
    move.l  #FW_SD_READ,EFP_SD_READ
    move.l  #FW_SD_WRITE,EFP_SD_WRITE
    move.l  #FW_SD_REG,EFP_SD_REG

    ; And done...
    rts



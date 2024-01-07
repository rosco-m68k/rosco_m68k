;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2020 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; Block device IO - assembly parts
;------------------------------------------------------------
    include "rosco_m68k_public.asm"
    include "rosco_m68k_private.asm"
    section .text

TRAP_13_VECTOR      equ     $2D
TRAP_13_VECTOR_ADDR equ     TRAP_13_VECTOR*4

; TRAP 13 provides access to block device IO (ATA & SD Card).
; For historical reasons, this TRAP also provides access to the SPI routines.
;
; D0 is expected to contain the task number (function code). Other arguments
; depend on the specific function - See InterfaceReference.md for details.
;
; NOTE: Trashes A0, and allowed to modify arguments.
TRAP_13_HANDLER::
    cmp.l   #19,D0                      ; Is function code in range?
    bhi.s   .NOT_IMPLEMENTED            ; Nope, leave...

    add.l   D0,D0                       ; Multiply FC...
    add.l   D0,D0                       ; ... by 4...
    move.l  .JUMPTABLE(PC,D0),A0        ; ... and calc offset into table...
    jmp     (A0)                        ; ... then jump there

.JUMPTABLE:
    dc.l    CHECK_SUCCESS               ; FC == 0
    dc.l    SD_INIT                     ; FC == 1
    dc.l    SD_READ_BLOCK               ; FC == 2
    dc.l    SD_WRITE_BLOCK              ; FC == 3
    dc.l    SD_READ_REGISTER            ; FC == 4
    dc.l    CHECK_FAIL                  ; FC == 5
    dc.l    SPI_INIT                    ; FC == 6
    dc.l    SPI_ASSERT_CS               ; FC == 7
    dc.l    SPI_DEASSERT_CS             ; FC == 8
    dc.l    SPI_TRANSFER_BYTE           ; FC == 9
    dc.l    SPI_TRANSFER_BUFFER         ; FC == 10
    dc.l    SPI_RECV_BYTE               ; FC == 11
    dc.l    SPI_RECV_BUFFER             ; FC == 12
    dc.l    SPI_SEND_BYTE               ; FC == 13
    dc.l    SPI_SEND_BUFFER             ; FC == 14
    dc.l    CHECK_FAIL                  ; FC == 15
    dc.l    ATA_INIT                    ; FC == 16
    dc.l    ATA_READ                    ; FC == 17
    dc.l    ATA_WRITE                   ; FC == 18
    dc.l    ATA_IDENTIFY                ; FC == 19
.NOT_IMPLEMENTED:
    rte

* ************************************************************************** *
* ************************************************************************** *
; The individual handlers. These are responsible for handling the rte,
; and should not return to the main handler!
* ************************************************************************** *
CHECK_SUCCESS:
    move.l  #$1234FEDC,D0               ; Move magic into D0
    rte

CHECK_FAIL:
    move.l  #$2bad2bad,D0               ; Move magic into D0
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

SPI_INIT:
    move.l  EFP_SPI_INIT,A0
    jsr     (A0)
    rte

SPI_ASSERT_CS:
    move.l  EFP_SPI_CS_A,A0
    jsr     (A0)
    rte

SPI_DEASSERT_CS:
    move.l  EFP_SPI_CS_D,A0
    jsr     (A0)
    rte

SPI_TRANSFER_BYTE:
    move.l  EFP_SPI_XFER_B,A0
    jsr     (A0)
    rte

SPI_TRANSFER_BUFFER:
    move.l  EFP_SPI_XFER_M,A0
    jsr     (A0)
    rte

SPI_RECV_BYTE:
    move.l  EFP_SPI_RECV_B,A0
    jsr     (A0)
    rte

SPI_RECV_BUFFER:
    move.l  EFP_SPI_RECV_M,A0
    jsr     (A0)
    rte

SPI_SEND_BYTE:
    move.l  EFP_SPI_SEND_B,A0
    jsr     (A0)
    rte

SPI_SEND_BUFFER:
    move.l  EFP_SPI_SEND_M,A0
    jsr     (A0)
    rte

ATA_INIT:
    move.l  EFP_ATA_INIT,A0
    jsr     (A0)
    rte

ATA_READ:
    move.l  EFP_ATA_READ,A0
    jsr     (A0)
    rte

ATA_WRITE:
    move.l  EFP_ATA_WRITE,A0
    jsr     (A0)
    rte

ATA_IDENTIFY:
    move.l  EFP_ATA_IDENT,A0
    jsr     (A0)
    rte

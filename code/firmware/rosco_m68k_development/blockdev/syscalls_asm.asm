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
    include "../../../shared/rosco_m68k_public.asm"
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
BLOCKDEV_TRAP_13_HANDLER:
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
    dc.l    CHECK_SUCCESS               ; FC == 5
    dc.l    SPI_INIT                    ; FC == 6
    dc.l    SPI_ASSERT_CS               ; FC == 7
    dc.l    SPI_DEASSERT_CS             ; FC == 8
    dc.l    SPI_TRANSFER_BYTE           ; FC == 9
    dc.l    SPI_TRANSFER_BUFFER         ; FC == 10
    dc.l    SPI_RECV_BYTE               ; FC == 11
    dc.l    SPI_RECV_BUFFER             ; FC == 12
    dc.l    SPI_SEND_BYTE               ; FC == 13
    dc.l    SPI_SEND_BUFFER             ; FC == 14
    dc.l    CHECK_SUCCESS               ; FC == 15
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

* ************************************************************************** *
* ************************************************************************** *
; EFP default handlers
* ************************************************************************** *
; Arguments:
;   A1  - Pointer to an SD struct
;
; Returns:
;   D0  - Result (0 = OK, otherwise failed)
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
;   D0  - 0 on error, else success
FW_SD_READ:
    move.l  #BBSD_read_block,A0
    bra.s   SD_BLOCK_OP

; Arguments
;   A1  - Pointer to an SD struct
;   A2  - Pointer to 512-byte buffer
;   D1  - Block number to write
;
; Returns
;   D0  - 0 on error, else success
FW_SD_WRITE:
    move.l  #BBSD_write_block,A0
    bra.s   SD_BLOCK_OP

; Arguments
;   A1  - Pointer to an SD struct
;   A2  - Pointer to register buffer
;   D1  - Register number to read
;
; Returns
;   D0  - 0 on error, else success
FW_SD_REG:
    move.l  #BBSD_readreg,A0
SD_BLOCK_OP:
    move.l  A2,-(A7)
    move.l  D1,-(A7)
    move.l  A1,-(A7)
    jsr     (A0)
    add.l   #12,A7
    rts

; Arguments:
;   None
;
; Returns:
;   D0  - Result (0 = OK, otherwise failed)
FW_SPI_INIT::
    jmp     BBSPI_initialize

; Arguments:
;   D1  - Device number (0 or 1)
;
; Returns:
;   D0  - Result (0 failed, otherwise OK)
;
; Modifies:
;   A1  - Trashed
FW_SPI_ASSERT_CS:
    move.l  #BBSPI_assert_cs0,A0
    move.l  #BBSPI_assert_cs1,A1
    bra.s   SPI_ASSERT_OP
    
; Arguments:
;   D1  - Device number (0 or 1)
;
; Returns:
;   D0  - Result (0 failed, otherwise OK)
FW_SPI_DEASSERT_CS:
    move.l  #BBSPI_deassert_cs0,A0
    move.l  #BBSPI_deassert_cs1,A1
SPI_ASSERT_OP:
    cmp.l   #0,D1
    beq.s   .DEV0
    cmp.l   #1,D1
    beq.s   .DEV1
    
    ; else error
    move.l  #0,D0
    rts

.DEV0:
    jsr     (A0)
    bra.s   .SUCCESS

.DEV1:
    jsr     (A1)
    
.SUCCESS
    move.l  #1,D0
    rts

; Arguments:
;   D1  - Byte to send
;
; Returns:
;   D0  - Byte received
FW_SPI_TRANSFER_BYTE:
    move.l  D1,-(A7)
    jsr     BBSPI_transfer_byte
    addq.l  #4,A7
    rts

; Arguments:
;   None
;
; Returns:
;   D0  - Byte received
FW_SPI_RECV_BYTE:
    jmp     BBSPI_recv_byte

; Arguments:
;   None
;
; Returns:
;   D0  - Byte received
FW_SPI_SEND_BYTE:
    move.l  D1,-(A7)
    jsr     BBSPI_transfer_byte
    addq.l  #4,A7
    rts

; Arguments:
;   A1  - Pointer to buffer
;   D1  - Count
;
; Returns:
;   D0  - Count transferred
FW_SPI_TRANSFER_BUFFER:
    move.l  #BBSPI_transfer_buffer,A0
    bra.s   SPI_BUFFER_OP

; Arguments:
;   A1  - Pointer to buffer
;   D1  - Count
;
; Returns:
;   D0  - Count transferred
FW_SPI_RECV_BUFFER:
    move.l  #BBSPI_recv_buffer,A0
    bra.s   SPI_BUFFER_OP

; Arguments:
;   A1  - Pointer to buffer
;   D1  - Count
;
; Returns:
;   D0  - Count transferred
FW_SPI_SEND_BUFFER:
    move.l  #BBSPI_send_buffer,A0
SPI_BUFFER_OP:
    move.l  D1,-(A7)
    move.l  A1,-(A7)
    jsr     (A0)
    add.l   #8,A7
    rts

; Arguments:
;
;  D1.L - 0 (ATA Master) or 1 (ATA slave)
;  A1   - Pointer to an ATADevice struct
;
; Modifies:
;
;  D0.L - Return value
;  D1.L - May be modified arbitrarily
;  A0   - Modified arbitrarily
;  A1   - May be modified arbitrarily
FW_ATA_INIT:
    move.l  A1,-(A7)
    move.l  D1,-(A7)
    jsr     ATA_init
    add.l   #8,A7
    rts

; Arguments:
;
;  D1.L - LBA sector number to read
;  D2.L - Number of sectors to read
;  A1   - Pointer to an initialized ATADevice struct
;  A2   - Pointer to a (512 * D2.L)-byte buffer
;
; Modifies:
;
;  D0.L  - Return value (Actual read count)
;  D1.L  - May be modified arbitrarily
;  A0    - Modified arbitrarily
;  A1    - May be modified arbitrarily
;  A2    - May be modified arbitrarily
FW_ATA_READ:
    move.l  #ATA_read_sectors,A0

ATA_XFER_OP:
    move.l  A1,-(A7)
    move.l  D2,-(A7)
    move.l  D1,-(A7)
    move.l  A2,-(A7)
    jsr     (A0)
    add.l   #16,A7
    rts

; Arguments:
;
;  D1.L - LBA sector number to write
;  D2.L - Number of sectors to write
;  A1   - Pointer to an initialized ATADevice struct
;  A2   - Pointer to a (512 * D2.L)-byte buffer
;
; Modifies:
;
;  D0.L  - Return value (Actual written count)
;  D1.L  - May be modified arbitrarily
;  A0    - Modified arbitrarily
;  A1    - May be modified arbitrarily
;  A2    - May be modified arbitrarily
FW_ATA_WRITE:
    move.l  #ATA_write_sectors,A0
    bra.s   ATA_XFER_OP

; Arguments:
;
;  D0.L - 19 (Function code)
;  A1   - Pointer to an initialized ATADevice struct
;  A2   - Pointer to a 512-byte buffer
;
; Modifies:
;
;  D0.L - Return value (0 = failed, 1 = success)
;  D1.L - May be modified arbitrarily
;  A0   - Modified arbitrarily
;  A1   - May be modified arbitrarily
;  A2   - May be modified arbitrarily
FW_ATA_IDENT:
    move.l  A1,-(A7)
    move.l  A2,-(A7)
    jsr     ATA_ident
    add.l   #8,A7
    rts

* ************************************************************************** *
* ************************************************************************** *
; Called to install the TRAP handlers; Trashes A0
* ************************************************************************** *
INSTALL_BLOCKDEV_HANDLERS::
    ; Install TRAP handler
    move.l  #BLOCKDEV_TRAP_13_HANDLER,TRAP_13_VECTOR_ADDR

    ; Set up EFP pointers
    move.l  #FW_SD_INIT,EFP_SD_INIT
    move.l  #FW_SD_READ,EFP_SD_READ
    move.l  #FW_SD_WRITE,EFP_SD_WRITE
    move.l  #FW_SD_REG,EFP_SD_REG
    move.l  #FW_SPI_INIT,EFP_SPI_INIT
    move.l  #FW_SPI_ASSERT_CS,EFP_SPI_CS_A
    move.l  #FW_SPI_DEASSERT_CS,EFP_SPI_CS_D
    move.l  #FW_SPI_TRANSFER_BYTE,EFP_SPI_XFER_B
    move.l  #FW_SPI_TRANSFER_BUFFER,EFP_SPI_XFER_M
    move.l  #FW_SPI_RECV_BYTE,EFP_SPI_RECV_B
    move.l  #FW_SPI_RECV_BUFFER,EFP_SPI_RECV_M
    move.l  #FW_SPI_SEND_BYTE,EFP_SPI_SEND_B
    move.l  #FW_SPI_SEND_BUFFER,EFP_SPI_SEND_M
    move.l  #FW_ATA_INIT,EFP_ATA_INIT
    move.l  #FW_ATA_READ,EFP_ATA_READ
    move.l  #FW_ATA_WRITE,EFP_ATA_WRITE
    move.l  #FW_ATA_IDENT,EFP_ATA_IDENT

    ; And done...
    rts


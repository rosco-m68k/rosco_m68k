;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|       firmware v2
;------------------------------------------------------------
; Copyright (c)2019-2021 Ross Bamford and contributors
; See top-level LICENSE.md for licence information.
;
; Public equates for rosco_m68k firmware
;
; 
;------------------------------------------------------------

; ----------------------------------------------------------------------------
; Memory layout
;
RAMBASE     equ     $0                    ; Base address for RAM
RAMLIMIT    equ     $100000               ; Limit of onboard RAM
IOBASE      equ     $F80000               ; Base address for IO space
ROMBASE     equ     $FC0000               ; Base address for ROM space


; ----------------------------------------------------------------------------
; System Data Block (SDB) layout
;
SDB_MAGIC       equ     $400              ; SDB Magic (0xB105D47A)
SDB_STATUS      equ     $404              ; Status code
SDB_TICKCNT     equ     $408              ; (Internal) Tick counter
SDB_SYSFLAGS    equ     $40A              ; Sys Flags (see InterfaceReference)
SDB_UPTICKS     equ     $40C              ; Upticks counter
SDB_E68K_STATE  equ     $410              ; (Internal) E68k state
SDB_INTFLAGS    equ     $413              ; (Internal) Flags
SDB_MEMSIZE     equ     $414              ; Memory size (first block)
SDB_UARTBASE    equ     $418              ; Default UART base address
SDB_CPUINFO     equ     $41C              ; CPU Info (see IntefaceReference)

; ----------------------------------------------------------------------------
; Extension Function Pointer (EFP) table addresses
;
; See InterfaceReference.md for the meaning of the individual pointers
; and their interface contracts.
;
; These are public to allow them to be easily replaced by system software 
; and drivers. They **must not** be called directly from user code!
;
EFP_PRINT       equ     $420
EFP_PRINTLN     equ     $424
EFP_PRINTCHAR   equ     $428
EFP_HALT        equ     $42C
EFP_SENDCHAR    equ     $430
EFP_RECVCHAR    equ     $434
EFP_CLRSCR      equ     $438
EFP_MOVEXY      equ     $43C
EFP_SETCURSOR   equ     $440
EFP_CHECKCHAR   equ     $444
EFP_PROGLOADER  equ     $448
EFP_SD_INIT     equ     $44C
EFP_SD_READ     equ     $450
EFP_SD_WRITE    equ     $454
EFP_SD_REG      equ     $458
EFP_SPI_INIT    equ     $45C
EFP_SPI_CS_A    equ     $460
EFP_SPI_CS_D    equ     $464
EFP_SPI_XFER_B  equ     $468
EFP_SPI_XFER_M  equ     $46C
EFP_SPI_RECV_B  equ     $470
EFP_SPI_RECV_M  equ     $474
EFP_SPI_SEND_B  equ     $478
EFP_SPI_SEND_M  equ     $47C
EFP_ATA_INIT    equ     $480
EFP_ATA_READ    equ     $484
EFP_ATA_WRITE   equ     $488
EFP_ATA_IDENT   equ     $48C
EFP_PROG_EXIT   equ     $490

; MFP Location
MFPBASE     equ     IOBASE

  ifd REVISION1X
; Equates for MC68901 Multi Function Peripheral
;
; The register layout is different on r0 boards, hence the
; conditional assembly...
; ------------------------------------------------------------
  ifd REVISION_0
;; MFP Registers on REVISION_0 board

; MFP GPIO Registers
MFP_GPDR    equ     MFPBASE+$01
MFP_AER     equ     MFPBASE+$21
MFP_DDR     equ     MFPBASE+$11
; MFP Interrupt Controller Registers
MFP_IERA    equ     MFPBASE+$31
MFP_IERB    equ     MFPBASE+$09
MFP_IPRA    equ     MFPBASE+$29
MFP_IPRB    equ     MFPBASE+$19
MFP_ISRA    equ     MFPBASE+$39
MFP_ISRB    equ     MFPBASE+$05
MFP_IMRA    equ     MFPBASE+$25
MFP_IMRB    equ     MFPBASE+$15
MFP_VR      equ     MFPBASE+$35
; MFP Timer Registers
MFP_TACR    equ     MFPBASE+$0D
MFP_TBCR    equ     MFPBASE+$2D
MFP_TCDCR   equ     MFPBASE+$1D
MFP_TADR    equ     MFPBASE+$3D
MFP_TBDR    equ     MFPBASE+$03
MFP_TCDR    equ     MFPBASE+$23
MFP_TDDR    equ     MFPBASE+$13
; MFP USART Registers
MFP_SCR     equ     MFPBASE+$33
MFP_UCR     equ     MFPBASE+$0B
MFP_RSR     equ     MFPBASE+$2B
MFP_TSR     equ     MFPBASE+$1B
MFP_UDR     equ     MFPBASE+$3B

  else

;; MFP Registers on "fixed" boards
; MFP GPIO Registers
MFP_GPDR    equ     MFPBASE+$01
MFP_AER     equ     MFPBASE+$03
MFP_DDR     equ     MFPBASE+$05
; MFP Interrupt Controller Registers
MFP_IERA    equ     MFPBASE+$07
MFP_IERB    equ     MFPBASE+$09
MFP_IPRA    equ     MFPBASE+$0B
MFP_IPRB    equ     MFPBASE+$0D
MFP_ISRA    equ     MFPBASE+$0F
MFP_ISRB    equ     MFPBASE+$11
MFP_IMRA    equ     MFPBASE+$13
MFP_IMRB    equ     MFPBASE+$15
MFP_VR      equ     MFPBASE+$17
; MFP Timer Registers
MFP_TACR    equ     MFPBASE+$19
MFP_TBCR    equ     MFPBASE+$1B
MFP_TCDCR   equ     MFPBASE+$1D
MFP_TADR    equ     MFPBASE+$1F
MFP_TBDR    equ     MFPBASE+$21
MFP_TCDR    equ     MFPBASE+$23
MFP_TDDR    equ     MFPBASE+$25
; MFP USART Registers
MFP_SCR     equ     MFPBASE+$27
MFP_UCR     equ     MFPBASE+$29
MFP_RSR     equ     MFPBASE+$2B
MFP_TSR     equ     MFPBASE+$2D
MFP_UDR     equ     MFPBASE+$2F

  endif     ; REVISION_0

; Base vector for MFP exceptions
MFP_VECBASE equ     $40
  endif     ; REVISION1X


; Equates for MC68681 DUART
; ------------------------------------------------------------
;
; This assumes the 68681 RS1-RS4 are connected to A1-A4, and that
; the decoder maps starting at either $f80008 (for the r1 board)
; or $f80048 (for the r2), with the difference being in that the
; newer board is mapped with A7 high, while the older one is mapped
; with A7 low. 
;
; For easier software compatibility, both the old and new boards 
; use the same out-of-order register ordering, which differs form
; the datasheet.
;
; In that scheme, this is how IO addresses map to MC68681 registers:
;
; Address   :  A23 A22 A21 A20 A19 A18 A17 A16 A15 A14 A13 A12 A11 A10 A9  A8  A7  A6  A5  A4  A3  A2  A1  A0 (4321) = Reg
; 0x00f80008:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   0   1   0   0   0  (0100) = 4
; 0x00f8000a:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   0   1   0   1   0  (0101) = 5
; 0x00f8000c:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   0   1   1   0   0  (0110) = 6
; 0x00f8000e:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   0   1   1   1   0  (0111) = 7
; 0x00f80010:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   1   0   0   0   0  (1000) = 8
; 0x00f80012:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   1   0   0   1   0  (1001) = 9
; 0x00f80014:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   1   0   1   0   0  (1010) = 10
; 0x00f80016:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   1   0   1   1   0  (1011) = 11
; 0x00f80018:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   1   1   0   0   0  (1100) = 12
; 0x00f8001a:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   1   1   0   1   0  (1101) = 13
; 0x00f8001c:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   1   1   1   0   0  (1110) = 14
; 0x00f8001e:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   0   x   1   1   1   1   0  (1111) = 15
; 0x00f80020:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   x   y   0   0   0   0   0  (0000) = 0
; 0x00f80022:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   x   y   0   0   0   1   0  (0001) = 1
; 0x00f80024:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   x   y   0   0   1   0   0  (0010) = 2
; 0x00f80026:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   x   x   y   0   0   1   1   0  (0011) = 3
;
; (x = 0 for r1 board, 1 for r2).
; (y = 1 for r1 board, 0 for r2).
;
; The actual register constants below are offsets from the relevant
; base address (which will be determined during auto-detection, and
; stored in the SDB at $418.

DUART_BASE_R1   equ     $f80008
DUART_BASE_R2   equ     $f800a8
    ifnd REVISION1X
DUART_BASE_MBR2 equ     $f00001
    endif

; For reference to the datasheet, the MC68681 register number is listed below.
;
    ifd REVISION1X
RW_MODE_A       equ     $18           ; RW register 0

R_STATUS_A      equ     $1a           ; R register 1
W_CLKSEL_A      equ     $1a           ; W register 1

; R is DO NOT READ on MC part, MISR on XR68C681
R_MISR          equ     $1c           ; R register 2
W_COMMAND_A     equ     $1c           ; W register 2

R_RXBUF_A       equ     $1e           ; R register 3
W_TXBUF_A       equ     $1e           ; W register 3

R_INPORTCHG     equ     $0            ; R register 4
W_AUXCTLREG     equ     $0            ; W register 4

R_ISR           equ     $2            ; R register 5
W_IMR           equ     $2            ; W register 5

R_COUNTERMSB    equ     $4            ; R register 6
W_COUNTERMSB    equ     $4            ; W register 6

R_COUNTERLSB    equ     $6            ; R register 7
W_COUNTERLSB    equ     $6            ; W register 7

RW_MODE_B       equ     $8            ; RW register 8

R_STATUS_B      equ     $a            ; R register 9
W_CLKSEL_B      equ     $a            ; W register 9

; R is DO NOT ACCESS on both legacy and modern parts
W_COMMAND_B     equ     $c            ; W register 10

R_RXBUF_B       equ     $e            ; R register 11
W_TXBUF_B       equ     $e            ; W register 11

RW_IVR          equ     $10           ; RW register 12

R_INPUTPORT     equ     $12           ; R register 13
W_OUTPORTCFG    equ     $12           ; W register 13

R_STARTCNTCMD   equ     $14           ; R register 14
W_OPR_SETCMD    equ     $14           ; W register 14

R_STOPCNTCMD    equ     $16           ; R register 15
W_OPR_RESETCMD  equ     $16           ; W register 15


    else


RW_MODE_A       equ     $0            ; RW register 0

R_STATUS_A      equ     $2            ; R register 1
W_CLKSEL_A      equ     $2            ; W register 1

; R is DO NOT READ on MC part, MISR on XR68C681
R_MISR          equ     $4            ; R register 2
W_COMMAND_A     equ     $4            ; W register 2

R_RXBUF_A       equ     $6            ; R register 3
W_TXBUF_A       equ     $6            ; W register 3

R_INPORTCHG     equ     $8            ; R register 4
W_AUXCTLREG     equ     $8            ; W register 4

R_ISR           equ     $a            ; R register 5
W_IMR           equ     $a            ; W register 5

R_COUNTERMSB    equ     $c            ; R register 6
W_COUNTERMSB    equ     $c            ; W register 6

R_COUNTERLSB    equ     $e            ; R register 7
W_COUNTERLSB    equ     $e            ; W register 7

RW_MODE_B       equ     $10           ; RW register 8

R_STATUS_B      equ     $12           ; R register 9
W_CLKSEL_B      equ     $12           ; W register 9

; R is DO NOT ACCESS on both legacy and modern parts
W_COMMAND_B     equ     $14           ; W register 10

R_RXBUF_B       equ     $16           ; R register 11
W_TXBUF_B       equ     $16           ; W register 11

RW_IVR          equ     $18           ; RW register 12

R_INPUTPORT     equ     $1a           ; R register 13
W_OUTPORTCFG    equ     $1a           ; W register 13

R_STARTCNTCMD   equ     $1c           ; R register 14
W_OPR_SETCMD    equ     $1c           ; W register 14

R_STOPCNTCMD    equ     $1e           ; R register 15
W_OPR_RESETCMD  equ     $1e           ; W register 15

    endif

;
; For convenience, also define the mnemonics used in the datasheet...
;
; These are *not* defined (by the datasheet) for all registers!
;
DUART_MR1A      equ     RW_MODE_A
DUART_MR2A      equ     RW_MODE_A
DUART_SRA       equ     R_STATUS_A
DUART_CSRA      equ     W_CLKSEL_A
DUART_MISR      equ     R_MISR
DUART_CRA       equ     W_COMMAND_A
DUART_RBA       equ     R_RXBUF_A
DUART_TBA       equ     W_TXBUF_A
DUART_IPCR      equ     R_INPORTCHG
DUART_ACR       equ     W_AUXCTLREG
DUART_ISR       equ     R_ISR
DUART_IMR       equ     W_IMR
DUART_CUR       equ     R_COUNTERMSB
DUART_CTUR      equ     W_COUNTERMSB
DUART_CLR       equ     R_COUNTERLSB
DUART_CTLR      equ     W_COUNTERLSB
DUART_MR1B      equ     RW_MODE_B
DUART_MR2B      equ     RW_MODE_B
DUART_SRB       equ     R_STATUS_B
DUART_CSRB      equ     W_CLKSEL_B
DUART_CRB       equ     W_COMMAND_B
DUART_RBB       equ     R_RXBUF_B
DUART_TBB       equ     W_TXBUF_B
DUART_IVR       equ     RW_IVR
DUART_OPCR      equ     W_OUTPORTCFG


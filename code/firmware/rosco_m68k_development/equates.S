;------------------------------------------------------------
;                                  ___ ___ _
;  ___ ___ ___ ___ ___       _____|  _| . | |_
; |  _| . |_ -|  _| . |     |     | . | . | '_|
; |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
;                     |_____|       firmware v1
;------------------------------------------------------------
; Copyright (c)2019 Ross Bamford
; See top-level LICENSE.md for licence information.
;
; Global equates for firmware code
;------------------------------------------------------------

; Version (embedded into firmware at 0xFC0400)
; MSW is flags, LSW is split into major (MSB) and minor (LSB)
;
; Flags:
; bit 0 - 14: Reserved
; bit 15    : Snapshot version
RELEASE_VER     equ    $80000130

; EFP table addresses
EFP_PRINT       equ    $420
EFP_PRINTLN     equ    $424
EFP_PRINTCHAR   equ    $428
EFP_HALT        equ    $42C
EFP_SENDCHAR    equ    $430
EFP_RECVCHAR    equ    $434
EFP_CLRSCR      equ    $438
EFP_MOVEXY      equ    $43C
EFP_SETCURSOR   equ    $440

; Equates for MC68681 DUART
; ------------------------------------------------------------
;
; This assumes the 68681 RS1-RS4 are connected to A1-A4, and that
; the decoder maps starting at $f80008. In that scheme, this is
; how IO addresses map to MC68681 registers:
;
; Address   :  A23 A22 A21 A20 A19 A18 A17 A16 A15 A14 A13 A12 A11 A10 A9  A8  A7  A6  A5  A4  A3  A2  A1  A0 (4321) = Reg
; 0x00f80008:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   0   0  (0100) = 4
; 0x00f8000a:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   1   0  (0101) = 5
; 0x00f8000c:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   1   0   0  (0110) = 6
; 0x00f8000e:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   1   1   0  (0111) = 7
; 0x00f80010:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   0   0   0  (1000) = 8
; 0x00f80012:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   0   1   0  (1001) = 9
; 0x00f80014:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   1   0   0  (1010) = 10
; 0x00f80016:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   1   1   0  (1011) = 11
; 0x00f80018:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   1   0   0   0  (1100) = 12
; 0x00f8001a:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   1   0   1   0  (1101) = 13
; 0x00f8001c:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   1   1   0   0  (1110) = 14
; 0x00f8001e:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   0   1   1   1   1   0  (1111) = 15
; 0x00f80020:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   0   0   0   0  (0000) = 0
; 0x00f80022:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   0   0   1   0  (0001) = 1
; 0x00f80024:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   0   1   0   0  (0010) = 2
; 0x00f80026:  1   1   1   1   1   0   0   0   0   0   0   0   0   0   0   0   0   0   1   0   0   1   1   0  (0011) = 3
;
; For reference to the datasheet, the MC68681 register number is listed below.
;
RW_MODE_A       equ     $f80020      ; RW register 0

R_STATUS_A      equ     $f80022      ; R register 1
W_CLKSEL_A      equ     $f80022      ; W register 1

; R is DO NOT ACCESS
W_COMMAND_A     equ     $f80024      ; W register 2

R_RXBUF_A       equ     $f80026      ; R register 3
W_TXBUF_A       equ     $f80026      ; W register 3

;============================

;RW_MODE_A       equ     $f80000      ; RW register 0

;R_STATUS_A      equ     $f80002      ; R register 1
;W_CLKSEL_A      equ     $f80002      ; W register 1

; R is DO NOT ACCESS
;W_COMMAND_A     equ     $f80004      ; W register 2

;R_RXBUF_A       equ     $f80006      ; R register 3
;W_TXBUF_A       equ     $f80006      ; W register 3
;=============================

R_INPORTCHG     equ     $f80008      ; R register 4
W_AUXCTLREG     equ     $f80008      ; W register 4

R_ISR           equ     $f8000a      ; R register 5
W_IMR           equ     $f8000a      ; W register 5

R_COUNTERMSB    equ     $f8000c      ; R register 6
W_COUNTUPPER    equ     $f8000c      ; W register 6

R_COUNTERLSB    equ     $f8000e      ; R register 7
W_COUNTLOWER    equ     $f8000e      ; W register 7

RW_MODE_B       equ     $f80010      ; RW register 8

R_STATUS_B      equ     $f80012      ; R register 9
W_CLKSEL_B      equ     $f80012      ; W register 9

; R is DO NOT ACCESS
W_COMMAND_B     equ     $f80014      ; W register 10

R_RXBUF_B       equ     $f80016      ; R register 11
W_TXBUF_B       equ     $f80016      ; W register 11

RW_IVR          equ     $f80018      ; RW register 12

R_INPUTPORT     equ     $f8001a      ; R register 13
W_OUTPORTCFG    equ     $f8001a      ; W register 13

R_STARTCNTCMD   equ     $f8001c      ; R register 14
W_OPR_SETCMD    equ     $f8001c      ; W register 14

R_STOPCNTCMD    equ     $f8001e      ; R register 15
W_OPR_RESETCMD  equ     $f8001e      ; W register 15

; For convenience, also define the mnemonics used in the datasheet...
;
; These are *not* defined (by the datasheet) for all registers!
;
DUART_MR1A      equ     RW_MODE_A
DUART_MR2A      equ     RW_MODE_A
DUART_SRA       equ     R_STATUS_A
DUART_CSRA      equ     W_CLKSEL_A
DUART_CRA       equ     W_COMMAND_A
DUART_RBA       equ     R_RXBUF_A
DUART_TBA       equ     W_TXBUF_A
DUART_IPCR      equ     R_INPORTCHG
DUART_ACR       equ     W_AUXCTLREG
DUART_ISR       equ     R_ISR
DUART_IMR       equ     W_IMR
DUART_CUR       equ     R_COUNTERMSB
DUART_CTUR      equ     W_COUNTUPPER
DUART_CLR       equ     R_COUNTERLSB
DUART_CTLR      equ     W_COUNTLOWER
DUART_MR1B      equ     RW_MODE_B
DUART_MR2B      equ     RW_MODE_B
DUART_SRB       equ     R_STATUS_B
DUART_CSRB      equ     W_CLKSEL_B
DUART_CRB       equ     W_COMMAND_B
DUART_RBB       equ     R_RXBUF_B
DUART_TBB       equ     W_TXBUF_B
DUART_IVR       equ     RW_IVR
DUART_OPCR      equ     W_OUTPORTCFG

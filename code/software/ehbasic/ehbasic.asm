*************************************************************************************
*										    *
*	Enhanced BASIC for the Motorola MC680xx					    *
*										    *
*	This version is for the TS2 single board computer.		            *
*	Jeff Tranter (tranter@pobox.com)					    *
*										    *
*************************************************************************************
*										    *
*	Copyright(C) 2002-12 by Lee Davison. This program may be freely distributed *
*	for personal use only. All commercial rights are reserved.		    *
*										    *
*	More 68000 and other projects can be found on my website at ..		    *
*										    *
*	 http://mycorner.no-ip.org/index.html					    *
*										    *
*	mail : leeedavison@googlemail.com					    *
*										    *
*************************************************************************************

* Ver 3.52

* Ver 3.52 stops USING$() from reading beyond the end of the format string
* Ver 3.51 fixes the UCASE$() and LCASE$() functions for null strings
* Ver 3.50 unary minus in concatenate generates a type mismatch error
* Ver 3.49 doesn't tokenise 'DEF' or 'DEC' within a hex value
* Ver 3.48 allows scientific notation underflow in the USING$() function
* Ver 3.47 traps the use of array elements as the FOR loop variable
* Ver 3.46 updates function and function variable handling

*************************************************************************************
*
* Ver 3.45 makes the handling of non existant variables consistent and gives the
* option of not returning an error for a non existant variable. If this is the
* behaviour you want just change novar to some non zero value

novar		EQU	0				* non existant variables cause errors


*************************************************************************************

* Ver 3.44 adds overflow indication to the USING$() function
* Ver 3.43 removes an undocumented feature of concatenating null strings
* Ver 3.42 reimplements backspace so that characters are overwritten with [SPACE]
* Ver 3.41 removes undocumented features of the USING$() function
* Ver 3.40 adds the USING$() function
* Ver 3.33 adds the file requester to LOAD and SAVE
* Ver 3.32 adds the optional ELSE clause to IF .. THEN

*************************************************************************************
*
* Version 3.25 adds the option to change the behaviour of INPUT so that a null
* response does not cause a program break. If this is the behaviour you want just
* change nobrk to some non zero value.

nobrk		EQU	0				* null response to INPUT causes a break


*************************************************************************************
*
* Version 3.xx replaces the fixed RAM addressing from previous versions with a RAM
* pointer in a3. this means that this could now be run as a task on a multitasking
* system where memory resources may change.


*************************************************************************************

    include "../../shared/rosco_m68k_public.asm"
  	include	"ehdefs.inc"
  
							* RAM offset definitions

* Use this value to run out of ROM
*	ORG		$FC0000			* past the vectors in a real system
* Use this value to run out of RAM
*  ORG		$28000			* past the vectors in a real system

         BRA    code_start       * For convenience, so you can start from first address
*************************************************************************************
*
* the following code is rosco_m68k-specific

* output character to the console from register d0.b

; While not strictly _to spec_ to reset cursor position on LF (it should be CR), ehBASIC 
; *always* prints them in pairs, so this will work (and fits nicely with the way the 
; VDP IO routines handle LF, while also still working with the UART).
VEC_OUT:
    move.l  D1,-(A7)              ; Save D1
    move.b  TPos(A3),D1           ; Grab TPos...

    cmp.b   #$A,D0                ; Is character a linefeed?
    bne.s   .NOTLF                ; ...carry on if not
    move.b  #0,D1                 ; ...else zero TPos
    bra.s   .SETTPOS              ; ...and store it back to mem, then print (for UART compatibility).
.NOTLF
    cmp.b   #$8,D0                ; Is it a BS?
    bne.s   .PRINT                ; ...nope, go directly to print...
    cmp.b   #0,D1                 ; ...else, check if TPos is 0
    beq.s   .BSZERO               ; branch is it is zero...
    subq.b  #1,D1                 ; ...else just subtract 1
    bra.s   .SETTPOS              ; and save to mem, then print
.BSZERO
    move.b  TWidth(A3),D1         ; If it was zero, move to end of previous line...
                                  ; (ehBASIC should actually prevent this, but belt-and-braces...)
.SETTPOS
    move.b  D1,TPos(A3)           ; Store D1 back into TPos
.PRINT
    move.l  #4,D1                 ; Trap function code 4...
    trap    #14                   ; .. and go
    move.l  (A7)+,D1              ; Restore D1
    rts

*************************************************************************************
*
* input a character from the console into register d0
* else return Cb=0 if there's no character available

L_DUART_SRA      equ     $f80022      ; R register 1
L_DUART_RBA      equ     $f80026      ; R register 3

    ifd FIRMWARE_IO
; use rosco_m68k firmware calls
VEC_IN:
    movem.l d1-d7/a0-a6,-(sp)   ; overkill, but just D1 was not enough

    move.l  #6,D1               ; CHECKCHAR trap function code
    trap    #14

    tst.b   D0
    bne     .GOTKEY

    movem.l (sp)+,d1-d7/a0-a6
    andi.b  #$FE,CCR              ; Else clear the carry flag, no character available
    rts                           ; And return

.GOTKEY
    move.l  #3,D1               ; RECVCHAR trap function code
    trap    #14

		cmp.b		#$7F,D0							; is it DEL key?
		bne			.NOTDEL

		move.b	#$08,D0							; change into BS

.NOTDEL
    movem.l (sp)+,d1-d7/a0-a6
    ori.b   #1,CCR                ; ... and set the carry to flag to indicate we got a char
    rts

    else

    ifd MC68681

; MC68681 version
VEC_IN:

    move.b  L_DUART_SRA,D0        ; Check DUART status reg A
    btst    #0,D0                 ; Bit 0
    bne.s   .GOTCHR               ; Notready if zero
    andi.b  #$FE,CCR              ; Else clear the carry flag, no character available
    rts                           ; And return
    
.GOTCHR
    move.b  L_DUART_RBA,D0
    ori.b   #1,CCR                ; ... and set the carry to flag to indicate we got a char
    rts

    else

; MFP UART version
VEC_IN:

    move.b  MFP_RSR,D0            ; Get RSR
    btst    #7,D0                 ; Is buffer_full bit set?
    bne.s   .GOTCHR               ; Yes - Go to receive character

    btst    #6,D0                 ; Else, do we have an overrun error?
    bne.s   .GOTERR               ; .. Yes - handle that

    andi.b  #$FE,CCR              ; Else clear the carry flag, no character available
    rts                           ; And return

.GOTERR
    move.b  MFP_UDR,D0            ; Empty buffer
    bra.s   VEC_IN                ; And continue testing...

.GOTCHR
    move.b  MFP_UDR,D0            ; Get the data
    ori.b   #1,CCR                ; Set the carry to flag we got a char
    rts
    
    endif

    endif

*************************************************************************************
*
* LOAD routine for the rosco_m68k (not yet implemented)

VEC_LD
	MOVEQ		#$2E,d7			        * error code $2E "Not implemented" error
	BRA		LAB_XERR			* do error #d7, then warm start

*************************************************************************************
*
* SAVE routine for the rosco_m68k (not yet implemented)

VEC_SV
	MOVEQ		#$2E,d7			        * error code $2E "Not implemented" error
	BRA		LAB_XERR			* do error #d7, then warm start

*************************************************************************************
*
code_start
kmain::
* Display cursor
  move.l  #5,D1
  move.l  #1,D0
  trap    #14

* to tell EhBASIC where and how much RAM it has pass the address in a0 and the size
* in d0. these values are at the end of the .inc file

	MOVEA.l	#ram_addr,a0		* tell BASIC where RAM starts

  ifd     ROSCO_M68K					* Xark - calculate rosco_m68k memory size

  MOVE.l  _SDB_MEM_SIZE,d0    * total rosco_m68k memory size
	SUB.l		#ram_addr+$4000,d0	* minus starting RAM address and 16K stack

  else

	MOVE.l	#ram_size,d0		* tell BASIC how big RAM is

  endif

* end of simulator specific code


****************************************************************************************
****************************************************************************************
****************************************************************************************
****************************************************************************************
*
* Register use :- (must improve this !!)
*
*	a6 -	temp Bpntr				* temporary BASIC execute pointer
*	a5 -	Bpntr					* BASIC execute (get byte) pointer
*	a4 -	des_sk				        * descriptor stack pointer
*	a3 -	ram_strt				* start of RAM. all RAM references are offsets
*							* from this value
*

*************************************************************************************
*
* BASIC cold start entry point. assume entry with RAM address in a0 and RAM length
* in d0

LAB_COLD
	MOVEA.l	a0,a3				* copy RAM base to a3
	ADDA.l	d0,a0				* a0 is top of RAM
	MOVE.l	a0,Ememl(a3)		* set end of mem
	LEA		ram_base(a3),sp		* set stack to RAM start + 1k

	MOVE.w	#$4EF9,d0			* JMP opcode
	MOVEA.l	sp,a0				* point to start of vector table

	MOVE.w	d0,(a0)+			* LAB_WARM
	LEA		LAB_COLD(pc),a1		* initial warm start vector
	MOVE.l	a1,(a0)+			* set vector

	MOVE.w	d0,(a0)+			* Usrjmp
	LEA		LAB_FCER(pc),a1		* initial user function vector
							* "Function call" error
	MOVE.l	a1,(a0)+			* set vector

	MOVE.w	d0,(a0)+			* V_INPT JMP opcode
	LEA		VEC_IN(pc),a1		* get byte from input device vector
	MOVE.l	a1,(a0)+			* set vector

	MOVE.w	d0,(a0)+			* V_OUTP JMP opcode
	LEA		VEC_OUT(pc),a1		* send byte to output device vector
	MOVE.l	a1,(a0)+			* set vector

	MOVE.w	d0,(a0)+			* V_LOAD JMP opcode
	LEA		VEC_LD(pc),a1		* load BASIC program vector
	MOVE.l	a1,(a0)+			* set vector

	MOVE.w	d0,(a0)+			* V_SAVE JMP opcode
	LEA		VEC_SV(pc),a1		* save BASIC program vector
	MOVE.l	a1,(a0)+			* set vector

	MOVE.w	d0,(a0)+			* V_CTLC JMP opcode
	LEA		VEC_CC(pc),a1		* save CTRL-C check vector
	MOVE.l	a1,(a0)+			* set vector

* set-up start values

*##LAB_GMEM
	MOVEQ		#$00,d0			* clear d0
	MOVE.b	d0,Nullct(a3)		* default NULL count
	MOVE.b	d0,TPos(a3)			* clear terminal position
	MOVE.b	d0,ccflag(a3)		* allow CTRL-C check
	MOVE.w	d0,prg_strt-2(a3)		* clear start word
	MOVE.w	d0,BHsend(a3)		* clear value to string end word

	ifd	ROSCO_M68K

	MOVE.b	#$0,TWidth(a3)		* Xark - use unlimited witdh on rosco_m68k

	else

	MOVE.b	#$4F,TWidth(a3)		* default terminal width (should be width - 1)

	endif

	MOVE.b	#$0E,TabSiz(a3)		* save default tab size = 14

	MOVE.b	#$38,Iclim(a3)		* default limit for TAB = 14 for simulator

	LEA		des_sk(a3),a4		* set descriptor stack start

	LEA		prg_strt(a3),a0		* get start of mem
	MOVE.l	a0,Smeml(a3)		* save start of mem

	BSR		LAB_1463			* do "NEW" and "CLEAR"
	BSR		LAB_CRLF			* print CR/LF
	MOVE.l	Ememl(a3),d0		* get end of mem
	SUB.l		Smeml(a3),d0		* subtract start of mem

	BSR		LAB_295E			* print d0 as unsigned integer (bytes free)
	LEA		LAB_SMSG(pc),a0		* point to start message
	BSR		LAB_18C3			* print null terminated string from memory

	LEA		LAB_RSED(pc),a0		* get pointer to value
	BSR		LAB_UFAC			* unpack memory (a0) into FAC1

	LEA		LAB_1274(pc),a0		* get warm start vector
	MOVE.l	a0,Wrmjpv(a3)		* set warm start vector
	BSR		LAB_RND			* initialise
	JMP		LAB_WARM(a3)		* go do warm start


*************************************************************************************
*
* do format error

LAB_FOER
	MOVEQ		#$2C,d7			* error code $2C "Format" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do address error

LAB_ADER
	MOVEQ		#$2A,d7			* error code $2A "Address" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do wrong dimensions error

LAB_WDER
	MOVEQ		#$28,d7			* error code $28 "Wrong dimensions" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do undimensioned array error

LAB_UDER
	MOVEQ		#$26,d7			* error code $26 "undimensioned array" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do undefined variable error

LAB_UVER

* if you do want a non existant variable to return an error then leave the novar
* value at the top of this file set to zero

 ifeq	novar

	MOVEQ		#$24,d7			* error code $24 "undefined variable" error
	BRA.s		LAB_XERR			* do error #d7, then warm start

 endc

* if you want a non existant variable to return a null value then set the novar
* value at the top of this file to some non zero value

 ifne	novar

	ADD.l		d0,d0				* .......$ .......& ........ .......0
	SWAP		d0				* ........ .......0 .......$ .......&
	ROR.b		#1,d0				* ........ .......0 .......$ &.......
	LSR.w		#1,d0				* ........ .......0 0....... $&.....�.
	AND.b		#$C0,d0			* mask the type bits
	MOVE.b	d0,Dtypef(a3)		* save the data type

	MOVEQ		#0,d0				* clear d0 and set the zero flag
	MOVEA.l	d0,a0				* return a null address
	RTS

 endc


*************************************************************************************
*
* do loop without do error

LAB_LDER
	MOVEQ		#$22,d7			* error code $22 "LOOP without DO" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do undefined function error

LAB_UFER
	MOVEQ		#$20,d7			* error code $20 "Undefined function" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do can't continue error

LAB_CCER
	MOVEQ		#$1E,d7			* error code $1E "Can't continue" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do string too complex error

LAB_SCER
	MOVEQ		#$1C,d7			* error code $1C "String too complex" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do string too long error

LAB_SLER
	MOVEQ		#$1A,d7			* error code $1A "String too long" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do type missmatch error

LAB_TMER
	MOVEQ		#$18,d7			* error code $18 "Type mismatch" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do illegal direct error

LAB_IDER
	MOVEQ		#$16,d7			* error code $16 "Illegal direct" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do divide by zero error

LAB_DZER
	MOVEQ		#$14,d7			* error code $14 "Divide by zero" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do double dimension error

LAB_DDER
	MOVEQ		#$12,d7			* error code $12 "Double dimension" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do array bounds error

LAB_ABER
	MOVEQ		#$10,d7			* error code $10 "Array bounds" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do undefined satement error

LAB_USER
	MOVEQ		#$0E,d7			* error code $0E "Undefined statement" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do out of memory error

LAB_OMER
	MOVEQ		#$0C,d7			* error code $0C "Out of memory" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do overflow error

LAB_OFER
	MOVEQ		#$0A,d7			* error code $0A "Overflow" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do function call error

LAB_FCER
	MOVEQ		#$08,d7			* error code $08 "Function call" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do out of data error

LAB_ODER
	MOVEQ		#$06,d7			* error code $06 "Out of DATA" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do return without gosub error

LAB_RGER
	MOVEQ		#$04,d7			* error code $04 "RETURN without GOSUB" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do syntax error

LAB_SNER
	MOVEQ		#$02,d7			* error code $02 "Syntax" error
	BRA.s		LAB_XERR			* do error #d7, then warm start


*************************************************************************************
*
* do next without for error

LAB_NFER
	MOVEQ		#$00,d7			* error code $00 "NEXT without FOR" error


*************************************************************************************
*
* do error #d7, then warm start

LAB_XERR
	BSR		LAB_1491			* flush stack & clear continue flag
	BSR		LAB_CRLF			* print CR/LF
	LEA		LAB_BAER(pc),a1		* start of error message pointer table
	MOVE.w	(a1,d7.w),d7		* get error message offset
	LEA		(a1,d7.w),a0		* get error message address
	BSR		LAB_18C3			* print null terminated string from memory
	LEA		LAB_EMSG(pc),a0		* point to " Error" message
LAB_1269
	BSR		LAB_18C3			* print null terminated string from memory
	MOVE.l	Clinel(a3),d0		* get current line
	BMI.s		LAB_1274			* go do warm start if -ve # (was immediate mode)

							* else print line number
	BSR		LAB_2953			* print " in line [LINE #]"

* BASIC warm start entry point, wait for Basic command

LAB_1274
	LEA		LAB_RMSG(pc),a0		* point to "Ready" message
	BSR		LAB_18C3			* go do print string

* wait for Basic command - no "Ready"

LAB_127D
	MOVEQ		#-1,d1			* set to -1
	MOVE.l	d1,Clinel(a3)		* set current line #
	MOVE.b	d1,Breakf(a3)		* set break flag
	LEA		Ibuffs(a3),a5		* set basic execute pointer ready for new line
LAB_127E
	BSR		LAB_1357			* call for BASIC input
	BSR		LAB_GBYT			* scan memory
	BEQ.s		LAB_127E			* loop while null

* got to interpret input line now ....

	BCS.s		LAB_1295			* branch if numeric character, handle new
							* BASIC line

							* no line number so do immediate mode, a5
							* points to the buffer start
	BSR		LAB_13A6			* crunch keywords into Basic tokens
							* crunch from (a5), output to (a0)
							* returns ..
							* d2 is length, d1 trashed, d0 trashed,
							* a1 trashed
	BRA		LAB_15F6			* go scan & interpret code


*************************************************************************************
*
* handle a new BASIC line

LAB_1295
	BSR		LAB_GFPN			* get fixed-point number into temp integer & d1
	BSR		LAB_13A6			* crunch keywords into Basic tokens
							* crunch from (a5), output to (a0)
							* returns .. d2 is length,
							* d1 trashed, d0 trashed, a1 trashed
	MOVE.l	Itemp(a3),d1		* get required line #
	BSR		LAB_SSLN			* search BASIC for d1 line number
							* returns pointer in a0
	BCS.s		LAB_12E6			* branch if not found

							* aroooogah! line # already exists! delete it
	MOVEA.l	(a0),a1			* get start of block (next line pointer)
	MOVE.l	Sfncl(a3),d0		* get end of block (start of functions)
	SUB.l		a1,d0				* subtract start of block ( = bytes to move)
	LSR.l		#1,d0				* /2 (word move)
	SUBQ.l	#1,d0				* adjust for DBF loop
	SWAP		d0				* swap high word to low word
	MOVEA.l	a0,a2				* copy destination
LAB_12AE
	SWAP		d0				* swap high word to low word
LAB_12B0
	MOVE.w	(a1)+,(a2)+			* copy word
	DBF		d0,LAB_12B0			* decrement low count and loop until done

	SWAP		d0				* swap high word to low word
	DBF		d0,LAB_12AE			* decrement high count and loop until done

	MOVE.l	a2,Sfncl(a3)		* start of functions
	MOVE.l	a2,Svarl(a3)		* save start of variables
	MOVE.l	a2,Sstrl(a3)		* start of strings
	MOVE.l	a2,Sarryl(a3)		* save start of arrays
	MOVE.l	a2,Earryl(a3)		* save end of arrays

							* got new line in buffer and no existing same #
LAB_12E6
	MOVE.b	Ibuffs(a3),d0		* get byte from start of input buffer
	BEQ.s		LAB_1325			* if null line go do line chaining

							* got new line and it isn't empty line
	MOVEA.l	Sfncl(a3),a1		* get start of functions (end of block to move)
	LEA		8(a1,d2),a2			* copy it, add line length and add room for
							* pointer and line number

	MOVE.l	a2,Sfncl(a3)		* start of functions
	MOVE.l	a2,Svarl(a3)		* save start of variables
	MOVE.l	a2,Sstrl(a3)		* start of strings
	MOVE.l	a2,Sarryl(a3)		* save start of arrays
	MOVE.l	a2,Earryl(a3)		* save end of arrays
	MOVE.l	Ememl(a3),Sstorl(a3)	* copy end of mem to start of strings, clear
							* strings

	MOVE.l	a1,d1				* copy end of block to move
	SUB.l		a0,d1				* subtract start of block to move
	LSR.l		#1,d1				* /2 (word copy)
	SUBQ.l	#1,d1				* correct for loop end on -1
	SWAP		d1				* swap high word to low word
LAB_12FF
	SWAP		d1				* swap high word to low word
LAB_1301
	MOVE.w	-(a1),-(a2)			* decrement pointers and copy word
	DBF		d1,LAB_1301			* decrement & loop

	SWAP		d1				* swap high word to low word
	DBF		d1,LAB_12FF			* decrement high count and loop until done

* space is opened up, now copy the crunched line from the input buffer into the space

	LEA		Ibuffs(a3),a1		* source is input buffer
	MOVEA.l	a0,a2				* copy destination
	MOVEQ		#-1,d1			* set to allow re-chaining
	MOVE.l	d1,(a2)+			* set next line pointer (allow re-chaining)
	MOVE.l	Itemp(a3),(a2)+		* save line number
	LSR.w		#1,d2				* /2 (word copy)
	SUBQ.w	#1,d2				* correct for loop end on -1
LAB_1303
	MOVE.w	(a1)+,(a2)+			* copy word
	DBF		d2,LAB_1303			* decrement & loop

	BRA.s		LAB_1325			* go test for end of prog

* rebuild chaining of BASIC lines

LAB_132E
	ADDQ.w	#8,a0				* point to first code byte of line, there is
							* always 1 byte + [EOL] as null entries are
							* deleted
LAB_1330
	TST.b		(a0)+				* test byte	
	BNE.s		LAB_1330			* loop if not [EOL]

							* was [EOL] so get next line start
	MOVE.w	a0,d1				* past pad byte(s)
	ANDI.w	#1,d1				* mask odd bit
	ADD.w		d1,a0				* add back to ensure even
	MOVE.l	a0,(a1)			* save next line pointer to current line
LAB_1325
	MOVEA.l	a0,a1				* copy pointer for this line
	TST.l		(a0)				* test pointer to next line
	BNE.s		LAB_132E			* not end of program yet so we must
							* go and fix the pointers

	BSR		LAB_1477			* reset execution to start, clear variables
							* and flush stack
	BRA		LAB_127D			* now we just wait for Basic command, no "Ready"


*************************************************************************************
*
* receive a line from the keyboard
							* character $08 as delete key, BACKSPACE on
							* standard keyboard
LAB_134B
	BSR		LAB_PRNA			* go print the character
	MOVEQ		#' ',d0			* load [SPACE]
	BSR		LAB_PRNA			* go print
	MOVEQ		#$08,d0			* load [BACKSPACE]
	BSR		LAB_PRNA			* go print
	SUBQ.w	#$01,d1			* decrement the buffer index (delete)
	BRA.s		LAB_1359			* re-enter loop

* print "? " and get BASIC input
* return a0 pointing to the buffer start

LAB_INLN
	BSR		LAB_18E3			* print "?" character
	MOVEQ		#' ',d0			* load " "
	BSR		LAB_PRNA			* go print

* call for BASIC input (main entry point)
* return a0 pointing to the buffer start

LAB_1357
	MOVEQ		#$00,d1			* clear buffer index
	LEA		Ibuffs(a3),a0		* set buffer base pointer
LAB_1359
	JSR		V_INPT(a3)			* call scan input device
	BCC.s		LAB_1359			* loop if no byte

	BEQ.s		LAB_1359			* loop if null byte

	CMP.b		#$07,d0			* compare with [BELL]
	BEQ.s		LAB_1378			* branch if [BELL]

	CMP.b		#$0D,d0			* compare with [CR]
	BEQ		LAB_1866			* do CR/LF exit if [CR]

	TST.w		d1				* set flags on buffer index
	BNE.s		LAB_1374			* branch if not empty

* the next two lines ignore any non printing character and [SPACE] if the input buffer
* is empty

	CMP.b		#' ',d0			* compare with [SP]+1
	BLS.s		LAB_1359			* if < ignore character

*##	CMP.b		#' '+1,d0			* compare with [SP]+1
*##	BCS.s		LAB_1359			* if < ignore character

LAB_1374
	CMP.b		#$08,d0			* compare with [BACKSPACE]
	BEQ.s		LAB_134B			* go delete last character

LAB_1378
	CMP.w		#(Ibuffe-Ibuffs-1),d1	* compare character count with max-1
	BCC.s		LAB_138E			* skip store & do [BELL] if buffer full

	MOVE.b	d0,(a0,d1.w)		* else store in buffer
	ADDQ.w	#$01,d1			* increment index
LAB_137F
	BSR		LAB_PRNA			* go print the character
	BRA.s		LAB_1359			* always loop for next character

* announce buffer full

LAB_138E
	MOVEQ		#$07,d0			* [BELL] character into d0
	BRA.s		LAB_137F			* go print the [BELL] but ignore input character


*************************************************************************************
*
* copy a hex value without crunching

LAB_1392
	MOVE.b	d0,(a0,d2.w)		* save the byte to the output
	ADDQ.w	#1,d2				* increment the buffer save index

	ADDQ.w	#1,d1				* increment the buffer read index
	MOVE.b	(a5,d1.w),d0		* get a byte from the input buffer
	BEQ		LAB_13EC			* if [EOL] go save it without crunching

	CMP.b		#' ',d0			* compare the character with " "
	BEQ.s		LAB_1392			* if [SPACE] just go save it and get another

	CMP.b		#'0',d0			* compare the character with "0"
	BCS.s		LAB_13C6			* if < "0" quit the hex save loop

	CMP.b		#'9',d0			* compare with "9"
	BLS.s		LAB_1392			* if it is "0" to "9" save it and get another

	MOVEQ		#-33,d5			* mask xx0x xxxx, ASCII upper case
	AND.b		d0,d5				* mask the character

	CMP.b		#'A',d5			* compare with "A"
	BCS.s		LAB_13CC			* if < "A" quit the hex save loop

	CMP.b		#'F',d5			* compare with "F"
	BLS.s		LAB_1392			* if it is "A" to "F" save it and get another

	BRA.s		LAB_13CC			* else continue crunching

* crunch keywords into Basic tokens
* crunch from (a5), output to (a0)
* returns ..
* d4 trashed
* d3 trashed
* d2 is length
* d1 trashed
* d0 trashed
* a1 trashed

* this is the improved BASIC crunch routine and is 10 to 100 times faster than the
* old list search

LAB_13A6
	MOVEQ		#0,d1				* clear the read index
	MOVE.l	d1,d2				* clear the save index
	MOVE.b	d1,Oquote(a3)		* clear the open quote/DATA flag
LAB_13AC
	MOVEQ		#0,d0				* clear word
	MOVE.b	(a5,d1.w),d0		* get byte from input buffer
	BEQ.s		LAB_13EC			* if null save byte then continue crunching

	CMP.b		#'_',d0			* compare with "_"
	BCC.s		LAB_13EC			* if >= "_" save byte then continue crunching

	CMP.b		#'<',d0			* compare with "<"
	BCC.s		LAB_13CC			* if >= "<" go crunch

	CMP.b		#'0',d0			* compare with "0"
	BCC.s		LAB_13EC			* if >= "0" save byte then continue crunching

	MOVE.b	d0,Asrch(a3)		* save buffer byte as search character
	CMP.b		#$22,d0			* is it quote character?
	BEQ.s		LAB_1410			* branch if so (copy quoted string)

	CMP.b		#'$',d0			* is it the hex value character?
	BEQ.s		LAB_1392			* if so go copy a hex value

LAB_13C6
	CMP.b		#'*',d0			* compare with "*"
	BCS.s		LAB_13EC			* if <= "*" save byte then continue crunching

							* crunch rest
LAB_13CC
	BTST.b	#6,Oquote(a3)		* test open quote/DATA token flag
	BNE.s		LAB_13EC			* branch if b6 of Oquote set (was DATA)
							* go save byte then continue crunching

	SUB.b		#$2A,d0			* normalise byte
	ADD.w		d0,d0				* *2 makes word offset (high byte=$00)
	LEA		TAB_CHRT(pc),a1		* get keyword offset table address
	MOVE.w	(a1,d0.w),d0		* get offset into keyword table
	BMI.s		LAB_141F			* branch if no keywords for character

	LEA		TAB_STAR(pc),a1		* get keyword table address
	ADDA.w	d0,a1				* add keyword offset
	MOVEQ		#-1,d3			* clear index
	MOVE.w	d1,d4				* copy read index
LAB_13D6
	ADDQ.w	#1,d3				* increment table index
	MOVE.b	(a1,d3.w),d0		* get byte from table
LAB_13D8
	BMI.s		LAB_13EA			* branch if token, save token and continue
							* crunching

	ADDQ.w	#1,d4				* increment read index
	CMP.b		(a5,d4.w),d0		* compare byte from input buffer
	BEQ.s		LAB_13D6			* loop if character match

	BRA.s		LAB_1417			* branch if no match

LAB_13EA
	MOVE.w	d4,d1				* update read index
LAB_13EC
	MOVE.b	d0,(a0,d2.w)		* save byte to output
	ADDQ.w	#1,d2				* increment buffer save index
	ADDQ.w	#1,d1				* increment buffer read index
	TST.b		d0				* set flags
	BEQ.s		LAB_142A			* branch if was null [EOL]

							* d0 holds token or byte here
	SUB.b		#$3A,d0			* subtract ":"
	BEQ.s		LAB_13FF			* branch if it was ":" (is now $00)

							* d0 now holds token-$3A
	CMP.b		#(TK_DATA-$3A),d0		* compare with DATA token - $3A
	BNE.s		LAB_1401			* branch if not DATA

							* token was : or DATA
LAB_13FF
	MOVE.b	d0,Oquote(a3)		* save token-$3A ($00 for ":", TK_DATA-$3A for
							* DATA)
LAB_1401
	SUB.b		#(TK_REM-$3A),d0		* subtract REM token offset
	BNE		LAB_13AC			* If wasn't REM then go crunch rest of line

	MOVE.b	d0,Asrch(a3)		* else was REM so set search for [EOL]

							* loop for REM, "..." etc.
LAB_1408
	MOVE.b	(a5,d1.w),d0		* get byte from input buffer
	BEQ.s		LAB_13EC			* branch if null [EOL]

	CMP.b		Asrch(a3),d0		* compare with stored character
	BEQ.s		LAB_13EC			* branch if match (end quote, REM, :, or DATA)

							* entry for copy string in quotes, don't crunch
LAB_1410
	MOVE.b	d0,(a0,d2.w)		* save byte to output
	ADDQ.w	#1,d2				* increment buffer save index
	ADDQ.w	#1,d1				* increment buffer read index
	BRA.s		LAB_1408			* loop

* not found keyword this go so find the end of this word in the table

LAB_1417
	MOVE.w	d1,d4				* reset read pointer
LAB_141B
	ADDQ.w	#1,d3				* increment keyword table pointer, flag
							* unchanged
	MOVE.b	(a1,d3.w),d0		* get keyword table byte
	BPL.s		LAB_141B			* if not end of keyword go do next byte

	ADDQ.w	#1,d3				* increment keyword table pointer flag
							* unchanged
	MOVE.b	(a1,d3.w),d0		* get keyword table byte
	BNE.s		LAB_13D8			* go test next word if not zero byte (table end)

							* reached end of table with no match
LAB_141F
	MOVE.b	(a5,d1.w),d0		* restore byte from input buffer
	BRA.s		LAB_13EC			* go save byte in output and continue crunching

							* reached [EOL]
LAB_142A
	MOVEQ		#0,d0				* ensure longword clear
	BTST		d0,d2				* test odd bit (fastest)
	BEQ.s		LAB_142C			* branch if no bytes to fill

	MOVE.b	d0,(a0,d2.w)		* clear next byte
	ADDQ.w	#1,d2				* increment buffer save index
LAB_142C
	MOVE.l	d0,(a0,d2.w)		* clear next line pointer, EOT in immediate mode
	RTS


*************************************************************************************
*
* search Basic for d1 line number from start of mem

LAB_SSLN
	MOVEA.l	Smeml(a3),a0		* get start of program mem
	BRA.s		LAB_SCLN			* go search for required line from a0

LAB_145F
	MOVEA.l	d0,a0				* copy next line pointer

* search Basic for d1 line number from a0
* returns Cb=0 if found
* returns a0 pointer to found or next higher (not found) line

LAB_SCLN
	MOVE.l	(a0)+,d0			* get next line pointer and point to line #
	BEQ.s		LAB_145E			* is end marker so we're done, do 'no line' exit

	CMP.l		(a0),d1			* compare this line # with required line #
	BGT.s		LAB_145F			* loop if required # > this #

	SUBQ.w	#4,a0				* adjust pointer, flags not changed
	RTS

LAB_145E
	SUBQ.w	#4,a0				* adjust pointer, flags not changed
	SUBQ.l	#1,d0				* make end program found = -1, set carry
	RTS


*************************************************************************************
*
* perform NEW

LAB_NEW
	BNE.s		RTS_005			* exit if not end of statement (do syntax error)

LAB_1463
	MOVEA.l	Smeml(a3),a0		* point to start of program memory
	MOVEQ		#0,d0				* clear longword
	MOVE.l	d0,(a0)+			* clear first line, next line pointer
	MOVE.l	a0,Sfncl(a3)		* set start of functions

* reset execution to start, clear variables and flush stack

LAB_1477
	MOVEA.l	Smeml(a3),a5		* reset BASIC execute pointer
	SUBQ.w	#1,a5				* -1 (as end of previous line)

* "CLEAR" command gets here

LAB_147A
	MOVE.l	Ememl(a3),Sstorl(a3)	* save end of mem as bottom of string space
	MOVE.l	Sfncl(a3),d0		* get start of functions
	MOVE.l	d0,Svarl(a3)		* start of variables
	MOVE.l	d0,Sstrl(a3)		* start of strings
	MOVE.l	d0,Sarryl(a3)		* set start of arrays
	MOVE.l	d0,Earryl(a3)		* set end of arrays
LAB_1480
	MOVEQ		#0,d0				* set Zb
	MOVE.b	d0,ccnull(a3)		* clear get byte countdown
	BSR		LAB_RESTORE			* perform RESTORE command

* flush stack & clear continue flag

LAB_1491
	LEA		des_sk(a3),a4		* reset descriptor stack pointer

	MOVE.l	(sp)+,d0			* pull return address
	LEA		ram_base(a3),sp		* set stack to RAM start + 1k, flush stack
	MOVE.l	d0,-(sp)			* restore return address

	MOVEQ		#0,d0				* clear longword
	MOVE.l	d0,Cpntrl(a3)		* clear continue pointer
	MOVE.b	d0,Sufnxf(a3)		* clear subscript/FNX flag
RTS_005
	RTS


*************************************************************************************
*
* perform CLEAR

LAB_CLEAR
	BEQ.s		LAB_147A			* if no following byte go do "CLEAR"

	RTS						* was following byte (go do syntax error)


*************************************************************************************
*
* perform LIST [n][-m]

LAB_LIST
	BCS.s		LAB_14BD			* branch if next character numeric (LIST n...)

	MOVEQ		#-1,d1			* set end to $FFFFFFFF
	MOVE.l	d1,Itemp(a3)		* save to Itemp

	MOVEQ		#0,d1				* set start to $00000000
	TST.b		d0				* test next byte
	BEQ.s		LAB_14C0			* branch if next character [NULL] (LIST)

	CMP.b		#TK_MINUS,d0		* compare with token for -
	BNE.s		RTS_005			* exit if not - (LIST -m)

							* LIST [[n]-[m]] this sets the n, if present,
							* as the start and end
LAB_14BD
	BSR		LAB_GFPN			* get fixed-point number into temp integer & d1
LAB_14C0
	BSR		LAB_SSLN			* search BASIC for d1 line number
							* (pointer in a0)
	BSR		LAB_GBYT			* scan memory
	BEQ.s		LAB_14D4			* branch if no more characters

							* this bit checks the - is present
	CMP.b		#TK_MINUS,d0		* compare with token for -
	BNE.s		RTS_005			* return if not "-" (will be Syntax error)

	MOVEQ		#-1,d1			* set end to $FFFFFFFF
	MOVE.l	d1,Itemp(a3)		* save Itemp

							* LIST [n]-[m] the - was there so see if
							* there is an m to set as the end value
	BSR		LAB_IGBY			* increment & scan memory
	BEQ.s		LAB_14D4			* branch if was [NULL] (LIST n-)

	BSR		LAB_GFPN			* get fixed-point number into temp integer & d1
LAB_14D4
	MOVE.b	#$00,Oquote(a3)		* clear open quote flag
	BSR		LAB_CRLF			* print CR/LF
	MOVE.l	(a0)+,d0			* get next line pointer
	BEQ.s		RTS_005			* if null all done so exit

	MOVEA.l	d0,a1				* copy next line pointer
	BSR		LAB_1629			* do CRTL-C check vector

	MOVE.l	(a0)+,d0			* get this line #
	CMP.l		Itemp(a3),d0		* compare end line # with this line #
	BHI.s		RTS_005			* if this line greater all done so exit

LAB_14E2
	MOVEM.l	a0-a1,-(sp)			* save registers
	BSR		LAB_295E			* print d0 as unsigned integer
	MOVEM.l	(sp)+,a0-a1			* restore registers
	MOVEQ		#$20,d0			* space is the next character
LAB_150C
	BSR		LAB_PRNA			* go print the character
	CMP.b		#$22,d0			* was it " character
	BNE.s		LAB_1519			* branch if not

							* we're either entering or leaving quotes
	EOR.b		#$FF,Oquote(a3)		* toggle open quote flag
LAB_1519
	MOVE.b	(a0)+,d0			* get byte and increment pointer
	BNE.s		LAB_152E			* branch if not [EOL] (go print)

							* was [EOL]
	MOVEA.l	a1,a0				* copy next line pointer
	MOVE.l	a0,d0				* copy to set flags
	BNE.s		LAB_14D4			* go do next line if not [EOT]

	RTS

LAB_152E
	BPL.s		LAB_150C			* just go print it if not token byte

							* else it was a token byte so maybe uncrunch it
	TST.b		Oquote(a3)			* test the open quote flag
	BMI.s		LAB_150C			* just go print character if open quote set

							* else uncrunch BASIC token
	LEA		LAB_KEYT(pc),a2		* get keyword table address
	MOVEQ		#$7F,d1			* mask into d1
	AND.b		d0,d1				* copy and mask token
	LSL.w		#2,d1				* *4
	LEA		(a2,d1.w),a2		* get keyword entry address
	MOVE.b	(a2)+,d0			* get byte from keyword table
	BSR		LAB_PRNA			* go print the first character
	MOVEQ		#0,d1				* clear d1
	MOVE.b	(a2)+,d1			* get remaining length byte from keyword table
	BMI.s		LAB_1519			* if -ve done so go get next byte

	MOVE.w	(a2),d0			* get offset to rest
	LEA		TAB_STAR(pc),a2		* get keyword table address
	LEA		(a2,d0.w),a2		* get address of rest
LAB_1540
	MOVE.b	(a2)+,d0			* get byte from keyword table
	BSR		LAB_PRNA			* go print the character
	DBF		d1,LAB_1540			* decrement and loop if more to do

	BRA.s		LAB_1519			* go get next byte


*************************************************************************************
*
* perform FOR

LAB_FOR
	BSR		LAB_LET			* go do LET

	MOVE.l	Lvarpl(a3),d0		* get the loop variable pointer
	CMP.l		Sstrl(a3),d0		* compare it with the end of vars memory
	BGE		LAB_TMER			* if greater go do type mismatch error

* test for not less than the start of variables memory if needed
*
*	CMP.l		Svarl(a3),d0		* compare it with the start of variables memory
*	BLT		LAB_TMER			* if not variables memory do type mismatch error

*	MOVEQ		#28,d0			* we need 28 bytes !
*	BSR.s		LAB_1212			* check room on stack for d0 bytes

	BSR		LAB_SNBS			* scan for next BASIC statement ([:] or [EOL])
							* returns a0 as pointer to [:] or [EOL]
	MOVE.l	a0,(sp)			* push onto stack (and dump the return address)
	MOVE.l	Clinel(a3),-(sp)		* push current line onto stack

	MOVEQ		#TK_TO-$100,d0		* set "TO" token
	BSR		LAB_SCCA			* scan for CHR$(d0) else syntax error/warm start
	BSR		LAB_CTNM			* check if source is numeric, else type mismatch
	MOVE.b	Dtypef(a3),-(sp)		* push the FOR variable data type onto stack
	BSR		LAB_EVNM			* evaluate expression and check is numeric else
							* do type mismatch

	MOVE.l	FAC1_m(a3),-(sp)		* push TO value mantissa
	MOVE.w	FAC1_e(a3),-(sp)		* push TO value exponent and sign

	MOVE.l	#$80000000,FAC1_m(a3)	* set default STEP size mantissa
	MOVE.w	#$8100,FAC1_e(a3)		* set default STEP size exponent and sign

	BSR		LAB_GBYT			* scan memory
	CMP.b		#TK_STEP,d0			* compare with STEP token
	BNE.s		LAB_15B3			* jump if not "STEP"

							* was STEP token so ....
	BSR		LAB_IGBY			* increment & scan memory
	BSR		LAB_EVNM			* evaluate expression & check is numeric
							* else do type mismatch
LAB_15B3
	MOVE.l	FAC1_m(a3),-(sp)		* push STEP value mantissa
	MOVE.w	FAC1_e(a3),-(sp)		* push STEP value exponent and sign

	MOVE.l	Lvarpl(a3),-(sp)		* push variable pointer for FOR/NEXT
	MOVE.w	#TK_FOR,-(sp)		* push FOR token on stack

	BRA.s		LAB_15C2			* go do interpreter inner loop

LAB_15DC						* have reached [EOL]+1
	MOVE.w	a5,d0				* copy BASIC execute pointer
	AND.w		#1,d0				* and make line start address even
	ADD.w		d0,a5				* add to BASIC execute pointer
	MOVE.l	(a5)+,d0			* get next line pointer
	BEQ		LAB_1274			* if null go to immediate mode, no "BREAK"
							* message (was immediate or [EOT] marker)

	MOVE.l	(a5)+,Clinel(a3)		* save (new) current line #
LAB_15F6
	BSR		LAB_GBYT			* get BASIC byte
	BSR.s		LAB_15FF			* go interpret BASIC code from (a5)

* interpreter inner loop (re)entry point

LAB_15C2
	BSR.s		LAB_1629			* do CRTL-C check vector
	TST.b		Clinel(a3)			* test current line #, is -ve for immediate mode
	BMI.s		LAB_15D1			* branch if immediate mode

	MOVE.l	a5,Cpntrl(a3)		* save BASIC execute pointer as continue pointer
LAB_15D1
	MOVE.b	(a5)+,d0			* get this byte & increment pointer
	BEQ.s		LAB_15DC			* loop if [EOL]

	CMP.b		#$3A,d0			* compare with ":"
	BEQ.s		LAB_15F6			* loop if was statement separator

	BRA		LAB_SNER			* else syntax error, then warm start


*************************************************************************************
*
* interpret BASIC code from (a5)

LAB_15FF
	BEQ		RTS_006			* exit if zero [EOL]

LAB_1602
	EORI.b	#$80,d0			* normalise token
	BMI		LAB_LET			* if not token, go do implied LET

	CMP.b		#(TK_TAB-$80),d0		* compare normalised token with TAB
	BCC		LAB_SNER			* branch if d0>=TAB, syntax error/warm start
							* only tokens before TAB can start a statement

	EXT.w		d0				* byte to word (clear high byte)
	ADD.w		d0,d0				* *2
	LEA		LAB_CTBL(pc),a0		* get vector table base address
	MOVE.w	(a0,d0.w),d0		* get offset to vector
	PEA		(a0,d0.w)			* push vector
	BRA		LAB_IGBY			* get following byte & execute vector


*************************************************************************************
*
* CTRL-C check jump. this is called as a subroutine but exits back via a jump if a
* key press is detected.

LAB_1629
	JMP		V_CTLC(a3)			* ctrl c check vector

* if there was a key press it gets back here .....

LAB_1636
	CMP.b		#$03,d0			* compare with CTRL-C
	BEQ.s		LAB_163B			* STOP if was CTRL-C

LAB_1639
	RTS						*


*************************************************************************************
*
* perform END

LAB_END
	BNE.s		LAB_1639			* exit if something follows STOP
	MOVE.b	#0,Breakf(a3)		* clear break flag, indicate program end


*************************************************************************************
*
* perform STOP

LAB_STOP
	BNE.s		LAB_1639			* exit if something follows STOP

LAB_163B
	LEA		Ibuffe(a3),a1		* get buffer end
	CMPA.l	a1,a5				* compare execute address with buffer end
	BCS.s		LAB_164F			* branch if BASIC pointer is in buffer
							* can't continue in immediate mode

							* else...
	MOVE.l	a5,Cpntrl(a3)		* save BASIC execute pointer as continue pointer
LAB_1647
	MOVE.l	Clinel(a3),Blinel(a3)	* save break line
LAB_164F
	ADDQ.w	#4,sp				* dump return address, don't return to execute
							* loop
	MOVE.b	Breakf(a3),d0		* get break flag
	BEQ		LAB_1274			* go do warm start if was program end

	LEA		LAB_BMSG(pc),a0		* point to "Break"
	BRA		LAB_1269			* print "Break" and do warm start


*************************************************************************************
*
* perform RESTORE

LAB_RESTORE
	MOVEA.l	Smeml(a3),a0		* copy start of memory
	BEQ.s		LAB_1624			* branch if next character null (RESTORE)

	BSR		LAB_GFPN			* get fixed-point number into temp integer & d1
	CMP.l		Clinel(a3),d1		* compare current line # with required line #
	BLS.s		LAB_GSCH			* branch if >= (start search from beginning)

	MOVEA.l	a5,a0				* copy BASIC execute pointer
LAB_RESs
	TST.b		(a0)+				* test next byte & increment pointer
	BNE.s		LAB_RESs			* loop if not EOL

	MOVE.w	a0,d0				* copy pointer
	AND.w		#1,d0				* mask odd bit
	ADD.w		d0,a0				* add pointer
							* search for line in Itemp from (a0)
LAB_GSCH
	BSR		LAB_SCLN			* search for d1 line number from a0
							* returns Cb=0 if found
	BCS		LAB_USER			* go do "Undefined statement" error if not found

LAB_1624
	TST.b		-(a0)				* decrement pointer (faster)
	MOVE.l	a0,Dptrl(a3)		* save DATA pointer
RTS_006
	RTS


*************************************************************************************
*
* perform NULL

LAB_NULL
	BSR		LAB_GTBY			* get byte parameter, result in d0 and Itemp
	MOVE.b	d0,Nullct(a3)		* save new NULL count
	RTS


*************************************************************************************
*
* perform CONT

LAB_CONT
	BNE		LAB_SNER			* if following byte exit to do syntax error

	TST.b		Clinel(a3)			* test current line #, is -ve for immediate mode
	BPL		LAB_CCER			* if running go do can't continue error

	MOVE.l	Cpntrl(a3),d0		* get continue pointer
	BEQ		LAB_CCER			* go do can't continue error if we can't

							* we can continue so ...
	MOVEA.l	d0,a5				* save continue pointer as BASIC execute pointer
	MOVE.l	Blinel(a3),Clinel(a3)	* set break line as current line
	RTS


*************************************************************************************
*
* perform RUN

LAB_RUN
	BNE.s		LAB_RUNn			* if following byte do RUN n

	BSR		LAB_1477			* execution to start, clear vars & flush stack
	MOVE.l	a5,Cpntrl(a3)		* save as continue pointer
	BRA		LAB_15C2			* go do interpreter inner loop
							* (can't RTS, we flushed the stack!)

LAB_RUNn
	BSR		LAB_147A			* go do "CLEAR"
	BRA.s		LAB_16B0			* get n and do GOTO n


*************************************************************************************
*
* perform DO

LAB_DO
*	MOVE.l	#$05,d0			* need 5 bytes for DO
*	BSR.s		LAB_1212			* check room on stack for A bytes
	MOVE.l	a5,-(sp)			* push BASIC execute pointer on stack
	MOVE.l	Clinel(a3),-(sp)		* push current line on stack
	MOVE.w	#TK_DO,-(sp)		* push token for DO on stack
	PEA		LAB_15C2(pc)		* set return address
	BRA		LAB_GBYT			* scan memory & return to interpreter inner loop


*************************************************************************************
*
* perform GOSUB

LAB_GOSUB
*	MOVE.l	#10,d0			* need 10 bytes for GOSUB
*	BSR.s		LAB_1212			* check room on stack for d0 bytes
	MOVE.l	a5,-(sp)			* push BASIC execute pointer
	MOVE.l	Clinel(a3),-(sp)		* push current line
	MOVE.w	#TK_GOSUB,-(sp)		* push token for GOSUB
LAB_16B0
	BSR		LAB_GBYT			* scan memory
	PEA		LAB_15C2(pc)		* return to interpreter inner loop after GOTO n

* this PEA is needed because either we just cleared the stack and have nowhere to return
* to or, in the case of GOSUB, we have just dropped a load on the stack and the address
* we whould have returned to is buried. This burried return address will be unstacked by
* the corresponding RETURN command


*************************************************************************************
*
* perform GOTO

LAB_GOTO
	BSR		LAB_GFPN			* get fixed-point number into temp integer & d1
	MOVEA.l	Smeml(a3),a0		* get start of memory
	CMP.l		Clinel(a3),d1		* compare current line with wanted #
	BLS.s		LAB_16D0			* branch if current # => wanted #

	MOVEA.l	a5,a0				* copy BASIC execute pointer
LAB_GOTs
	TST.b		(a0)+				* test next byte & increment pointer
	BNE.s		LAB_GOTs			* loop if not EOL

	MOVE.w	a0,d0				* past pad byte(s)
	AND.w		#1,d0				* mask odd bit
	ADD.w		d0,a0				* add to pointer

LAB_16D0
	BSR		LAB_SCLN			* search for d1 line number from a0
							* returns Cb=0 if found
	BCS		LAB_USER			* if carry set go do "Undefined statement" error

	MOVEA.l	a0,a5				* copy to basic execute pointer
	SUBQ.w	#1,a5				* decrement pointer
	MOVE.l	a5,Cpntrl(a3)		* save as continue pointer
	RTS


*************************************************************************************
*
* perform LOOP

LAB_LOOP
	CMP.w		#TK_DO,4(sp)		* compare token on stack with DO token
	BNE		LAB_LDER			* branch if no matching DO

	MOVE.b	d0,d7				* copy following token (byte)
	BEQ.s		LoopAlways			* if no following token loop forever

	CMP.b		#':',d7			* compare with ":"
	BEQ.s		LoopAlways			* if no following token loop forever

	SUB.b		#TK_UNTIL,d7		* subtract token for UNTIL
	BEQ.s		DoRest			* branch if was UNTIL

	SUBQ.b	#1,d7				* decrement result
	BNE		LAB_SNER			* if not WHILE go do syntax error & warm start
							* only if the token was WHILE will this fail

	MOVEQ		#-1,d7			* set invert result longword
DoRest
	BSR		LAB_IGBY			* increment & scan memory
	BSR		LAB_EVEX			* evaluate expression
	TST.b		FAC1_e(a3)			* test FAC1 exponent
	BEQ.s		DoCmp				* if = 0 go do straight compare

	MOVE.b	#$FF,FAC1_e(a3)		* else set all bits
DoCmp
	EOR.b		d7,FAC1_e(a3)		* EOR with invert byte
	BNE.s		LoopDone			* if <> 0 clear stack & back to interpreter loop

							* loop condition wasn't met so do it again
LoopAlways
	MOVE.l	6(sp),Clinel(a3)		* copy DO current line
	MOVE.l	10(sp),a5			* save BASIC execute pointer

	LEA		LAB_15C2(pc),a0		* get return address
	MOVE.l	a0,(sp)			* dump the call to this routine and set the
							* return address
	BRA		LAB_GBYT			* scan memory and return to interpreter inner
							* loop

							* clear stack & back to interpreter loop
LoopDone
	LEA		14(sp),sp			* dump structure and call from stack
	BRA.s		LAB_DATA			* go perform DATA (find : or [EOL])


*************************************************************************************
*
* perform RETURN

LAB_RETURN
	BNE.s		RTS_007			* exit if following token to allow syntax error

	CMP.w		#TK_GOSUB,4(sp)		* compare token from stack with GOSUB
	BNE		LAB_RGER			* do RETURN without GOSUB error if no matching
							* GOSUB

	ADDQ.w	#6,sp				* dump calling address & token
	MOVE.l	(sp)+,Clinel(a3)		* pull current line
	MOVE.l	(sp)+,a5			* pull BASIC execute pointer
							* now do perform "DATA" statement as we could be
							* returning into the middle of an ON <var> GOSUB
							* n,m,p,q line (the return address used by the
							* DATA statement is the one pushed before the
							* GOSUB was executed!)


*************************************************************************************
*
* perform DATA

LAB_DATA
	BSR.s		LAB_SNBS			* scan for next BASIC statement ([:] or [EOL])
							* returns a0 as pointer to [:] or [EOL]
	MOVEA.l	a0,a5				* skip rest of statement
RTS_007
	RTS


*************************************************************************************
*
* scan for next BASIC statement ([:] or [EOL])
* returns a0 as pointer to [:] or [EOL]

LAB_SNBS
	MOVEA.l	a5,a0				* copy BASIC execute pointer
	MOVEQ		#$22,d1			* set string quote character
	MOVEQ		#$3A,d2			* set look for character = ":"
	BRA.s		LAB_172D			* go do search

LAB_172C
	CMP.b		d0,d2				* compare with ":"
	BEQ.s		RTS_007a			* exit if found

	CMP.b		d0,d1				* compare with '"'
	BEQ.s		LAB_1725			* if found go search for [EOL]

LAB_172D
	MOVE.b	(a0)+,d0			* get next byte
	BNE.s		LAB_172C			* loop if not null [EOL]

RTS_007a
	SUBQ.w	#1,a0				* correct pointer
	RTS

LAB_1723
	CMP.b		d0,d1				* compare with '"'
	BEQ.s		LAB_172D			* if found go search for ":" or [EOL]

LAB_1725
	MOVE.b	(a0)+,d0			* get next byte
	BNE.s		LAB_1723			* loop if not null [EOL]

	BRA.s		RTS_007a			* correct pointer & return


*************************************************************************************
*
* perform IF

LAB_IF
	BSR		LAB_EVEX			* evaluate expression
	BSR		LAB_GBYT			* scan memory
	CMP.b		#TK_THEN,d0			* compare with THEN token
	BEQ.s		LAB_174B			* if it was THEN then continue

							* wasn't IF .. THEN so must be IF .. GOTO
	CMP.b		#TK_GOTO,d0			* compare with GOTO token
	BNE		LAB_SNER			* if not GOTO token do syntax error/warm start

							* was GOTO so check for GOTO <n>
	MOVE.l	a5,a0				* save the execute pointer
	BSR		LAB_IGBY			* scan memory, test for a numeric character
	MOVE.l	a0,a5				* restore the execute pointer
	BCC		LAB_SNER			* if not numeric do syntax error/warm start

LAB_174B
	MOVE.b	FAC1_e(a3),d0		* get FAC1 exponent
	BEQ.s		LAB_174E			* if result was zero go look for an ELSE

	BSR		LAB_IGBY			* increment & scan memory
	BCS		LAB_GOTO			* if numeric do GOTO n
							* a GOTO <n> will never return to the IF
							* statement so there is no need to return
							* to this code

	CMP.b		#TK_RETURN,d0		* compare with RETURN token
	BEQ		LAB_1602			* if RETURN then interpret BASIC code from (a5)
							* and don't return here

	BSR		LAB_15FF			* else interpret BASIC code from (a5)

* the IF was executed and there may be a following ELSE so the code needs to return
* here to check and ignore the ELSE if present

	MOVE.b	(a5),d0			* get the next basic byte
	CMP.b		#TK_ELSE,d0			* compare it with the token for ELSE
	BEQ		LAB_DATA			* if ELSE ignore the following statement

* there was no ELSE so continue execution of IF <expr> THEN <stat> [: <stat>]. any
* following ELSE will, correctly, cause a syntax error

	RTS						* else return to interpreter inner loop

* perform ELSE after IF

LAB_174E
	MOVE.b	(a5)+,d0			* faster increment past THEN
	MOVEQ		#TK_ELSE,d3			* set search for ELSE token
	MOVEQ		#TK_IF,d4			* set search for IF token
	MOVEQ		#0,d5				* clear the nesting depth
LAB_1750
	MOVE.b	(a5)+,d0			* get next BASIC byte & increment ptr
	BEQ.s		LAB_1754			* if EOL correct the pointer and return

	CMP.b		d4,d0				* compare with "IF" token
	BNE.s		LAB_1752			* skip if not nested IF

	ADDQ.w	#1,d5				* else increment the nesting depth ..
	BRA.s		LAB_1750			* .. and continue looking

LAB_1752
	CMP.b		d3,d0				* compare with ELSE token
	BNE.s		LAB_1750			* if not ELSE continue looking

LAB_1756
	DBF		d5,LAB_1750			* loop if still nested

* found the matching ELSE, now do <{n|statement}>

	BSR		LAB_GBYT			* scan memory
	BCS		LAB_GOTO			* if numeric do GOTO n
							* code will return to the interpreter loop
							* at the tail end of the GOTO <n>

	BRA		LAB_15FF			* else interpret BASIC code from (a5)
							* code will return to the interpreter loop
							* at the tail end of the <statement>


*************************************************************************************
*
* perform REM, skip (rest of) line

LAB_REM
	TST.b		(a5)+				* test byte & increment pointer
	BNE.s		LAB_REM			* loop if not EOL

LAB_1754
	SUBQ.w	#1,a5				* correct the execute pointer
	RTS


*************************************************************************************
*
* perform ON

LAB_ON
	BSR		LAB_GTBY			* get byte parameter, result in d0 and Itemp
	MOVE.b	d0,d2				* copy byte
	BSR		LAB_GBYT			* restore BASIC byte
	MOVE.w	d0,-(sp)			* push GOTO/GOSUB token
	CMP.b		#TK_GOSUB,d0		* compare with GOSUB token
	BEQ.s		LAB_176C			* branch if GOSUB

	CMP.b		#TK_GOTO,d0			* compare with GOTO token
	BNE		LAB_SNER			* if not GOTO do syntax error, then warm start

* next character was GOTO or GOSUB

LAB_176C
	SUBQ.b	#1,d2				* decrement index (byte value)
	BNE.s		LAB_1773			* branch if not zero

	MOVE.w	(sp)+,d0			* pull GOTO/GOSUB token
	BRA		LAB_1602			* go execute it

LAB_1773
	BSR		LAB_IGBY			* increment & scan memory
	BSR.s		LAB_GFPN			* get fixed-point number into temp integer & d1
							* (skip this n)
	CMP.b		#$2C,d0			* compare next character with ","
	BEQ.s		LAB_176C			* loop if ","

	MOVE.w	(sp)+,d0			* pull GOTO/GOSUB token (run out of options)
	RTS						* and exit


*************************************************************************************
*
* get fixed-point number into temp integer & d1
* interpret number from (a5), leave (a5) pointing to byte after #

LAB_GFPN
	MOVEQ		#$00,d1			* clear integer register
	MOVE.l	d1,d0				* clear d0
	BSR		LAB_GBYT			* scan memory, Cb=1 if "0"-"9", & get byte
	BCC.s		LAB_1786			* return if carry clear, chr was not "0"-"9"

	MOVE.l	d2,-(sp)			* save d2
LAB_1785
	MOVE.l	d1,d2				* copy integer register
	ADD.l		d1,d1				* *2
	BCS		LAB_SNER			* if overflow do syntax error, then warm start

	ADD.l		d1,d1				* *4
	BCS		LAB_SNER			* if overflow do syntax error, then warm start

	ADD.l		d2,d1				* *1 + *4
	BCS		LAB_SNER			* if overflow do syntax error, then warm start

	ADD.l		d1,d1				* *10
	BCS		LAB_SNER			* if overflow do syntax error, then warm start

	SUB.b		#$30,d0			* subtract $30 from byte
	ADD.l		d0,d1				* add to integer register, the top 24 bits are
							* always clear
	BVS		LAB_SNER			* if overflow do syntax error, then warm start
							* this makes the maximum line number 2147483647
	BSR		LAB_IGBY			* increment & scan memory
	BCS.s		LAB_1785			* loop for next character if "0"-"9"

	MOVE.l	(sp)+,d2			* restore d2
LAB_1786
	MOVE.l	d1,Itemp(a3)		* save Itemp
	RTS


*************************************************************************************
*
* perform DEC

LAB_DEC
	MOVE.w	#$8180,-(sp)		* set -1 sign/exponent
	BRA.s		LAB_17B7			* go do DEC


*************************************************************************************
*
* perform INC

LAB_INC
	MOVE.w	#$8100,-(sp)		* set 1 sign/exponent
	BRA.s		LAB_17B7			* go do INC

							* was "," so another INCR variable to do
LAB_17B8
	BSR		LAB_IGBY			* increment and scan memory
LAB_17B7
	BSR		LAB_GVAR			* get variable address in a0

* if you want a non existant variable to return a null value then set the novar
* value at the top of this file to some non zero value

 ifne	novar

	BEQ.s		LAB_INCT			* if variable not found skip the inc/dec

 endc

	TST.b		Dtypef(a3)			* test data type, $80=string, $40=integer,
							* $00=float
	BMI		LAB_TMER			* if string do "Type mismatch" error/warm start

	BNE.s		LAB_INCI			* go do integer INC/DEC

	MOVE.l	a0,Lvarpl(a3)		* save var address
	BSR		LAB_UFAC			* unpack memory (a0) into FAC1
	MOVE.l	#$80000000,FAC2_m(a3)	* set FAC2 mantissa for 1
	MOVE.w	(sp),d0			* move exponent & sign to d0
	MOVE.w	d0,FAC2_e(a3)		* move exponent & sign to FAC2
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* make sign compare = FAC1 sign
	EOR.b		d0,FAC_sc(a3)		* make sign compare (FAC1_s EOR FAC2_s)
	BSR		LAB_ADD			* add FAC2 to FAC1
	BSR		LAB_PFAC			* pack FAC1 into variable (Lvarpl)
LAB_INCT
	BSR		LAB_GBYT			* scan memory
	CMPI.b	#$2C,d0			* compare with ","
	BEQ.s		LAB_17B8			* continue if "," (another variable to do)

	ADDQ.w	#2,sp				* else dump sign & exponent
	RTS

LAB_INCI
	TST.b		1(sp)				* test sign
	BNE.s		LAB_DECI			* branch if DEC

	ADDQ.l	#1,(a0)			* increment variable
	BRA.s		LAB_INCT			* go scan for more

LAB_DECI
	SUBQ.l	#1,(a0)			* decrement variable
	BRA.s		LAB_INCT			* go scan for more


*************************************************************************************
*
* perform LET

LAB_LET
	BSR		LAB_SVAR			* search for or create a variable
							* return the variable address in a0
	MOVE.l	a0,Lvarpl(a3)		* save variable address
	MOVE.b	Dtypef(a3),-(sp)		* push var data type, $80=string, $40=integer,
							* $00=float
	MOVEQ		#TK_EQUAL-$100,d0		* get = token
	BSR		LAB_SCCA			* scan for CHR$(d0), else do syntax error/warm
							* start
	BSR		LAB_EVEX			* evaluate expression
	MOVE.b	Dtypef(a3),d0		* copy expression data type
	MOVE.b	(sp)+,Dtypef(a3)		* pop variable data type
	ROL.b		#1,d0				* set carry if expression type = string
	BSR		LAB_CKTM			* type match check, set C for string
	BEQ		LAB_PFAC			* if number pack FAC1 into variable Lvarpl & RET

* string LET

LAB_17D5
	MOVEA.l	Lvarpl(a3),a2		* get pointer to variable
LAB_17D6
	MOVEA.l	FAC1_m(a3),a0		* get descriptor pointer
	MOVEA.l	(a0),a1			* get string pointer
	CMP.l		Sstorl(a3),a1		* compare string memory start with string
							* pointer
	BCS.s		LAB_1811			* if it was in program memory assign the value
							* and exit

	CMPA.l	Sfncl(a3),a0		* compare functions start with descriptor
							* pointer
	BCS.s		LAB_1811			* branch if >= (string is on stack)

							* string is variable$ make space and copy string
LAB_1810
	MOVEQ		#0,d1				* clear length
	MOVE.w	4(a0),d1			* get string length
	MOVEA.l	(a0),a0			* get string pointer
	BSR		LAB_20C9			* copy string
	MOVEA.l	FAC1_m(a3),a0		* get descriptor pointer back
							* clean stack & assign value to string variable
LAB_1811
	CMPA.l	a0,a4				* is string on the descriptor stack
	BNE.s		LAB_1813			* skip pop if not

	ADDQ.w	#$06,a4			* else update stack pointer
LAB_1813
	MOVE.l	(a0)+,(a2)+			* save pointer to variable
	MOVE.w	(a0),(a2)			* save length to variable
RTS_008
	RTS


*************************************************************************************
*
* perform GET

LAB_GET
	BSR		LAB_SVAR			* search for or create a variable
							* return the variable address in a0
	MOVE.l	a0,Lvarpl(a3)		* save variable address as GET variable
	TST.b		Dtypef(a3)			* test data type, $80=string, $40=integer,
							* $00=float
	BMI.s		LAB_GETS			* go get string character

							* was numeric get
	BSR		INGET				* get input byte
	BSR		LAB_1FD0			* convert d0 to unsigned byte in FAC1
	BRA		LAB_PFAC			* pack FAC1 into variable (Lvarpl) & return

LAB_GETS
	MOVEQ		#$00,d1			* assume no byte
	MOVE.l	d1,a0				* assume null string
	BSR		INGET				* get input byte
	BCC.s		LAB_NoSt			* branch if no byte received

	MOVEQ		#$01,d1			* string is single byte
	BSR		LAB_2115			* make string space d1 bytes long
							* return a0 = pointer, other registers unchanged

	MOVE.b	d0,(a0)			* save byte in string (byte IS string!)
LAB_NoSt
	BSR		LAB_RTST			* push string on descriptor stack
							* a0 = pointer, d1 = length

	BRA.s		LAB_17D5			* do string LET & return


*************************************************************************************
*
* PRINT

LAB_1829
	BSR		LAB_18C6			* print string from stack
LAB_182C
	BSR		LAB_GBYT			* scan memory

* perform PRINT

LAB_PRINT
	BEQ.s		LAB_CRLF			* if nothing following just print CR/LF

LAB_1831
	CMP.b		#TK_TAB,d0			* compare with TAB( token
	BEQ.s		LAB_18A2			* go do TAB/SPC

	CMP.b		#TK_SPC,d0			* compare with SPC( token
	BEQ.s		LAB_18A2			* go do TAB/SPC

	CMP.b		#',',d0			* compare with ","
	BEQ.s		LAB_188B			* go do move to next TAB mark

	CMP.b		#';',d0			* compare with ";"
	BEQ		LAB_18BD			* if ";" continue with PRINT processing

	BSR		LAB_EVEX			* evaluate expression
	TST.b		Dtypef(a3)			* test data type, $80=string, $40=integer,
							* $00=float
	BMI.s		LAB_1829			* branch if string

** replace the two lines above with this code

**	MOVE.b	Dtypef(a3),d0		* get data type flag, $80=string, $00=numeric
**	BMI.s		LAB_1829			* branch if string

	BSR		LAB_2970			* convert FAC1 to string
	BSR		LAB_20AE			* print " terminated string to FAC1 stack

* don't check fit if terminal width byte is zero

	MOVEQ		#0,d0				* clear d0
	MOVE.b	TWidth(a3),d0		* get terminal width byte
	BEQ.s		LAB_185E			* skip check if zero

	SUB.b		7(a4),d0			* subtract string length
	SUB.b		TPos(a3),d0			* subtract terminal position
	BCC.s		LAB_185E			* branch if less than terminal width

	BSR.s		LAB_CRLF			* else print CR/LF
LAB_185E
	BSR.s		LAB_18C6			* print string from stack
	BRA.s		LAB_182C			* always go continue processing line


*************************************************************************************
*
* CR/LF return to BASIC from BASIC input handler
* leaves a0 pointing to the buffer start

LAB_1866
	MOVE.b	#$00,(a0,d1.w)		* null terminate input

* print CR/LF

LAB_CRLF
	MOVEQ		#$0D,d0			* load [CR]
	BSR.s		LAB_PRNA			* go print the character
	MOVEQ		#$0A,d0			* load [LF]
	BRA.s		LAB_PRNA			* go print the character & return

LAB_188B
	MOVE.b	TPos(a3),d2			* get terminal position
	CMP.b		Iclim(a3),d2		* compare with input column limit
	BCS.s		LAB_1898			* branch if less than Iclim

	BSR.s		LAB_CRLF			* else print CR/LF (next line)
	BRA.s		LAB_18BD			* continue with PRINT processing

LAB_1898
	SUB.b		TabSiz(a3),d2		* subtract TAB size
	BCC.s		LAB_1898			* loop if result was >= 0

	NEG.b		d2				* twos complement it
	BRA.s		LAB_18B7			* print d2 spaces

							* do TAB/SPC
LAB_18A2
	MOVE.w	d0,-(sp)			* save token
	BSR		LAB_SGBY			* increment and get byte, result in d0 and Itemp
	MOVE.w	d0,d2				* copy byte
	BSR		LAB_GBYT			* get basic byte back
	CMP.b		#$29,d0			* is next character ")"
	BNE		LAB_SNER			* if not do syntax error, then warm start

	MOVE.w	(sp)+,d0			* get token back
	CMP.b		#TK_TAB,d0			* was it TAB ?
	BNE.s		LAB_18B7			* branch if not (was SPC)

							* calculate TAB offset
	SUB.b		TPos(a3),d2			* subtract terminal position
	BLS.s		LAB_18BD			* branch if result was <= 0
							* can't TAB backwards or already there

							* print d2.b spaces
LAB_18B7
	MOVEQ		#0,d0				* clear longword
	SUBQ.b	#1,d0				* make d0 = $FF
	AND.l		d0,d2				* mask for byte only
	BEQ.s		LAB_18BD			* branch if zero

	MOVEQ		#$20,d0			* load " "
	SUBQ.b	#1,d2				* adjust for DBF loop
LAB_18B8
	BSR.s		LAB_PRNA			* go print
	DBF		d2,LAB_18B8			* decrement count and loop if not all done

							* continue with PRINT processing
LAB_18BD
	BSR		LAB_IGBY			* increment & scan memory
	BNE		LAB_1831			* if byte continue executing PRINT

	RTS						* exit if nothing more to print


*************************************************************************************
*
* print null terminated string from a0

LAB_18C3
	BSR		LAB_20AE			* print terminated string to FAC1/stack

* print string from stack

LAB_18C6
	BSR		LAB_22B6			* pop string off descriptor stack or from memory
							* returns with d0 = length, a0 = pointer
	BEQ.s		RTS_009			* exit (RTS) if null string

	MOVE.w	d0,d1				* copy length & set Z flag
	SUBQ.w	#1,d1				* -1 for BF loop
LAB_18CD
	MOVE.b	(a0)+,d0			* get byte from string
	BSR.s		LAB_PRNA			* go print the character
	DBF		d1,LAB_18CD			* decrement count and loop if not done yet

RTS_009
	RTS


*************************************************************************************
*
* print "?" character

LAB_18E3
	MOVEQ		#$3F,d0			* load "?" character


*************************************************************************************
*
* print character in d0, includes the null handler and infinite line length code
* changes no registers

LAB_PRNA
	MOVE.l	d1,-(sp)			* save d1
	CMP.b		#$20,d0			* compare with " "
	BCS.s		LAB_18F9			* branch if less, non printing character

							* don't check fit if terminal width byte is zero
	MOVE.b	TWidth(a3),d1		* get terminal width
	BNE.s		LAB_18F0			* branch if not zero (not infinite length)

							* is "infinite line" so check TAB position
	MOVE.b	TPos(a3),d1			* get position
	SUB.b		TabSiz(a3),d1		* subtract TAB size
	BNE.s		LAB_18F7			* skip reset if different

	MOVE.b	d1,TPos(a3)			* else reset position
	BRA.s		LAB_18F7			* go print character

LAB_18F0
	CMP.b		TPos(a3),d1			* compare with terminal character position
	BNE.s		LAB_18F7			* branch if not at end of line

	MOVE.l	d0,-(sp)			* save d0
	BSR		LAB_CRLF			* else print CR/LF
	MOVE.l	(sp)+,d0			* restore d0
LAB_18F7
	ADDQ.b	#$01,TPos(a3)		* increment terminal position
LAB_18F9
	JSR		V_OUTP(a3)			* output byte via output vector
	CMP.b		#$0D,d0			* compare with [CR]
	BNE.s		LAB_188A			* branch if not [CR]

							* else print nullct nulls after the [CR]
	MOVEQ		#$00,d1			* clear d1
	MOVE.b	Nullct(a3),d1		* get null count
	BEQ.s		LAB_1886			* branch if no nulls

	MOVEQ		#$00,d0			* load [NULL]
LAB_1880
	JSR		V_OUTP(a3)			* go print the character
	DBF		d1,LAB_1880			* decrement count and loop if not all done

	MOVEQ		#$0D,d0			* restore the character
LAB_1886
	MOVE.b	d1,TPos(a3)			* clear terminal position
LAB_188A
	MOVE.l	(sp)+,d1			* restore d1
	RTS


*************************************************************************************
*
* handle bad input data

LAB_1904
	MOVEA.l	(sp)+,a5			* restore execute pointer
	TST.b		Imode(a3)			* test input mode flag, $00=INPUT, $98=READ
	BPL.s		LAB_1913			* branch if INPUT (go do redo)

	MOVE.l	Dlinel(a3),Clinel(a3)	* save DATA line as current line
	BRA		LAB_TMER			* do type mismatch error, then warm start

							* mode was INPUT
LAB_1913
	LEA		LAB_REDO(pc),a0		* point to redo message
	BSR		LAB_18C3			* print null terminated string from memory
	MOVEA.l	Cpntrl(a3),a5		* save continue pointer as BASIC execute pointer
	RTS


*************************************************************************************
*
* perform INPUT

LAB_INPUT
	BSR		LAB_CKRN			* check not direct (back here if ok)
	CMP.b		#'"',d0			* compare the next byte with open quote
	BNE.s		LAB_1934			* if no prompt string just go get the input

	BSR		LAB_1BC1			* print "..." string
	MOVEQ		#';',d0			* set the search character to ";"
	BSR		LAB_SCCA			* scan for CHR$(d0), else do syntax error/warm
							* start
	BSR		LAB_18C6			* print string from Sutill/Sutilh
							* finished the prompt, now read the data
LAB_1934
	BSR		LAB_INLN			* print "? " and get BASIC input
							* return a0 pointing to the buffer start
	MOVEQ		#0,d0				* flag INPUT

* if you don't want a null response to INPUT to break the program then set the nobrk
* value at the top of this file to some non zero value

 ifne	nobrk

	BRA.s		LAB_1953			* go handle the input

 endc

* if you do want a null response to INPUT to break the program then leave the nobrk
* value at the top of this file set to zero

 ifeq	nobrk

	TST.b		(a0)				* test first byte from buffer
	BNE.s		LAB_1953			* branch if not null input

	BRA		LAB_1647			* go do BREAK exit

 endc


*************************************************************************************
*
* perform READ

LAB_READ
	MOVEA.l	Dptrl(a3),a0		* get the DATA pointer
	MOVEQ		#$98-$100,d0		* flag READ
LAB_1953
	MOVE.b	d0,Imode(a3)		* set input mode flag, $00=INPUT, $98=READ
	MOVE.l	a0,Rdptrl(a3)		* save READ pointer

							* READ or INPUT the next variable from list
LAB_195B
	BSR		LAB_SVAR			* search for or create a variable
							* return the variable address in a0
	MOVE.l	a0,Lvarpl(a3)		* save variable address as LET variable
	MOVE.l	a5,-(sp)			* save BASIC execute pointer
LAB_1961
	MOVEA.l	Rdptrl(a3),a5		* set READ pointer as BASIC execute pointer
	BSR		LAB_GBYT			* scan memory
	BNE.s		LAB_1986			* if not null go get the value

							* the pointer was to a null entry
	TST.b		Imode(a3)			* test input mode flag, $00=INPUT, $98=READ
	BMI.s		LAB_19DD			* branch if READ (go find the next statement)

							* else the mode was INPUT so get more
	BSR		LAB_18E3			* print a "?" character
	BSR		LAB_INLN			* print "? " and get BASIC input
							* return a0 pointing to the buffer start

* if you don't want a null response to INPUT to break the program then set the nobrk
* value at the top of this file to some non zero value

 ifne	nobrk

	MOVE.l	a0,Rdptrl(a3)		* save the READ pointer
	BRA.s		LAB_1961			* go handle the input

 endc

* if you do want a null response to INPUT to break the program then leave the nobrk
* value at the top of this file set to zero

 ifeq	nobrk

	TST.b		(a0)				* test the first byte from the buffer
	BNE.s		LAB_1984			* if not null input go handle it

	BRA		LAB_1647			* else go do the BREAK exit

LAB_1984
	MOVEA.l	a0,a5				* set the execute pointer to the buffer
	SUBQ.w	#1,a5				* decrement the execute pointer

 endc

LAB_1985
	BSR		LAB_IGBY			* increment & scan memory
LAB_1986
	TST.b		Dtypef(a3)			* test data type, $80=string, $40=integer,
							* $00=float
	BPL.s		LAB_19B0			* branch if numeric

							* else get string
	MOVE.b	d0,d2				* save search character
	CMP.b		#$22,d0			* was it " ?
	BEQ.s		LAB_1999			* branch if so

	MOVEQ		#':',d2			* set new search character
	MOVEQ		#',',d0			* other search character is ","
	SUBQ.w	#1,a5				* decrement BASIC execute pointer
LAB_1999
	ADDQ.w	#1,a5				* increment BASIC execute pointer
	MOVE.b	d0,d3				* set second search character
	MOVEA.l	a5,a0				* BASIC execute pointer is source

	BSR		LAB_20B4			* print d2/d3 terminated string to FAC1 stack
							* d2 = Srchc, d3 = Asrch, a0 is source
	MOVEA.l	a2,a5				* copy end of string to BASIC execute pointer
	BSR		LAB_17D5			* go do string LET
	BRA.s		LAB_19B6			* go check string terminator

							* get numeric INPUT
LAB_19B0
	MOVE.b	Dtypef(a3),-(sp)		* save variable data type
	BSR		LAB_2887			* get FAC1 from string
	MOVE.b	(sp)+,Dtypef(a3)		* restore variable data type
	BSR		LAB_PFAC			* pack FAC1 into (Lvarpl)
LAB_19B6
	BSR		LAB_GBYT			* scan memory
	BEQ.s		LAB_19C2			* branch if null (last entry)

	CMP.b		#',',d0			* else compare with ","
	BNE		LAB_1904			* if not "," go handle bad input data

	ADDQ.w	#1,a5				* else was "," so point to next chr
							* got good input data
LAB_19C2
	MOVE.l	a5,Rdptrl(a3)		* save the read pointer for now
	MOVEA.l	(sp)+,a5			* restore the execute pointer
	BSR		LAB_GBYT			* scan the memory
	BEQ.s		LAB_1A03			* if null go do extra ignored message

	PEA		LAB_195B(pc)		* set return address
	BRA		LAB_1C01			* scan for "," else do syntax error/warm start
							* then go INPUT next variable from list

							* find next DATA statement or do "Out of Data"
							* error
LAB_19DD
	BSR		LAB_SNBS			* scan for next BASIC statement ([:] or [EOL])
							* returns a0 as pointer to [:] or [EOL]
	MOVEA.l	a0,a5				* add index, now = pointer to [EOL]/[EOS]
	ADDQ.w	#1,a5				* pointer to next character
	CMP.b		#':',d0			* was it statement end?
	BEQ.s		LAB_19F6			* branch if [:]

							* was [EOL] so find next line

	MOVE.w	a5,d1				* past pad byte(s)
	AND.w		#1,d1				* mask odd bit
	ADD.w		d1,a5				* add pointer
	MOVE.l	(a5)+,d2			* get next line pointer
	BEQ		LAB_ODER			* branch if end of program

	MOVE.l	(a5)+,Dlinel(a3)		* save current DATA line
LAB_19F6
	BSR		LAB_GBYT			* scan memory
	CMP.b		#TK_DATA,d0			* compare with "DATA" token
	BEQ		LAB_1985			* was "DATA" so go do next READ

	BRA.s		LAB_19DD			* go find next statement if not "DATA"

* end of INPUT/READ routine

LAB_1A03
	MOVEA.l	Rdptrl(a3),a0		* get temp READ pointer
	TST.b		Imode(a3)			* get input mode flag, $00=INPUT, $98=READ
	BPL.s		LAB_1A0E			* branch if INPUT

	MOVE.l	a0,Dptrl(a3)		* else save temp READ pointer as DATA pointer
	RTS

							* we were getting INPUT
LAB_1A0E
	TST.b		(a0)				* test next byte
	BNE.s		LAB_1A1B			* error if not end of INPUT

	RTS
							* user typed too much
LAB_1A1B
	LEA		LAB_IMSG(pc),a0		* point to extra ignored message
	BRA		LAB_18C3			* print null terminated string from memory & RTS


*************************************************************************************
*
* perform NEXT

LAB_NEXT
	BNE.s		LAB_1A46			* branch if NEXT var

	ADDQ.w	#4,sp				* back past return address
	CMP.w		#TK_FOR,(sp)		* is FOR token on stack?
	BNE		LAB_NFER			* if not do NEXT without FOR err/warm start

	MOVEA.l	2(sp),a0			* get stacked FOR variable pointer
	BRA.s		LAB_11BD			* branch always (no variable to search for)

* NEXT var

LAB_1A46
	BSR		LAB_GVAR			* get variable address in a0
	ADDQ.w	#4,sp				* back past return address
	MOVE.w	#TK_FOR,d0			* set for FOR token
	MOVEQ		#$1C,d1			* set for FOR use size
	BRA.s		LAB_11A6			* enter loop for next variable search

LAB_11A5
	ADDA.l	d1,sp				* add FOR stack use size
LAB_11A6
	CMP.w		(sp),d0			* is FOR token on stack?
	BNE		LAB_NFER			* if not found do NEXT without FOR error and
							* warm start

							* was FOR token
	CMPA.l	2(sp),a0			* compare var pointer with stacked var pointer
	BNE.s		LAB_11A5			* loop if no match found

LAB_11BD
	MOVE.w	6(sp),FAC2_e(a3)		* get STEP value exponent and sign
	MOVE.l	8(sp),FAC2_m(a3)		* get STEP value mantissa

	MOVE.b	18(sp),Dtypef(a3)		* restore FOR variable data type
	BSR		LAB_1C19			* check type and unpack (a0)

	MOVE.b	FAC2_s(a3),FAC_sc(a3)	* save FAC2 sign as sign compare
	MOVE.b	FAC1_s(a3),d0		* get FAC1 sign
	EOR.b		d0,FAC_sc(a3)		* EOR to create sign compare

	MOVE.l	a0,Lvarpl(a3)		* save variable pointer
	BSR		LAB_ADD			* add STEP value to FOR variable
	MOVE.b	18(sp),Dtypef(a3)		* restore FOR variable data type (again)
	BSR		LAB_PFAC			* pack FAC1 into FOR variable (Lvarpl)

	MOVE.w	12(sp),FAC2_e(a3)		* get TO value exponent and sign
	MOVE.l	14(sp),FAC2_m(a3)		* get TO value mantissa

	MOVE.b	FAC2_s(a3),FAC_sc(a3)	* save FAC2 sign as sign compare
	MOVE.b	FAC1_s(a3),d0		* get FAC1 sign
	EOR.b		d0,FAC_sc(a3)		* EOR to create sign compare

	BSR		LAB_27FA			* compare FAC1 with FAC2 (TO value)
							* returns d0=+1 if FAC1 > FAC2
							* returns d0= 0 if FAC1 = FAC2
							* returns d0=-1 if FAC1 < FAC2

	MOVE.w	6(sp),d1			* get STEP value exponent and sign
	EOR.w		d0,d1				* EOR compare result with STEP exponent and sign

	TST.b		d0				* test for =
	BEQ.s		LAB_1A90			* branch if = (loop INcomplete)

	TST.b		d1				* test result
	BPL.s		LAB_1A9B			* branch if > (loop complete)

							* loop back and do it all again
LAB_1A90
	MOVE.l	20(sp),Clinel(a3)		* reset current line
	MOVE.l	24(sp),a5			* reset BASIC execute pointer
	BRA		LAB_15C2			* go do interpreter inner loop

							* loop complete so carry on
LAB_1A9B
	ADDA.w	#28,sp			* add 28 to dump FOR structure
	BSR		LAB_GBYT			* scan memory
	CMP.b		#$2C,d0			* compare with ","
	BNE		LAB_15C2			* if not "," go do interpreter inner loop

							* was "," so another NEXT variable to do
	BSR		LAB_IGBY			* else increment & scan memory
	BSR		LAB_1A46			* do NEXT (var)


*************************************************************************************
*
* evaluate expression & check is numeric, else do type mismatch

LAB_EVNM
	BSR.s		LAB_EVEX			* evaluate expression


*************************************************************************************
*
* check if source is numeric, else do type mismatch

LAB_CTNM
	CMP.w		d0,d0				* required type is numeric so clear carry


*************************************************************************************
*
* type match check, set C for string, clear C for numeric

LAB_CKTM
	BTST.b	#7,Dtypef(a3)		* test data type flag, don't change carry
	BNE.s		LAB_1ABA			* branch if data type is string

							* else data type was numeric
	BCS		LAB_TMER			* if required type is string do type mismatch
							* error

	RTS
							* data type was string, now check required type
LAB_1ABA
	BCC		LAB_TMER			* if required type is numeric do type mismatch
							* error
	RTS


*************************************************************************************
*
* this routine evaluates any type of expression. first it pushes an end marker so
* it knows when the expression has been evaluated, this is a precedence value of zero.
* next the first value is evaluated, this can be an in line value, either numeric or
* string, a variable or array element of any type, a function or even an expression
* in parenthesis. this value is kept in FAC_1
* after the value is evaluated a test is made on the next BASIC program byte, if it
* is a comparrison operator i.e. "<", "=" or ">", then the corresponding bit is set
* in the comparison evaluation flag. this test loops until no more comparrison operators
* are found or more than one of any type is found. in the last case an error is generated

* evaluate expression

LAB_EVEX
	SUBQ.w	#1,a5				* decrement BASIC execute pointer
LAB_EVEZ
	MOVEQ		#0,d1				* clear precedence word
	MOVE.b	d1,Dtypef(a3)		* clear the data type, $80=string, $40=integer,
							* $00=float
	BRA.s		LAB_1ACD			* enter loop

* get vector, set up operator then continue evaluation

LAB_1B43						*
	LEA		LAB_OPPT(pc),a0		* point to operator vector table
	MOVE.w	2(a0,d1.w),d0		* get vector offset
	PEA		(a0,d0.w)			* push vector

	MOVE.l	FAC1_m(a3),-(sp)		* push FAC1 mantissa
	MOVE.w	FAC1_e(a3),-(sp)		* push sign and exponent
	MOVE.b	comp_f(a3),-(sp)		* push comparison evaluation flag

	MOVE.w	(a0,d1.w),d1		* get precedence value
LAB_1ACD
	MOVE.w	d1,-(sp)			* push precedence value
	BSR		LAB_GVAL			* get value from line
	MOVE.b	#$00,comp_f(a3)		* clear compare function flag
LAB_1ADB
	BSR		LAB_GBYT			* scan memory
LAB_1ADE
	SUB.b		#TK_GT,d0			* subtract token for > (lowest compare function)
	BCS.s		LAB_1AFA			* branch if < TK_GT

	CMP.b		#$03,d0			* compare with ">" to "<" tokens
	BCS.s		LAB_1AE0			* branch if <= TK_SGN (is compare function)

	TST.b		comp_f(a3)			* test compare function flag
	BNE.s		LAB_1B2A			* branch if compare function

	BRA		LAB_1B78			* go do functions

							* was token for > = or < (d0 = 0, 1 or 2)
LAB_1AE0
	MOVEQ		#1,d1				* set to 0000 0001
	ASL.b		d0,d1				* 1 if >, 2 if =, 4 if <
	MOVE.b	comp_f(a3),d0		* copy old compare function flag
	EOR.b		d1,comp_f(a3)		* EOR in this compare function bit
	CMP.b		comp_f(a3),d0		* compare old with new compare function flag
	BCC		LAB_SNER			* if new <= old comp_f do syntax error and warm
							* start, there was more than one <, = or >
	BSR		LAB_IGBY			* increment & scan memory
	BRA.s		LAB_1ADE			* go do next character

							* token is < ">" or > "<" tokens
LAB_1AFA
	TST.b		comp_f(a3)			* test compare function flag
	BNE.s		LAB_1B2A			* branch if compare function

							* was < TK_GT so is operator or lower
	ADD.b	#(TK_GT-TK_PLUS),d0		* add # of operators (+ - * / ^ AND OR EOR)
	BCC.s		LAB_1B78			* branch if < + operator

	BNE.s		LAB_1B0B			* branch if not + token

	TST.b		Dtypef(a3)			* test data type, $80=string, $40=integer,
							* $00=float
	BMI		LAB_224D			* type is string & token was +

LAB_1B0B
	MOVEQ		#0,d1				* clear longword
	ADD.b		d0,d0				* *2
	ADD.b		d0,d0				* *4
	MOVE.b	d0,d1				* copy to index
LAB_1B13
	MOVE.w	(sp)+,d0			* pull previous precedence
	LEA		LAB_OPPT(pc),a0		* set pointer to operator table
	CMP.w		(a0,d1.w),d0		* compare with this opperator precedence
	BCC.s		LAB_1B7D			* branch if previous precedence (d0) >=

	BSR		LAB_CTNM			* check if source is numeric, else type mismatch
LAB_1B1C
	MOVE.w	d0,-(sp)			* save precedence
LAB_1B1D
	BSR		LAB_1B43			* get vector, set-up operator and continue
							* evaluation
	MOVE.w	(sp)+,d0			* restore precedence
	MOVE.l	prstk(a3),d1		* get stacked function pointer
	BPL.s		LAB_1B3C			* branch if stacked values

	MOVE.w	d0,d0				* copy precedence (set flags)
	BEQ.s		LAB_1B7B			* exit if done

	BRA.s		LAB_1B86			* else pop FAC2 & return (do function)

							* was compare function (< = >)
LAB_1B2A
	MOVE.b	Dtypef(a3),d0		* get data type flag
	MOVE.b	comp_f(a3),d1		* get compare function flag
	ADD.b		d0,d0				* string bit flag into X bit
	ADDX.b	d1,d1				* shift compare function flag

	MOVE.b	#0,Dtypef(a3)		* clear data type flag, $00=float
	MOVE.b	d1,comp_f(a3)		* save new compare function flag
	SUBQ.w	#1,a5				* decrement BASIC execute pointer
	MOVEQ		#(TK_LT-TK_PLUS)*4,d1	* set offset to last operator entry
	BRA.s		LAB_1B13			* branch always

LAB_1B3C
	LEA		LAB_OPPT(pc),a0		* point to function vector table
	CMP.w		(a0,d1.w),d0		* compare with this opperator precedence
	BCC.s		LAB_1B86			* branch if d0 >=, pop FAC2 & return

	BRA.s		LAB_1B1C			* branch always

* do functions

LAB_1B78
	MOVEQ		#-1,d1			* flag all done
	MOVE.w	(sp)+,d0			* pull precedence word
LAB_1B7B
	BEQ.s		LAB_1B9D			* exit if done

LAB_1B7D
	CMP.w		#$64,d0			* compare previous precedence with $64
	BEQ.s		LAB_1B84			* branch if was $64 (< function can be string)

	BSR		LAB_CTNM			* check if source is numeric, else type mismatch
LAB_1B84
	MOVE.l	d1,prstk(a3)		* save current operator index

							* pop FAC2 & return
LAB_1B86
	MOVE.b	(sp)+,d0			* pop comparison evaluation flag
	MOVE.b	d0,d1				* copy comparison evaluation flag
	LSR.b		#1,d0				* shift out comparison evaluation lowest bit
	MOVE.b	d0,Cflag(a3)		* save comparison evaluation flag
	MOVE.w	(sp)+,FAC2_e(a3)		* pop exponent and sign
	MOVE.l	(sp)+,FAC2_m(a3)		* pop mantissa
	MOVE.b	FAC2_s(a3),FAC_sc(a3)	* copy FAC2 sign
	MOVE.b	FAC1_s(a3),d0		* get FAC1 sign
	EOR.b		d0,FAC_sc(a3)		* EOR FAC1 sign and set sign compare

	LSR.b		#1,d1				* type bit into X and C
	RTS

LAB_1B9D
	MOVE.b	FAC1_e(a3),d0		* get FAC1 exponent
	RTS


*************************************************************************************
*
* get a value from the BASIC line

LAB_GVAL
	BSR.s		LAB_IGBY			* increment & scan memory
	BCS		LAB_2887			* if numeric get FAC1 from string & return

	TST.b		d0				* test byte
	BMI		LAB_1BD0			* if -ve go test token values

							* else it is either a string, number, variable
							* or (<expr>)
	CMP.b		#'$',d0			* compare with "$"
	BEQ		LAB_2887			* if "$" get hex number from string & return

	CMP.b		#'%',d0			* else compare with "%"
	BEQ		LAB_2887			* if "%" get binary number from string & return

	CMP.b		#$2E,d0			* compare with "."
	BEQ		LAB_2887			* if so get FAC1 from string and return
							* (e.g. .123)

							* wasn't a number so ...
	CMP.b		#$22,d0			* compare with "
	BNE.s		LAB_1BF3			* if not open quote it must be a variable or
							* open bracket

							* was open quote so get the enclosed string

* print "..." string to string stack

LAB_1BC1
	MOVE.b	(a5)+,d0			* increment BASIC execute pointer (past ")
							* fastest/shortest method
	MOVEA.l	a5,a0				* copy basic execute pointer (string start)
	BSR		LAB_20AE			* print " terminated string to stack
	MOVEA.l	a2,a5				* restore BASIC execute pointer from temp
	RTS

* get value from line .. continued
							* wasn't any sort of number so ...
LAB_1BF3
	CMP.b		#'(',d0			* compare with "("
	BNE.s		LAB_1C18			* if not "(" get (var) and return value in FAC1
							* and $ flag


*************************************************************************************
*
* evaluate expression within parentheses

LAB_1BF7
	BSR		LAB_EVEZ			* evaluate expression (no decrement)


*************************************************************************************
*
* all the 'scan for' routines return the character after the sought character

* scan for ")", else do syntax error, then warm start

LAB_1BFB
	MOVEQ		#$29,d0			* load d0 with ")"
	BRA.s		LAB_SCCA


*************************************************************************************
*
* scan for "," and get byte, else do Syntax error then warm start

LAB_SCGB
	PEA		LAB_GTBY(pc)		* return address is to get byte parameter


*************************************************************************************
*
* scan for ",", else do syntax error, then warm start

LAB_1C01
	MOVEQ		#$2C,d0			* load d0 with ","


*************************************************************************************
*
* scan for CHR$(d0) , else do syntax error, then warm start

LAB_SCCA
	CMP.b		(a5)+,d0			* check next byte is = d0
	BEQ.s		LAB_GBYT			* if so go get next

	BRA		LAB_SNER			* else do syntax error/warm start


*************************************************************************************
*
* BASIC increment and scan memory routine

LAB_IGBY
	MOVE.b	(a5)+,d0			* get byte & increment pointer

* scan memory routine, exit with Cb = 1 if numeric character
* also skips any spaces encountered

LAB_GBYT
	MOVE.b	(a5),d0			* get byte

	CMP.b		#$20,d0			* compare with " "
	BEQ.s		LAB_IGBY			* if " " go do next

* test current BASIC byte, exit with Cb = 1 if numeric character

	CMP.b		#TK_ELSE,d0			* compare with the token for ELSE
	BCC.s		RTS_001			* exit if >= (not numeric, carry clear)

	CMP.b		#$3A,d0			* compare with ":"
	BCC.s		RTS_001			* exit if >= (not numeric, carry clear)

	MOVEQ		#$D0,d6			* set -"0"
	ADD.b		d6,d0				* add -"0"
	SUB.b		d6,d0				* subtract -"0"
RTS_001						* carry set if byte = "0"-"9"
	RTS


*************************************************************************************
*
* set-up for - operator

LAB_1C11
	BSR		LAB_CTNM			* check if source is numeric, else type mismatch
	MOVEQ	#(TK_GT-TK_PLUS)*4,d1		* set offset from base to - operator
LAB_1C13
	LEA		4(sp),sp			* dump GVAL return address
	BRA		LAB_1B1D			* continue evaluating expression


*************************************************************************************
*
* variable name set-up
* get (var), return value in FAC_1 & data type flag

LAB_1C18
	BSR		LAB_GVAR			* get variable address in a0

* if you want a non existant variable to return a null value then set the novar
* value at the top of this file to some non zero value

 ifne	novar

	BNE.s		LAB_1C19			* if it exists return it

	LEA.l		LAB_1D96(pc),a0		* else return a null descriptor/pointer

 endc

* return existing variable value

LAB_1C19
	TST.b		Dtypef(a3)			* test data type, $80=string, $40=integer,
							* $00=float
	BEQ		LAB_UFAC			* if float unpack memory (a0) into FAC1 and
							* return

	BPL.s		LAB_1C1A			* if integer unpack memory (a0) into FAC1
							* and return

	MOVE.l	a0,FAC1_m(a3)		* else save descriptor pointer in FAC1
	RTS

LAB_1C1A
	MOVE.l	(a0),d0			* get integer value
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & return


*************************************************************************************
*
* get value from line .. continued
* do tokens

LAB_1BD0
	CMP.b		#TK_MINUS,d0		* compare with token for -
	BEQ.s		LAB_1C11			* branch if - token (do set-up for - operator)

							* wasn't -123 so ...
	CMP.b		#TK_PLUS,d0			* compare with token for +
	BEQ		LAB_GVAL			* branch if + token (+n = n so ignore leading +)

	CMP.b		#TK_NOT,d0			* compare with token for NOT
	BNE.s		LAB_1BE7			* branch if not token for NOT

							* was NOT token
	MOVE.w	#(TK_EQUAL-TK_PLUS)*4,d1	* offset to NOT function
	BRA.s		LAB_1C13			* do set-up for function then execute

							* wasn't +, - or NOT so ...
LAB_1BE7
	CMP.b		#TK_FN,d0			* compare with token for FN
	BEQ		LAB_201E			* if FN go evaluate FNx

							* wasn't +, -, NOT or FN so ...
	SUB.b		#TK_SGN,d0			* compare with token for SGN & normalise
	BCS		LAB_SNER			* if < SGN token then do syntax error

* get value from line .. continued
* only functions left so set up function references

* new for V2.0+ this replaces a lot of IF .. THEN .. ELSEIF .. THEN .. that was needed
* to process function calls. now the function vector is computed and pushed on the stack
* and the preprocess offset is read. if the preprocess offset is non zero then the vector
* is calculated and the routine called, if not this routine just does RTS. whichever
* happens the RTS at the end of this routine, or the preprocess routine calls, the
* function code

* this also removes some less than elegant code that was used to bypass type checking
* for functions that returned strings

	AND.w		#$7F,d0			* mask byte
	ADD.w		d0,d0				* *2 (2 bytes per function offset)

	LEA		LAB_FTBL(pc),a0		* pointer to functions vector table
	MOVE.w	(a0,d0.w),d1		* get function vector offset
	PEA		(a0,d1.w)			* push function vector

	LEA		LAB_FTPP(pc),a0		* pointer to functions preprocess vector table
	MOVE.w	(a0,d0.w),d0		* get function preprocess vector offset
	BEQ.s		LAB_1C2A			* no preprocess vector so go do function

	LEA		(a0,d0.w),a0		* get function preprocess vector
	JMP		(a0)				* go do preprocess routine then function


*************************************************************************************
*
* process string expression in parenthesis

LAB_PPFS
	BSR		LAB_1BF7			* process expression in parenthesis
	TST.b		Dtypef(a3)			* test data type
	BPL		LAB_TMER			* if numeric do Type missmatch Error/warm start

LAB_1C2A
	RTS						* else do function


*************************************************************************************
*
* process numeric expression in parenthesis

LAB_PPFN
	BSR		LAB_1BF7			* process expression in parenthesis
	TST.b		Dtypef(a3)			* test data type
	BMI		LAB_TMER			* if string do Type missmatch Error/warm start

	RTS						* else do function


*************************************************************************************
*
* set numeric data type and increment BASIC execute pointer

LAB_PPBI
	MOVE.b	#$00,Dtypef(a3)		* clear data type flag, $00=float
	MOVE.b	(a5)+,d0			* get next BASIC byte
	RTS						* do function


*************************************************************************************
*
* process string for LEFT$, RIGHT$ or MID$

LAB_LRMS
	BSR		LAB_EVEZ			* evaluate (should be string) expression
	TST.b		Dtypef(a3)			* test data type flag
	BPL		LAB_TMER			* if type is not string do type mismatch error

	MOVE.b	(a5)+,d2			* get BASIC byte
	CMP.b		#',',d2			* compare with comma
	BNE		LAB_SNER			* if not "," go do syntax error/warm start

	MOVE.l	FAC1_m(a3),-(sp)		* save descriptor pointer
	BSR		LAB_GTWO			* get word parameter, result in d0 and Itemp
	MOVEA.l	(sp)+,a0			* restore descriptor pointer
	RTS						* do function


*************************************************************************************
*
* process numeric expression(s) for BIN$ or HEX$

LAB_BHSS
	BSR		LAB_EVEZ			* evaluate expression (no decrement)
	TST.b		Dtypef(a3)			* test data type
	BMI		LAB_TMER			* if string do Type missmatch Error/warm start

	BSR		LAB_2831			* convert FAC1 floating to fixed
							* result in d0 and Itemp
	MOVEQ		#0,d1				* set default to no leading "0"s
	MOVE.b	(a5)+,d2			* get BASIC byte
	CMP.b		#',',d2			* compare with comma
	BNE.s		LAB_BHCB			* if not "," go check close bracket

	MOVE.l	d0,-(sp)			* copy number to stack
	BSR		LAB_GTBY			* get byte value
	MOVE.l	d0,d1				* copy leading 0s #
	MOVE.l	(sp)+,d0			* restore number from stack
	MOVE.b	(a5)+,d2			* get BASIC byte
LAB_BHCB
	CMP.b		#')',d2			* compare with close bracket
	BNE		LAB_SNER			* if not ")" do Syntax Error/warm start

	RTS						* go do function


*************************************************************************************
*
* perform EOR

LAB_EOR
	BSR.s		GetFirst			* get two values for OR, AND or EOR
							* first in d0, and Itemp, second in d2
	EOR.l		d2,d0				* EOR values
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & RET


*************************************************************************************
*
* perform OR

LAB_OR
	BSR.s		GetFirst			* get two values for OR, AND or EOR
							* first in d0, and Itemp, second in d2
	OR.l		d2,d0				* do OR
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & RET


*************************************************************************************
*
* perform AND

LAB_AND
	BSR.s		GetFirst			* get two values for OR, AND or EOR
							* first in d0, and Itemp, second in d2
	AND.l		d2,d0				* do AND
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & RET


*************************************************************************************
*
* get two values for OR, AND, EOR
* first in d0, second in d2

GetFirst
	BSR		LAB_EVIR			* evaluate integer expression (no sign check)
							* result in d0 and Itemp
	MOVE.l	d0,d2				* copy second value
	BSR		LAB_279B			* copy FAC2 to FAC1, get first value in
							* expression
	BRA		LAB_EVIR			* evaluate integer expression (no sign check)
							* result in d0 and Itemp & return


*************************************************************************************
*
* perform NOT

LAB_EQUAL
	BSR		LAB_EVIR			* evaluate integer expression (no sign check)
							* result in d0 and Itemp
	NOT.l		d0				* bitwise invert
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & RET


*************************************************************************************
*
* perform comparisons
* do < compare

LAB_LTHAN
	BSR		LAB_CKTM			* type match check, set C for string
	BCS.s		LAB_1CAE			* branch if string

							* do numeric < compare
	BSR		LAB_27FA			* compare FAC1 with FAC2
							* returns d0=+1 if FAC1 > FAC2
							* returns d0= 0 if FAC1 = FAC2
							* returns d0=-1 if FAC1 < FAC2
	BRA.s		LAB_1CF2			* process result

							* do string < compare
LAB_1CAE
	MOVE.b	#$00,Dtypef(a3)		* clear data type, $80=string, $40=integer,
							* $00=float
	BSR		LAB_22B6			* pop string off descriptor stack, or from top
							* of string space returns d0 = length,
							* a0 = pointer
	MOVEA.l	a0,a1				* copy string 2 pointer
	MOVE.l	d0,d1				* copy string 2 length
	MOVEA.l	FAC2_m(a3),a0		* get string 1 descriptor pointer
	BSR		LAB_22BA			* pop (a0) descriptor, returns with ..
							* d0 = length, a0 = pointer
	MOVE.l	d0,d2				* copy length
	BNE.s		LAB_1CB5			* branch if not null string

	TST.l		d1				* test if string 2 is null also
	BEQ.s		LAB_1CF2			* if so do string 1 = string 2

LAB_1CB5
	SUB.l		d1,d2				* subtract string 2 length
	BEQ.s		LAB_1CD5			* branch if strings = length

	BCS.s		LAB_1CD4			* branch if string 1 < string 2

	MOVEQ		#-1,d0			* set for string 1 > string 2
	BRA.s		LAB_1CD6			* go do character comapare

LAB_1CD4
	MOVE.l	d0,d1				* string 1 length is compare length
	MOVEQ		#1,d0				* and set for string 1 < string 2
	BRA.s		LAB_1CD6			* go do character comapare

LAB_1CD5
	MOVE.l	d2,d0				* set for string 1 = string 2
LAB_1CD6
	SUBQ.l	#1,d1				* adjust length for DBcc loop

							* d1 is length to compare, d0 is <=> for length
							* a0 is string 1 pointer, a1 is string 2 pointer
LAB_1CE6
	CMPM.b	(a0)+,(a1)+			* compare string bytes (1 with 2)
	DBNE		d1,LAB_1CE6			* loop if same and not end yet

	BEQ.s		LAB_1CF2			* if = to here, then go use length compare

	BCC.s		LAB_1CDB			* else branch if string 1 > string 2

	MOVEQ		#-1,d0			* else set for string 1 < string 2
	BRA.s		LAB_1CF2			* go set result

LAB_1CDB
	MOVEQ		#1,d0				* and set for string 1 > string 2

LAB_1CF2
	ADDQ.b	#1,d0				* make result 0, 1 or 2
	MOVE.b	d0,d1				* copy to d1
	MOVEQ		#1,d0				* set d0 longword
	ROL.b		d1,d0				* make 1, 2 or 4 (result = flag bit)
	AND.b		Cflag(a3),d0		* AND with comparison evaluation flag
	BEQ		LAB_27DB			* exit if not a wanted result (i.e. false)

	MOVEQ		#-1,d0			* else set -1 (true)
	BRA		LAB_27DB			* save d0 as integer & return


LAB_1CFE
	BSR		LAB_1C01			* scan for ",", else do syntax error/warm start


*************************************************************************************
*
* perform DIM

LAB_DIM
	MOVEQ		#-1,d1			* set "DIM" flag
	BSR.s		LAB_1D10			* search for or dimension a variable
	BSR		LAB_GBYT			* scan memory
	BNE.s		LAB_1CFE			* loop and scan for "," if not null

	RTS


*************************************************************************************
*
* perform << (left shift)

LAB_LSHIFT
	BSR.s		GetPair			* get an integer and byte pair
							* byte is in d2, integer is in d0 and Itemp
	BEQ.s		NoShift			* branch if byte zero

	CMP.b		#$20,d2			* compare bit count with 32d
	BCC.s		TooBig			* branch if >=

	ASL.l		d2,d0				* shift longword
NoShift
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & RET


*************************************************************************************
*
* perform >> (right shift)

LAB_RSHIFT
	BSR.s		GetPair			* get an integer and byte pair
							* byte is in d2, integer is in d0 and Itemp
	BEQ.s		NoShift			* branch if byte zero

	CMP.b		#$20,d2			* compare bit count with 32d
	BCS.s		Not2Big			* branch if >= (return shift)

	TST.l		d0				* test sign bit
	BPL.s		TooBig			* branch if +ve

	MOVEQ		#-1,d0			* set longword
	BRA		LAB_AYFC			* convert d0 to longword in FAC1 & RET

Not2Big
	ASR.l		d2,d0				* shift longword
	BRA		LAB_AYFC			* convert d0 to longword in FAC1 & RET

TooBig
	MOVEQ		#0,d0				* clear longword
	BRA		LAB_AYFC			* convert d0 to longword in FAC1 & RET


*************************************************************************************
*
* get an integer and byte pair
* byte is in d2, integer is in d0 and Itemp

GetPair
	BSR		LAB_EVBY			* evaluate byte expression, result in d0 and
							* Itemp
	MOVE.b	d0,d2				* save it
	BSR		LAB_279B			* copy FAC2 to FAC1, get first value in
							* expression
	BSR		LAB_EVIR			* evaluate integer expression (no sign check)
							* result in d0 and Itemp
	TST.b		d2				* test byte value
	RTS


*************************************************************************************
*
* check alpha, return C=0 if<"A" or >"Z" or <"a" to "z">

LAB_CASC
	CMP.b		#$61,d0			* compare with "a"
	BCC.s		LAB_1D83			* if >="a" go check =<"z"


*************************************************************************************
*
* check alpha upper case, return C=0 if<"A" or >"Z"

LAB_CAUC
	CMP.b		#$41,d0			* compare with "A"
	BCC.s		LAB_1D8A			* if >="A" go check =<"Z"

	OR		d0,d0				* make C=0
	RTS

LAB_1D8A
	CMP.b		#$5B,d0			* compare with "Z"+1
							* carry set if byte<="Z"
	RTS

LAB_1D83
	CMP.b		#$7B,d0			* compare with "z"+1
							* carry set if byte<="z"
	RTS


*************************************************************************************
*
* search for or create variable. this is used to automatically create a variable if
* it is not found. any routines that need to create the variable call LAB_GVAR via
* this point and error generation is supressed and the variable will be created
*
* return pointer to variable in Cvaral and a0
* set data type to variable type

LAB_SVAR
	BSR.s		LAB_GVAR			* search for variable
LAB_FVAR
	RTS


*************************************************************************************
*
* search for variable. if this routine is called from anywhere but the above call and
* the variable searched for does not exist then an error will be returned
*
* DIM flag is in d1.b
* return pointer to variable in Cvaral and a0
* set data type to variable type

LAB_GVAR
	MOVEQ		#$00,d1			* set DIM flag = $00
	BSR		LAB_GBYT			* scan memory (1st character)
LAB_1D10
	MOVE.b	d1,Defdim(a3)		* save DIM flag

* search for FN name entry point

LAB_1D12
	BSR.s		LAB_CASC			* check byte, return C=0 if<"A" or >"Z"
	BCC		LAB_SNER			* if not, syntax error then warm start

							* it is a variable name so ...
	MOVEQ		#$0,d1			* set index for name byte
	LEA		Varname(a3),a0		* pointer to variable name
	MOVE.l	d1,(a0)			* clear the variable name
	MOVE.b	d1,Dtypef(a3)		* clear the data type, $80=string, $40=integer,
							* $00=float

LAB_1D2D
	CMP.w		#$04,d1			* done all significant characters?
	BCC.s		LAB_1D2E			* if so go ignore any more

	MOVE.b	d0,(a0,d1.w)		* save the character
	ADDQ.w	#1,d1				* increment index
LAB_1D2E
	BSR		LAB_IGBY			* increment & scan memory (next character)
	BCS.s		LAB_1D2D			* branch if character = "0"-"9" (ok)

							* character wasn't "0" to "9" so ...
	BSR.s		LAB_CASC			* check byte, return C=0 if<"A" or >"Z"
	BCS.s		LAB_1D2D			* branch if = "A"-"Z" (ok)

							* check if string variable
	CMP.b		#'$',d0			* compare with "$"
	BNE.s		LAB_1D44			* branch if not string

							* type is string
	OR.b		#$80,Varname+1(a3)	* set top bit of 2nd character, indicate string
	BSR		LAB_IGBY			* increment & scan memory
	BRA.s		LAB_1D45			* skip integer check

							* check if integer variable
LAB_1D44
	CMP.b		#'&',d0			* compare with "&"
	BNE.s		LAB_1D45			* branch if not integer

							* type is integer
	OR.b		#$80,Varname+2(a3)	* set top bit of 3rd character, indicate integer
	BSR		LAB_IGBY			* increment & scan memory

* after we have determined the variable type we need to determine
* if it's an array of type

							* gets here with character after var name in d0
LAB_1D45
	TST.b		Sufnxf(a3)			* test function name flag
	BEQ.s		LAB_1D48			* if not FN or FN variable continue

	BPL.s		LAB_1D49			* if FN variable go find or create it

							* else was FN name
	MOVE.l	Varname(a3),d0		* get whole function name
	MOVEQ		#8,d1				* set step to next function size -4
	LEA		Sfncl(a3),a0		* get pointer to start of functions
	BRA.s		LAB_1D4B			* go find function

LAB_1D48
	SUB.b		#'(',d0			* subtract "("
	BEQ		LAB_1E17			* if "(" go find, or make, array

* either find or create var
* var name (1st four characters only!) is in Varname

							* variable name wasn't var( .. so look for
							* plain variable
LAB_1D49
	MOVE.l	Varname(a3),d0		* get whole variable name
LAB_1D4A
	MOVEQ		#4,d1				* set step to next variable size -4
	LEA		Svarl(a3),a0		* get pointer to start of variables

	BTST.l	#23,d0			* test if string name
	BEQ.s		LAB_1D4B			* branch if not

	ADDQ.w	#2,d1				* 6 bytes per string entry
	ADDQ.w	#(Sstrl-Svarl),a0		* move to string area

LAB_1D4B
	MOVEA.l	4(a0),a1			* get end address
	MOVEA.l	(a0),a0			* get start address
	BRA.s		LAB_1D5E			* enter loop at exit check

LAB_1D5D
	CMP.l		(a0)+,d0			* compare this variable with name
	BEQ.s		LAB_1DD7			* branch if match (found var)

	ADDA.l	d1,a0				* add offset to next variable
LAB_1D5E
	CMPA.l	a1,a0				* compare address with variable space end
	BNE.s		LAB_1D5D			* if not end go check next

	TST.b		Sufnxf(a3)			* is it a function or function variable
	BNE.s		LAB_1D94			* if was go do DEF or function variable

							* reached end of variable mem without match
							* ... so create new variable, possibly

	LEA		LAB_FVAR(pc),a2		* get the address of the create if doesn't
							* exist call to LAB_GVAR
	CMPA.l	(sp),a2			* compare the return address with expected
	BNE		LAB_UVER			* if not create go do error or return null

* this will only branch if the call to LAB_GVAR wasn't from LAB_SVAR

LAB_1D94
	BTST.b	#0,Sufnxf(a3)		* test function search flag
	BNE		LAB_UFER			* if not doing DEF then go do undefined
							* function error

							* else create new variable/function
LAB_1D98
	MOVEA.l	Earryl(a3),a2		* get end of block to move
	MOVE.l	a2,d2				* copy end of block to move
	SUB.l		a1,d2				* calculate block to move size

	MOVEA.l	a2,a0				* copy end of block to move
	ADDQ.l	#4,d1				* space for one variable/function + name
	ADDA.l	d1,a2				* add space for one variable/function
	MOVE.l	a2,Earryl(a3)		* set new array mem end
	LSR.l		#1,d2				* /2 for word copy
	BEQ.s		LAB_1DAF			* skip move if zero length block

	SUBQ.l	#1,d2				* -1 for DFB loop
	SWAP		d2				* swap high word to low word
LAB_1DAC
	SWAP		d2				* swap high word to low word
LAB_1DAE
	MOVE.w	-(a0),-(a2)			* copy word
	DBF		d2,LAB_1DAE			* loop until done

	SWAP		d2				* swap high word to low word
	DBF		d2,LAB_1DAC			* decrement high count and loop until done

* get here after creating either a function, variable or string
* if function set variables start, string start, array start
* if variable set string start, array start
* if string set array start

LAB_1DAF
	TST.b		Sufnxf(a3)			* was it function
	BMI.s		LAB_1DB0			* branch if was FN

	BTST.l	#23,d0			* was it string
	BNE.s		LAB_1DB2			* branch if string

	BRA.s		LAB_1DB1			* branch if was plain variable

LAB_1DB0
	ADD.l		d1,Svarl(a3)		* set new variable memory start
LAB_1DB1
	ADD.l		d1,Sstrl(a3)		* set new start of strings
LAB_1DB2
	ADD.l		d1,Sarryl(a3)		* set new array memory start
	MOVE.l	d0,(a0)+			* save variable/function name
	MOVE.l	#$00,(a0)			* initialise variable
	BTST.l	#23,d0			* was it string
	BEQ.s		LAB_1DD7			* branch if not string

	MOVE.w	#$00,4(a0)			* else initialise string length

							* found a match for var ((Vrschl) = ptr)
LAB_1DD7
	MOVE.l	d0,d1				* ........ $....... &....... ........
	ADD.l		d1,d1				* .......$ .......& ........ .......0
	SWAP		d1				* ........ .......0 .......$ .......&
	ROR.b		#1,d1				* ........ .......0 .......$ &.......
	LSR.w		#1,d1				* ........ .......0 0....... $&.....�.
	AND.b		#$C0,d1			* mask the type bits
	MOVE.b	d1,Dtypef(a3)		* save the data type

	MOVE.b	#$00,Sufnxf(a3)		* clear FN flag byte

* if you want a non existant variable to return a null value then set the novar
* value at the top of this file to some non zero value

 ifne	novar

	MOVEQ		#-1,d0			* return variable found

 endc

	RTS


*************************************************************************************
*
* set-up array pointer, d0, to first element in array
* set d0 to (a0)+2*(Dimcnt)+$0A

LAB_1DE6
	MOVEQ		#5,d0				* set d0 to 5 (*2 = 10, later)
	ADD.b		Dimcnt(a3),d0		* add # of dimensions (1, 2 or 3)
	ADD.l		d0,d0				* *2 (bytes per dimension size)
	ADD.l		a0,d0				* add array start pointer
	RTS


*************************************************************************************
*
* evaluate unsigned integer expression

LAB_EVIN
	BSR		LAB_IGBY			* increment & scan memory
	BSR		LAB_EVNM			* evaluate expression & check is numeric,
							* else do type mismatch


*************************************************************************************
*
* evaluate positive integer expression, result in d0 and Itemp

LAB_EVPI
	TST.b		FAC1_s(a3)			* test FAC1 sign (b7)
	BMI		LAB_FCER			* do function call error if -ve


*************************************************************************************
*
* evaluate integer expression, no sign check
* result in d0 and Itemp, exit with flags set correctly

LAB_EVIR
	CMPI.b	#$A0,FAC1_e(a3)		* compare exponent with exponent = 2^32 (n>2^31)
	BCS		LAB_2831			* convert FAC1 floating to fixed
							* result in d0 and Itemp
	BNE		LAB_FCER			* if > do function call error, then warm start

	TST.b		FAC1_s(a3)			* test sign of FAC1
	BPL		LAB_2831			* if +ve then ok

	MOVE.l	FAC1_m(a3),d0		* get mantissa
	NEG.l		d0				* do -d0
	BVC		LAB_FCER			* if not $80000000 do FC error, then warm start

	MOVE.l	d0,Itemp(a3)		* else just set it
	RTS


*************************************************************************************
*
* find or make array

LAB_1E17
	MOVE.w	Defdim(a3),-(sp)		* get DIM flag and data type flag (word in mem)
	MOVEQ		#0,d1				* clear dimensions count

* now get the array dimension(s) and stack it (them) before the data type and DIM flag

LAB_1E1F
	MOVE.w	d1,-(sp)			* save dimensions count
	MOVE.l	Varname(a3),-(sp)		* save variable name
	BSR.s		LAB_EVIN			* evaluate integer expression

	SWAP		d0				* swap high word to low word
	TST.w		d0				* test swapped high word
	BNE		LAB_ABER			* if too big do array bounds error

	MOVE.l	(sp)+,Varname(a3)		* restore variable name
	MOVE.w	(sp)+,d1			* restore dimensions count
	MOVE.w	(sp)+,d0			* restore DIM and data type flags
	MOVE.w	Itemp+2(a3),-(sp)		* stack this dimension size
	MOVE.w	d0,-(sp)			* save DIM and data type flags
	ADDQ.w	#1,d1				* increment dimensions count
	BSR		LAB_GBYT			* scan memory
	CMP.b		#$2C,d0			* compare with ","
	BEQ.s		LAB_1E1F			* if found go do next dimension

	MOVE.b	d1,Dimcnt(a3)		* store dimensions count
	BSR		LAB_1BFB			* scan for ")", else do syntax error/warm start
	MOVE.w	(sp)+,Defdim(a3)		* restore DIM and data type flags (word in mem)
	MOVEA.l	Sarryl(a3),a0		* get array mem start

* now check to see if we are at the end of array memory (we would be if there were
* no arrays).

LAB_1E5C
	MOVE.l	a0,Astrtl(a3)		* save as array start pointer
	CMPA.l	Earryl(a3),a0		* compare with array mem end
	BEQ.s		LAB_1EA1			* go build array if not found

							* search for array
	MOVE.l	(a0),d0			* get this array name
	CMP.l		Varname(a3),d0		* compare with array name
	BEQ.s		LAB_1E8D			* array found so branch

							* no match
	MOVEA.l	4(a0),a0			* get this array size
	ADDA.l	Astrtl(a3),a0		* add to array start pointer
	BRA.s		LAB_1E5C			* go check next array

							* found array, are we trying to dimension it?
LAB_1E8D
	TST.b		Defdim(a3)			* are we trying to dimension it?
	BNE		LAB_DDER			* if so do double dimension error/warm start

* found the array and we're not dimensioning it so we must find an element in it

	BSR		LAB_1DE6			* set data pointer, d0, to the first element
							* in the array
	ADDQ.w	#8,a0				* index to dimension count
	MOVE.w	(a0)+,d0			* get no of dimensions
	CMP.b		Dimcnt(a3),d0		* compare with dimensions count
	BEQ		LAB_1F28			* found array so go get element

	BRA		LAB_WDER			* else wrong so do "Wrong dimensions" error

							* array not found, so possibly build it
LAB_1EA1
	TST.b		Defdim(a3)			* test the default DIM flag
	BEQ		LAB_UDER			* if default flag is clear then we are not
							* explicitly dimensioning an array so go
							* do an "Undimensioned array" error

	BSR		LAB_1DE6			* set data pointer, d0, to the first element
							* in the array
	MOVE.l	Varname(a3),d0		* get array name
	MOVE.l	d0,(a0)+			* save array name
	MOVEQ		#4,d1				* set 4 bytes per element
	BTST.l	#23,d0			* test if string array
	BEQ.s		LAB_1EDF			* branch if not string

	MOVEQ		#6,d1				* else 6 bytes per element
LAB_1EDF
	MOVE.l	d1,Asptl(a3)		* set array data size (bytes per element)
	MOVE.b	Dimcnt(a3),d1		* get dimensions count
	ADDQ.w	#4,a0				* skip the array size now (don't know it yet!)
	MOVE.w	d1,(a0)+			* set array's dimensions count

* now calculate the array data space size

LAB_1EC0

* If you want arrays to dimension themselves by default then comment out the test
* above and uncomment the next three code lines and the label LAB_1ED0

*	MOVE.w	#$0A,d1			* set default dimension value, allow 0 to 9
*	TST.b		Defdim(a3)			* test default DIM flag
*	BNE.s		LAB_1ED0			* branch if b6 of Defdim is clear

	MOVE.w	(sp)+,d1			* get dimension size
*LAB_1ED0
	MOVE.w	d1,(a0)+			* save to array header
	BSR		LAB_1F7C			* do this dimension size+1 * array size
							* (d1+1)*(Asptl), result in d0
	MOVE.l	d0,Asptl(a3)		* save array data size
	SUBQ.b	#1,Dimcnt(a3)		* decrement dimensions count
	BNE.s		LAB_1EC0			* loop while not = 0

	ADDA.l	Asptl(a3),a0		* add size to first element address
	BCS		LAB_OMER			* if overflow go do "Out of memory" error

	CMPA.l	Sstorl(a3),a0		* compare with bottom of string memory
	BCS.s		LAB_1ED6			* branch if less (is ok)

	BSR		LAB_GARB			* do garbage collection routine
	CMPA.l	Sstorl(a3),a0		* compare with bottom of string memory
	BCC		LAB_OMER			* if Sstorl <= a0 do "Out of memory"
							* error then warm start

LAB_1ED6						* ok exit, carry set
	MOVE.l	a0,Earryl(a3)		* save array mem end
	MOVEQ		#0,d0				* zero d0
	MOVE.l	Asptl(a3),d1		* get size in bytes
	LSR.l		#1,d1				* /2 for word fill (may be odd # words)
	SUBQ.w	#1,d1				* adjust for DBF loop
LAB_1ED8
	MOVE.w	d0,-(a0)			* decrement pointer and clear word
	DBF		d1,LAB_1ED8			* decrement & loop until low word done

	SWAP		d1				* swap words
	TST.w		d1				* test high word
	BEQ.s		LAB_1F07			* exit if done

	SUBQ.w	#1,d1				* decrement low (high) word
	SWAP		d1				* swap back
	BRA.s		LAB_1ED8			* go do a whole block

* now we need to calculate the array size by doing Earryl - Astrtl

LAB_1F07
	MOVEA.l	Astrtl(a3),a0		* get for calculation and as pointer
	MOVE.l	Earryl(a3),d0		* get array memory end
	SUB.l		a0,d0				* calculate array size
	MOVE.l	d0,4(a0)			* save size to array
	TST.b		Defdim(a3)			* test default DIM flag
	BNE.s		RTS_011			* exit (RET) if this was a DIM command

							* else, find element
	ADDQ.w	#8,a0				* index to dimension count
	MOVE.w	(a0)+,Dimcnt(a3)		* get array's dimension count

* we have found, or built, the array. now we need to find the element

LAB_1F28
	MOVEQ		#0,d0				* clear first result
	MOVE.l	d0,Asptl(a3)		* clear array data pointer

* compare nth dimension bound (a0) with nth index (sp)+
* if greater do array bounds error

LAB_1F2C
	MOVE.w	(a0)+,d1			* get nth dimension bound
	CMP.w		(sp),d1			* compare nth index with nth dimension bound
	BCS		LAB_ABER			* if d1 less or = do array bounds error

* now do pointer = pointer * nth dimension + nth index

	TST.l		d0				* test pointer
	BEQ.s		LAB_1F5A			* skip multiply if last result = null

	BSR.s		LAB_1F7C			* do this dimension size+1 * array size
LAB_1F5A
	MOVEQ		#0,d1				* clear longword
	MOVE.w	(sp)+,d1			* get nth dimension index
	ADD.l		d1,d0				* add index to size
	MOVE.l	d0,Asptl(a3)		* save array data pointer

	SUBQ.b	#1,Dimcnt(a3)		* decrement dimensions count
	BNE.s		LAB_1F2C			* loop if dimensions still to do

	MOVE.b	#0,Dtypef(a3)		* set data type to float
	MOVEQ		#3,d1				* set for numeric array
	TST.b		Varname+1(a3)		* test if string array
	BPL.s		LAB_1F6A			* branch if not string

	MOVEQ		#5,d1				* else set for string array
	MOVE.b	#$80,Dtypef(a3)		* and set data type to string
	BRA.s		LAB_1F6B			* skip integer test

LAB_1F6A
	TST.b		Varname+2(a3)		* test if integer array
	BPL.s		LAB_1F6B			* branch if not integer

	MOVE.b	#$40,Dtypef(a3)		* else set data type to integer
LAB_1F6B
	BSR.s		LAB_1F7C			* do element size (d1) * array size (Asptl)
	ADDA.l	d0,a0				* add array data start pointer
RTS_011
	RTS


*************************************************************************************
*
* do this dimension size (d1) * array data size (Asptl)

* do a 16 x 32 bit multiply
* d1 holds the 16 bit multiplier
* Asptl holds the 32 bit multiplicand

* d0	bbbb  bbbb
* d1	0000  aaaa
*	----------
* d0	rrrr  rrrr

LAB_1F7C
	MOVE.l	Asptl(a3),d0		* get result
	MOVE.l	d0,d2				* copy it
	SWAP		d2				* shift high word to low word
	MULU.w	d1,d0				* d1 * low word = low result
	MULU.w	d1,d2				* d1 * high word = high result
	SWAP		d2				* align words for test
	TST.w		d2				* must be zero
	BNE		LAB_OMER			* if overflow go do "Out of memory" error

	ADD.l		d2,d0				* calculate result
	BCS		LAB_OMER			* if overflow go do "Out of memory" error

	ADD.l		Asptl(a3),d0		* add original
	BCS		LAB_OMER			* if overflow go do "Out of memory" error

	RTS


*************************************************************************************
*
* perform FRE()

LAB_FRE
	TST.b		Dtypef(a3)			* test data type, $80=string, $40=integer,
							* $00=float
	BPL.s		LAB_1FB4			* branch if numeric

	BSR		LAB_22B6			* pop string off descriptor stack, or from
							* top of string space, returns d0 = length,
							* a0 = pointer

							* FRE(n) was numeric so do this
LAB_1FB4
	BSR		LAB_GARB			* go do garbage collection
	MOVE.l	Sstorl(a3),d0		* get bottom of string space
	SUB.l		Earryl(a3),d0		* subtract array mem end


*************************************************************************************
*
* convert d0 to signed longword in FAC1

LAB_AYFC
	MOVE.b	#$00,Dtypef(a3)		* clear data type, $80=string, $40=integer,
							* $00=float
	MOVE.w	#$A000,FAC1_e(a3)		* set FAC1 exponent and clear sign (b7)
	MOVE.l	d0,FAC1_m(a3)		* save FAC1 mantissa
	BPL		LAB_24D0			* convert if +ve

	ORI.b		#1,CCR			* else set carry
	BRA		LAB_24D0			* do +/- (carry is sign) & normalise FAC1


*************************************************************************************
*
* remember if the line length is zero (infinite line) then POS(n) will return
* position MOD tabsize

* perform POS()

LAB_POS
	MOVE.b	TPos(a3),d0			* get terminal position

* convert d0 to unsigned byte in FAC1

LAB_1FD0
	AND.l		#$FF,d0			* clear high bits
	BRA.s		LAB_AYFC			* convert d0 to signed longword in FAC1 & RET

* check not direct (used by DEF and INPUT)

LAB_CKRN
	TST.b		Clinel(a3)			* test current line #
	BMI		LAB_IDER			* if -ve go do illegal direct error then warm
							* start

	RTS						* can continue so return


*************************************************************************************
*
* perform DEF

LAB_DEF
	MOVEQ		#TK_FN-$100,d0		* get FN token
	BSR		LAB_SCCA			* scan for CHR$(d0), else syntax error and
							* warm start
							* return character after d0
	MOVE.b	#$80,Sufnxf(a3)		* set FN flag bit
	BSR		LAB_1D12			* get FN name
	MOVE.l	a0,func_l(a3)		* save function pointer

	BSR.s		LAB_CKRN			* check not direct (back here if ok)
	CMP.b		#$28,(a5)+			* check next byte is "(" and increment
	BNE		LAB_SNER			* else do syntax error/warm start

	MOVE.b	#$7E,Sufnxf(a3)		* set FN variable flag bits
	BSR		LAB_SVAR			* search for or create a variable
							* return the variable address in a0
	BSR		LAB_1BFB			* scan for ")", else do syntax error/warm start
	MOVEQ		#TK_EQUAL-$100,d0		* = token
	BSR		LAB_SCCA			* scan for CHR$(A), else syntax error/warm start
							* return character after d0
	MOVE.l	Varname(a3),-(sp)		* push current variable name
	MOVE.l	a5,-(sp)			* push BASIC execute pointer
	BSR		LAB_DATA			* go perform DATA, find end of DEF FN statement
	MOVEA.l	func_l(a3),a0		* get the function pointer
	MOVE.l	(sp)+,(a0)			* save BASIC execute pointer to function
	MOVE.l	(sp)+,4(a0)			* save current variable name to function
	RTS


*************************************************************************************
*
* evaluate FNx

LAB_201E
	MOVE.b	#$81,Sufnxf(a3)		* set FN flag (find not create)
	BSR		LAB_IGBY			* increment & scan memory
	BSR		LAB_1D12			* get FN name
	MOVE.b	Dtypef(a3),-(sp)		* push data type flag (function type)
	MOVE.l	a0,-(sp)			* push function pointer
	CMP.b		#$28,(a5)			* check next byte is "(", no increment
	BNE		LAB_SNER			* else do syntax error/warm start

	BSR		LAB_1BF7			* evaluate expression within parentheses
	MOVEA.l	(sp)+,a0			* pop function pointer
	MOVE.l	a0,func_l(a3)		* set function pointer
	MOVE.b	Dtypef(a3),-(sp)		* push data type flag (function expression type)

	MOVE.l	4(a0),d0			* get function variable name
	BSR		LAB_1D4A			* go find function variable (already created)

							* now check type match for variable
	MOVE.b	(sp)+,d0			* pop data type flag (function expression type)
	ROL.b		#1,d0				* set carry if type = string
	BSR		LAB_CKTM			* type match check, set C for string

							* now stack the function variable value before
							* use
	BEQ.s		LAB_2043			* branch if not string

	LEA		des_sk_e(a3),a1		* get string stack pointer max+1
	CMPA.l	a1,a4				* compare string stack pointer with max+1
	BEQ		LAB_SCER			* if no space on the stack go do string too
							* complex error

	MOVE.w	4(a0),-(a4)			* string length on descriptor stack
	MOVE.l	(a0),-(a4)			* string address on stack
	BRA.s		LAB_204S			* skip var push

LAB_2043
	MOVE.l	(a0),-(sp)			* push variable
LAB_204S
	MOVE.l	a0,-(sp)			* push variable address
	MOVE.b	Dtypef(a3),-(sp)		* push variable data type

	BSR.s		LAB_2045			* pack function expression value into (a0)
							* (function variable)
	MOVE.l	a5,-(sp)			* push BASIC execute pointer
	MOVEA.l	func_l(a3),a0		* get function pointer
	MOVEA.l	(a0),a5			* save function execute ptr as BASIC execute ptr
	BSR		LAB_EVEX			* evaluate expression
	BSR		LAB_GBYT			* scan memory
	BNE		LAB_SNER			* if not [EOL] or [EOS] do syntax error and
							* warm start

	MOVE.l	(sp)+,a5			* restore BASIC execute pointer

* restore variable from stack and test data type

	MOVE.b	(sp)+,d0			* pull variable data type
	MOVEA.l	(sp)+,a0			* pull variable address
	TST.b		d0				* test variable data type
	BPL.s		LAB_204T			* branch if not string

	MOVE.l	(a4)+,(a0)			* string address from descriptor stack
	MOVE.w	(a4)+,4(a0)			* string length from descriptor stack
	BRA.s		LAB_2044			* skip variable pull

LAB_204T
	MOVE.l	(sp)+,(a0)			* restore variable from stack
LAB_2044
	MOVE.b	(sp)+,d0			* pop data type flag (function type)
	ROL.b		#1,d0				* set carry if type = string
	BSR		LAB_CKTM			* type match check, set C for string
	RTS

LAB_2045
	TST.b		Dtypef(a3)			* test data type
	BPL		LAB_2778			* if numeric pack FAC1 into variable (a0)
							* and return

	MOVEA.l	a0,a2				* copy variable pointer
	BRA		LAB_17D6			* go do string LET & return



*************************************************************************************
*
* perform STR$()

LAB_STRS
	BSR		LAB_2970			* convert FAC1 to string

* scan, set up string
* print " terminated string to FAC1 stack

LAB_20AE
	MOVEQ		#$22,d2			* set Srchc character (terminator 1)
	MOVE.w	d2,d3				* set Asrch character (terminator 2)

* print d2/d3 terminated string to FAC1 stack
* d2 = Srchc, d3 = Asrch, a0 is source
* a6 is temp

LAB_20B4
	MOVEQ		#0,d1				* clear longword
	SUBQ.w	#1,d1				* set length to -1
	MOVEA.l	a0,a2				* copy start to calculate end
LAB_20BE
	ADDQ.w	#1,d1				* increment length
	MOVE.b	(a0,d1.w),d0		* get byte from string
	BEQ.s		LAB_20D0			* exit loop if null byte [EOS]

	CMP.b		d2,d0				* compare with search character (terminator 1)
	BEQ.s		LAB_20CB			* branch if terminator

	CMP.b		d3,d0				* compare with terminator 2
	BNE.s		LAB_20BE			* loop if not terminator 2 (or null string)

LAB_20CB
	CMP.b		#$22,d0			* compare with "
	BNE.s		LAB_20D0			* branch if not "

	ADDQ.w	#1,a2				* else increment string start (skip " at end)
LAB_20D0
	ADDA.l	d1,a2				* add longowrd length to make string end+1

	CMPA.l	a3,a0				* is string in ram
	BCS.s		LAB_RTST			* if not go push descriptor on stack & exit
							* (could be message string from ROM)

	CMPA.l	Smeml(a3),a0		* is string in utility ram
	BCC.s		LAB_RTST			* if not go push descriptor on stack & exit
							* (is in string or program space)

							* (else) copy string to string memory
LAB_20C9
	MOVEA.l	a0,a1				* copy descriptor pointer
	MOVE.l	d1,d0				* copy longword length
	BNE.s		LAB_20D8			* branch if not null string

	MOVEA.l	d1,a0				* make null pointer
	BRA.s		LAB_RTST			* go push descriptor on stack & exit

LAB_20D8
	BSR.s		LAB_2115			* make string space d1 bytes long
	ADDA.l	d1,a0				* new string end
	ADDA.l	d1,a1				* old string end
	SUBQ.w	#1,d0				* -1 for DBF loop
LAB_20E0
	MOVE.b	-(a1),-(a0)			* copy byte (source can be odd aligned)
	DBF		d0,LAB_20E0			* loop until done



*************************************************************************************
*
* check for space on descriptor stack then ...
* put string address and length on descriptor stack & update stack pointers
* start is in a0, length is in d1

LAB_RTST
	LEA		des_sk_e(a3),a1		* get string stack pointer max+1
	CMPA.l	a1,a4				* compare string stack pointer with max+1
	BEQ		LAB_SCER			* if no space on string stack ..
							* .. go do 'string too complex' error

							* push string & update pointers
	MOVE.w	d1,-(a4)			* string length on descriptor stack
	MOVE.l	a0,-(a4)			* string address on stack
	MOVE.l	a4,FAC1_m(a3)		* string descriptor pointer in FAC1
	MOVE.b	#$80,Dtypef(a3)		* save data type flag, $80=string
	RTS


*************************************************************************************
*
* build descriptor a0/d1
* make space in string memory for string d1.w long
* return pointer in a0/Sutill

LAB_2115
	TST.w		d1				* test length
	BEQ.s		LAB_2128			* branch if user wants null string

							* make space for string d1 long
	MOVE.l	d0,-(sp)			* save d0
	MOVEQ		#0,d0				* clear longword
	MOVE.b	d0,Gclctd(a3)		* clear garbage collected flag (b7)
	MOVEQ		#1,d0				* +1 to possibly round up
	AND.w		d1,d0				* mask odd bit
	ADD.w		d1,d0				* ensure d0 is even length
	BCC.s		LAB_2117			* branch if no overflow

	MOVEQ		#1,d0				* set to allocate 65536 bytes
	SWAP		d0				* makes $00010000
LAB_2117
	MOVEA.l	Sstorl(a3),a0		* get bottom of string space
	SUBA.l	d0,a0				* subtract string length
	CMPA.l	Earryl(a3),a0		* compare with top of array space
	BCS.s		LAB_2137			* if less do out of memory error

	MOVE.l	a0,Sstorl(a3)		* save bottom of string space
	MOVE.l	a0,Sutill(a3)		* save string utility pointer
	MOVE.l	(sp)+,d0			* restore d0
	TST.w		d1				* set flags on length
	RTS

LAB_2128
	MOVEA.w	d1,a0				* make null pointer
	RTS

LAB_2137
	TST.b		Gclctd(a3)			* get garbage collected flag
	BMI		LAB_OMER			* do "Out of memory" error, then warm start

	MOVE.l	a1,-(sp)			* save a1
	BSR.s		LAB_GARB			* else go do garbage collection
	MOVEA.l	(sp)+,a1			* restore a1
	MOVE.b	#$80,Gclctd(a3)		* set garbage collected flag
	BRA.s		LAB_2117			* go try again


*************************************************************************************
*
* garbage collection routine

LAB_GARB
	MOVEM.l	d0-d2/a0-a2,-(sp)		* save registers
	MOVE.l	Ememl(a3),Sstorl(a3)	* start with no strings

							* re-run routine from last ending
LAB_214B
	MOVE.l	Earryl(a3),d1		* set highest uncollected string so far
	MOVEQ		#0,d0				* clear longword
	MOVEA.l	d0,a1				* clear string to move pointer
	MOVEA.l	Sstrl(a3),a0		* set pointer to start of strings
	LEA		4(a0),a0			* index to string pointer
	MOVEA.l	Sarryl(a3),a2		* set end pointer to start of arrays (end of
							* strings)
	BRA.s		LAB_2176			* branch into loop at end loop test

LAB_2161
	BSR		LAB_2206			* test and set if this is the highest string
	LEA		10(a0),a0			* increment to next string
LAB_2176
	CMPA.l	a2,a0				* compare end of area with pointer
	BCS.s		LAB_2161			* go do next if not at end

* done strings, now do arrays.

	LEA		-4(a0),a0			* decrement pointer to start of arrays
	MOVEA.l	Earryl(a3),a2		* set end pointer to end of arrays
	BRA.s		LAB_218F			* branch into loop at end loop test

LAB_217E
	MOVE.l	4(a0),d2			* get array size
	ADD.l		a0,d2				* makes start of next array

	MOVE.l	(a0),d0			* get array name
	BTST		#23,d0			* test string flag
	BEQ.s		LAB_218B			* branch if not string

	MOVE.w	8(a0),d0			* get # of dimensions
	ADD.w		d0,d0				* *2
	ADDA.w	d0,a0				* add to skip dimension size(s)
	LEA		10(a0),a0			* increment to first element
LAB_2183
	BSR.s		LAB_2206			* test and set if this is the highest string
	ADDQ.w	#6,a0				* increment to next element
	CMPA.l	d2,a0				* compare with start of next array
	BNE.s		LAB_2183			* go do next if not at end of array

LAB_218B
	MOVEA.l	d2,a0				* pointer to next array
LAB_218F
	CMPA.l	a0,a2				* compare pointer with array end
	BNE.s		LAB_217E			* go do next if not at end

* done arrays and variables, now just the descriptor stack to do

	MOVEA.l	a4,a0				* get descriptor stack pointer
	LEA		des_sk(a3),a2		* set end pointer to end of stack
	BRA.s		LAB_21C4			* branch into loop at end loop test

LAB_21C2
	BSR.s		LAB_2206			* test and set if this is the highest string
	LEA		6(a0),a0			* increment to next string
LAB_21C4
	CMPA.l	a0,a2				* compare pointer with stack end
	BNE.s		LAB_21C2			* go do next if not at end

* descriptor search complete, now either exit or set-up and move string

	MOVE.l	a1,d0				* set the flags (a1 is move string)
	BEQ.s		LAB_21D1			* go tidy up and exit if no move

	MOVEA.l	(a1),a0			* a0 is now string start
	MOVEQ		#0,d1				* clear d1
	MOVE.w	4(a1),d1			* d1 is string length
	ADDQ.l	#1,d1				* +1
	AND.b		#$FE,d1			* make even length
	ADDA.l	d1,a0				* pointer is now to string end+1
	MOVEA.l	Sstorl(a3),a2		* is destination end+1
	CMPA.l	a2,a0				* does the string need moving
	BEQ.s		LAB_2240			* branch if not

	LSR.l		#1,d1				* word move so do /2
	SUBQ.w	#1,d1				* -1 for DBF loop
LAB_2216
	MOVE.w	-(a0),-(a2)			* copy word
	DBF		d1,LAB_2216			* loop until done

	MOVE.l	a2,(a1)			* save new string start
LAB_2240
	MOVE.l	(a1),Sstorl(a3)		* string start is new string mem start
	BRA		LAB_214B			* re-run routine from last ending
							* (but don't collect this string)

LAB_21D1
	MOVEM.l	(sp)+,d0-d2/a0-a2		* restore registers
	RTS

* test and set if this is the highest string

LAB_2206
	MOVE.l	(a0),d0			* get this string pointer
	BEQ.s		RTS_012			* exit if null string

	CMP.l		d0,d1				* compare with highest uncollected string so far
	BCC.s		RTS_012			* exit if <= with highest so far

	CMP.l		Sstorl(a3),d0		* compare with bottom of string space
	BCC.s		RTS_012			* exit if >= bottom of string space

	MOVEQ		#-1,d0			* d0 = $FFFFFFFF
	MOVE.w	4(a0),d0			* d0 is string length
	NEG.w		d0				* make -ve
	AND.b		#$FE,d0			* make -ve even length
	ADD.l		Sstorl(a3),d0		* add string store to -ve length
	CMP.l		(a0),d0			* compare with string address
	BEQ.s		LAB_2212			* if = go move string store pointer down

	MOVE.l	(a0),d1			* highest = current
	MOVEA.l	a0,a1				* string to move = current
	RTS

LAB_2212
	MOVE.l	d0,Sstorl(a3)		* set new string store start
RTS_012
	RTS


*************************************************************************************
*
* concatenate - add strings
* string descriptor 1 is in FAC1_m, string 2 is in line

LAB_224D
	PEA		LAB_1ADB(pc)		* continue evaluation after concatenate
	MOVE.l	FAC1_m(a3),-(sp)		* stack descriptor pointer for string 1

	BSR		LAB_GVAL			* get value from line
	TST.b		Dtypef(a3)			* test data type flag
	BPL		LAB_TMER			* if type is not string do type mismatch error

	MOVEA.l	(sp)+,a0			* restore descriptor pointer for string 1

*************************************************************************************
*
* concatenate
* string descriptor 1 is in a0, string descriptor 2 is in FAC1_m

LAB_224E
	MOVEA.l	FAC1_m(a3),a1		* copy descriptor pointer 2
	MOVE.w	4(a0),d1			* get length 1
	ADD.w		4(a1),d1			* add length 2
	BCS		LAB_SLER			* if overflow go do 'string too long' error

	MOVE.l	a0,-(sp)			* save descriptor pointer 1
	BSR		LAB_2115			* make space d1 bytes long
	MOVE.l	a0,FAC2_m(a3)		* save new string start pointer
	MOVEA.l	(sp),a0			* copy descriptor pointer 1 from stack
	MOVE.w	4(a0),d0			* get length
	MOVEA.l	(a0),a0			* get string pointer
	BSR.s		LAB_229E			* copy string d0 bytes long from a0 to Sutill
							* return with a0 = pointer, d1 = length

	MOVEA.l	FAC1_m(a3),a0		* get descriptor pointer for string 2
	BSR.s		LAB_22BA			* pop (a0) descriptor, returns with ..
							* a0 = pointer, d0 = length
	BSR.s		LAB_229E			* copy string d0 bytes long from a0 to Sutill
							* return with a0 = pointer, d1 = length

	MOVEA.l	(sp)+,a0			* get descriptor pointer for string 1
	BSR.s		LAB_22BA			* pop (a0) descriptor, returns with ..
							* d0 = length, a0 = pointer

	MOVEA.l	FAC2_m(a3),a0		* retreive the result string pointer
	MOVE.l	a0,d1				* copy the result string pointer
	BEQ		LAB_RTST			* if it is a null string just return it
							* a0 = pointer, d1 = length

	NEG.l		d1				* else make the start pointer negative
	ADD.l		Sutill(a3),d1		* add the end pointert to give the length
	BRA		LAB_RTST			* push string on descriptor stack
							* a0 = pointer, d1 = length


*************************************************************************************
*
* copy string d0 bytes long from a0 to Sutill
* return with a0 = pointer, d1 = length

LAB_229E
	MOVE.w	d0,d1				* copy and check length
	BEQ.s		RTS_013			* skip copy if null

	MOVEA.l	Sutill(a3),a1		* get destination pointer
	MOVE.l	a1,-(sp)			* save destination string pointer
	SUBQ.w	#1,d0				* subtract for DBF loop
LAB_22A0
	MOVE.b	(a0)+,(a1)+			* copy byte
	DBF		d0,LAB_22A0			* loop if not done

	MOVE.l	a1,Sutill(a3)		* update Sutill to end of copied string
	MOVEA.l	(sp)+,a0			* restore destination string pointer
RTS_013
	RTS


*************************************************************************************
*
* pop string off descriptor stack, or from top of string space
* returns with d0.l = length, a0 = pointer

LAB_22B6
	MOVEA.l	FAC1_m(a3),a0		* get descriptor pointer


*************************************************************************************
*
* pop (a0) descriptor off stack or from string space
* returns with d0.l = length, a0 = pointer

LAB_22BA
	MOVEM.l	a1/d1,-(sp)			* save other regs
	CMPA.l	a0,a4				* is string on the descriptor stack
	BNE.s		LAB_22BD			* skip pop if not

	ADDQ.w	#$06,a4			* else update stack pointer
LAB_22BD
	MOVEQ		#0,d0				* clear string length longword
	MOVEA.l	(a0)+,a1			* get string address
	MOVE.w	(a0)+,d0			* get string length

	CMPA.l	a0,a4				* was it on the descriptor stack
	BNE.s		LAB_22E6			* branch if it wasn't

	CMPA.l	Sstorl(a3),a1		* compare string address with bottom of string
							* space
	BNE.s		LAB_22E6			* branch if <>

	MOVEQ		#1,d1				* mask for odd bit
	AND.w		d0,d1				* AND length
	ADD.l		d0,d1				* make it fit word aligned length

	ADD.l		d1,Sstorl(a3)		* add to bottom of string space
LAB_22E6
	MOVEA.l	a1,a0				* copy to a0
	MOVEM.l	(sp)+,a1/d1			* restore other regs
	TST.l		d0				* set flags on length
	RTS


*************************************************************************************
*
* perform CHR$()

LAB_CHRS
	BSR		LAB_EVBY			* evaluate byte expression, result in d0 and
							* Itemp
LAB_MKCHR
	MOVEQ		#1,d1				* string is single byte
	BSR		LAB_2115			* make string space d1 bytes long
							* return a0/Sutill = pointer, others unchanged
	MOVE.b	d0,(a0)			* save byte in string (byte IS string!)
	BRA		LAB_RTST			* push string on descriptor stack
							* a0 = pointer, d1 = length


*************************************************************************************
*
* perform LEFT$()

* enter with a0 is descriptor, d0 & Itemp is word 1

LAB_LEFT
	EXG		d0,d1				* word in d1
	BSR		LAB_1BFB			* scan for ")", else do syntax error/warm start

	TST.l		d1				* test returned length
	BEQ.s		LAB_231C			* branch if null return

	MOVEQ		#0,d0				* clear start offset
	CMP.w		4(a0),d1			* compare word parameter with string length
	BCS.s		LAB_231C			* branch if string length > word parameter

	BRA.s		LAB_2317			* go copy whole string


*************************************************************************************
*
* perform RIGHT$()

* enter with a0 is descriptor, d0 & Itemp is word 1

LAB_RIGHT
	EXG		d0,d1				* word in d1
	BSR		LAB_1BFB			* scan for ")", else do syntax error/warm start

	TST.l		d1				* test returned length
	BEQ.s		LAB_231C			* branch if null return

	MOVE.w	4(a0),d0			* get string length
	SUB.l		d1,d0				* subtract word
	BCC.s		LAB_231C			* branch if string length > word parameter

							* else copy whole string
LAB_2316
	MOVEQ		#0,d0				* clear start offset
LAB_2317
	MOVE.w	4(a0),d1			* else make parameter = length

* get here with ...
*   a0 - points to descriptor
*   d0 - is offset from string start
*   d1 - is required string length

LAB_231C
	MOVEA.l	a0,a1				* save string descriptor pointer
	BSR		LAB_2115			* make string space d1 bytes long
							* return a0/Sutill = pointer, others unchanged
	MOVEA.l	a1,a0				* restore string descriptor pointer
	MOVE.l	d0,-(sp)			* save start offset (longword)
	BSR.s		LAB_22BA			* pop (a0) descriptor, returns with ..
							* d0 = length, a0 = pointer
	ADDA.l	(sp)+,a0			* adjust pointer to start of wanted string
	MOVE.w	d1,d0				* length to d0
	BSR		LAB_229E			* store string d0 bytes long from (a0) to
							* (Sutill) return with a0 = pointer,
							* d1 = length
	BRA		LAB_RTST			* push string on descriptor stack
							* a0 = pointer, d1 = length


*************************************************************************************
*
* perform MID$()

* enter with a0 is descriptor, d0 & Itemp is word 1

LAB_MIDS
	MOVEQ		#0,d7				* clear longword
	SUBQ.w	#1,d7				* set default length = 65535
	MOVE.l	d0,-(sp)			* save word 1
	BSR		LAB_GBYT			* scan memory
	CMP.b		#',',d0			* was it ","
	BNE.s		LAB_2358			* branch if not "," (skip second byte get)

	MOVE.b	(a5)+,d0			* increment pointer past ","
	MOVE.l	a0,-(sp)			* save descriptor pointer
	BSR		LAB_GTWO			* get word parameter, result in d0 and Itemp
	MOVEA.l	(sp)+,a0			* restore descriptor pointer
	MOVE.l	d0,d7				* copy length
LAB_2358
	BSR		LAB_1BFB			* scan for ")", else do syntax error then warm
							* start
	MOVE.l	(sp)+,d0			* restore word 1
	MOVEQ		#0,d1				* null length
	SUBQ.l	#1,d0				* decrement start index (word 1)
	BMI		LAB_FCER			* if was null do function call error then warm
							* start

	CMP.w		4(a0),d0			* compare string length with start index
	BCC.s		LAB_231C			* if start not in string do null string (d1=0)

	MOVE.l	d7,d1				* get length back
	ADD.w		d0,d7				* d7 now = MID$() end
	BCS.s		LAB_2368			* already too long so do RIGHT$ equivalent

	CMP.w		4(a0),d7			* compare string length with start index+length
	BCS.s		LAB_231C			* if end in string go do string

LAB_2368
	MOVE.w	4(a0),d1			* get string length
	SUB.w		d0,d1				* subtract start offset
	BRA.s		LAB_231C			* go do string (effectively RIGHT$)


*************************************************************************************
*
* perform LCASE$()

LAB_LCASE
	BSR		LAB_22B6			* pop string off descriptor stack or from memory
							* returns with d0 = length, a0 = pointer
	MOVE.l	d0,d1				* copy the string length
	BEQ.s		NoString			* if null go return a null string

* else copy and change the string

	MOVEA.l	a0,a1				* copy the string address
	BSR		LAB_2115			* make a string space d1 bytes long
	ADDA.l	d1,a0				* new string end
	ADDA.l	d1,a1				* old string end
	MOVE.w	d1,d2				* copy length for loop
	SUBQ.w	#1,d2				* -1 for DBF loop
LC_loop
	MOVE.b	-(a1),d0			* get byte from string

	CMP.b		#$5B,d0			* compare with "Z"+1
	BCC.s		NoUcase			* if > "Z" skip change

	CMP.b		#$41,d0			* compare with "A"
	BCS.s		NoUcase			* if < "A" skip change

	ORI.b		#$20,d0			* convert upper case to lower case
NoUcase
	MOVE.b	d0,-(a0)			* copy upper case byte back to string
	DBF		d2,LC_loop			* decrement and loop if not all done

	BRA.s		NoString			* tidy up & exit (branch always)


*************************************************************************************
*
* perform UCASE$()

LAB_UCASE
	BSR		LAB_22B6			* pop string off descriptor stack or from memory
							* returns with d0 = length, a0 = pointer
	MOVE.l	d0,d1				* copy the string length
	BEQ.s		NoString			* if null go return a null string

* else copy and change the string

	MOVEA.l	a0,a1				* copy the string address
	BSR		LAB_2115			* make a string space d1 bytes long
	ADDA.l	d1,a0				* new string end
	ADDA.l	d1,a1				* old string end
	MOVE.w	d1,d2				* copy length for loop
	SUBQ.w	#1,d2				* -1 for DBF loop
UC_loop
	MOVE.b	-(a1),d0			* get a byte from the string

	CMP.b		#$61,d0			* compare with "a"
	BCS.s		NoLcase			* if < "a" skip change

	CMP.b		#$7B,d0			* compare with "z"+1
	BCC.s		NoLcase			* if > "z" skip change

	ANDI.b	#$DF,d0			* convert lower case to upper case
NoLcase
	MOVE.b	d0,-(a0)			* copy upper case byte back to string
	DBF		d2,UC_loop			* decrement and loop if not all done

NoString
	BRA		LAB_RTST			* push string on descriptor stack
							* a0 = pointer, d1 = length


*************************************************************************************
*
* perform SADD()

LAB_SADD
	MOVE.b	(a5)+,d0			* increment pointer
	BSR		LAB_GVAR			* get variable address in a0
	BSR		LAB_1BFB			* scan for ")", else do syntax error/warm start
	TST.b		Dtypef(a3)			* test data type flag
	BPL		LAB_TMER			* if numeric do Type missmatch Error

* if you want a non existant variable to return a null value then set the novar
* value at the top of this file to some non zero value

 ifne	novar

	MOVE.l	a0,d0				* test the variable found flag
	BEQ		LAB_AYFC			* if not found go return null

 endc

	MOVE.l	(a0),d0			* get string address
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & return


*************************************************************************************
*
* perform LEN()

LAB_LENS
	PEA		LAB_AYFC(pc)		* set return address to convert d0 to signed
							* longword in FAC1
	BRA		LAB_22B6			* pop string off descriptor stack or from memory
							* returns with d0 = length, a0 = pointer


*************************************************************************************
*
* perform ASC()

LAB_ASC
	BSR		LAB_22B6			* pop string off descriptor stack or from memory
							* returns with d0 = length, a0 = pointer
	TST.w		d0				* test length
	BEQ		LAB_FCER			* if null do function call error then warm start

	MOVE.b	(a0),d0			* get first character byte
	BRA		LAB_1FD0			* convert d0 to unsigned byte in FAC1 & return


*************************************************************************************
*
* increment and get byte, result in d0 and Itemp

LAB_SGBY
	BSR		LAB_IGBY			* increment & scan memory


*************************************************************************************
*
* get byte parameter, result in d0 and Itemp

LAB_GTBY
	BSR		LAB_EVNM			* evaluate expression & check is numeric,
							* else do type mismatch


*************************************************************************************
*
* evaluate byte expression, result in d0 and Itemp

LAB_EVBY
	BSR		LAB_EVPI			* evaluate positive integer expression
							* result in d0 and Itemp
	MOVEQ		#$80,d1			* set mask/2
	ADD.l		d1,d1				* =$FFFFFF00
	AND.l		d0,d1				* check top 24 bits
	BNE		LAB_FCER			* if <> 0 do function call error/warm start

	RTS


*************************************************************************************
*
* get word parameter, result in d0 and Itemp

LAB_GTWO
	BSR		LAB_EVNM			* evaluate expression & check is numeric,
							* else do type mismatch
	BSR		LAB_EVPI			* evaluate positive integer expression
							* result in d0 and Itemp
	SWAP		d0				* copy high word to low word
	TST.w		d0				* set flags
	BNE		LAB_FCER			* if <> 0 do function call error/warm start

	SWAP		d0				* copy high word to low word
	RTS


*************************************************************************************
*
* perform VAL()

LAB_VAL
	BSR		LAB_22B6			* pop string off descriptor stack or from memory
							* returns with d0 = length, a0 = pointer
	BEQ.s		LAB_VALZ			* string was null so set result = $00
							* clear FAC1 exponent & sign & return

	MOVEA.l	a5,a6				* save BASIC execute pointer
	MOVEA.l	a0,a5				* copy string pointer to execute pointer
	ADDA.l	d0,a0				* string end+1
	MOVE.b	(a0),d0			* get byte from string+1
	MOVE.w	d0,-(sp)			* save it
	MOVE.l	a0,-(sp)			* save address
	MOVE.b	#0,(a0)			* null terminate string
	BSR		LAB_GBYT			* scan memory
	BSR		LAB_2887			* get FAC1 from string
	MOVEA.l	(sp)+,a0			* restore pointer
	MOVE.w	(sp)+,d0			* pop byte
	MOVE.b	d0,(a0)			* restore to memory
	MOVEA.l	a6,a5				* restore BASIC execute pointer
	RTS

LAB_VALZ
	MOVE.w	d0,FAC1_e(a3)		* clear FAC1 exponent & sign
	RTS


*************************************************************************************
*
* get two parameters for POKE or WAIT, first parameter in a0, second in d0

LAB_GADB
	BSR		LAB_EVNM			* evaluate expression & check is numeric,
							* else do type mismatch
	BSR		LAB_EVIR			* evaluate integer expression
							* (does FC error not OF error if out of range)
	MOVE.l	d0,-(sp)			* copy to stack
	BSR		LAB_1C01			* scan for ",", else do syntax error/warm start
	BSR.s		LAB_GTBY			* get byte parameter, result in d0 and Itemp
	MOVEA.l	(sp)+,a0			* pull address
	RTS


*************************************************************************************
*
* get two parameters for DOKE or WAITW, first parameter in a0, second in d0

LAB_GADW
	BSR.s		LAB_GEAD			* get even address for word/long memory actions
							* address returned in d0 and on the stack
	BSR		LAB_1C01			* scan for ",", else do syntax error/warm start
	BSR		LAB_EVNM			* evaluate expression & check is numeric,
							* else do type mismatch
	BSR		LAB_EVIR			* evaluate integer expression
							* result in d0 and Itemp
	SWAP		d0				* swap words
	TST.w		d0				* test high word
	BEQ.s		LAB_XGADW			* exit if null

	ADDQ.w	#1,d0				* increment word
	BNE		LAB_FCER			* if <> 0 do function call error/warm start

LAB_XGADW
	SWAP		d0				* swap words back
	MOVEA.l	(sp)+,a0			* pull address
	RTS


*************************************************************************************
*
* get even address (for word or longword memory actions)
* address returned in d0 and on the stack
* does address error if the address is odd

LAB_GEAD
	BSR		LAB_EVNM			* evaluate expression & check is numeric,
							* else do type mismatch
	BSR		LAB_EVIR			* evaluate integer expression
							* (does FC error not OF error if out of range)
	BTST		#0,d0				* test low bit of longword
	BNE		LAB_ADER			* if address is odd do address error/warm start

	MOVEA.l	(sp),a0			* copy return address
	MOVE.l	d0,(sp)			* even address on stack
	JMP		(a0)				* effectively RTS


*************************************************************************************
*
* perform PEEK()

LAB_PEEK
	BSR		LAB_EVIR			* evaluate integer expression
							* (does FC error not OF error if out of range)
	MOVEA.l	d0,a0				* copy to address register
	MOVE.b	(a0),d0			* get byte
	BRA		LAB_1FD0			* convert d0 to unsigned byte in FAC1 & return


*************************************************************************************
*
* perform POKE

LAB_POKE
	BSR.s		LAB_GADB			* get two parameters for POKE or WAIT
							* first parameter in a0, second in d0
	MOVE.b	d0,(a0)			* put byte in memory
	RTS


*************************************************************************************
*
* perform DEEK()

LAB_DEEK
	BSR		LAB_EVIR			* evaluate integer expression
							* (does FC error not OF error if out of range)
	LSR.b		#1,d0				* shift bit 0 to carry
	BCS		LAB_ADER			* if address is odd do address error/warm start

	ADD.b		d0,d0				* shift byte back
	EXG		d0,a0				* copy to address register
	MOVEQ		#0,d0				* clear top bits
	MOVE.w	(a0),d0			* get word
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & return


*************************************************************************************
*
* perform LEEK()

LAB_LEEK
	BSR		LAB_EVIR			* evaluate integer expression
							* (does FC error not OF error if out of range)
	LSR.b		#1,d0				* shift bit 0 to carry
	BCS		LAB_ADER			* if address is odd do address error/warm start

	ADD.b		d0,d0				* shift byte back
	EXG		d0,a0				* copy to address register
	MOVE.l	(a0),d0			* get longword
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & return


*************************************************************************************
*
* perform DOKE

LAB_DOKE
	BSR.s		LAB_GADW			* get two parameters for DOKE or WAIT
							* first parameter in a0, second in d0
	MOVE.w	d0,(a0)			* put word in memory
	RTS


*************************************************************************************
*
* perform LOKE

LAB_LOKE
	BSR.s		LAB_GEAD			* get even address for word/long memory actions
							* address returned in d0 and on the stack
	BSR		LAB_1C01			* scan for ",", else do syntax error/warm start
	BSR		LAB_EVNM			* evaluate expression & check is numeric,
							* else do type mismatch
	BSR		LAB_EVIR			* evaluate integer value (no sign check)
	MOVEA.l	(sp)+,a0			* pull address
	MOVE.l	d0,(a0)			* put longword in memory
RTS_015
	RTS


*************************************************************************************
*
* perform SWAP

LAB_SWAP
	BSR		LAB_GVAR			* get variable 1 address in a0
	MOVE.l	a0,-(sp)			* save variable 1 address
	MOVE.b	Dtypef(a3),d4		* copy variable 1 data type, $80=string,
							* $40=inetger, $00=float

	BSR		LAB_1C01			* scan for ",", else do syntax error/warm start
	BSR		LAB_GVAR			* get variable 2 address in a0
	MOVEA.l	(sp)+,a2			* restore variable 1 address
	CMP.b		Dtypef(a3),d4		* compare variable 1 data type with variable 2
							* data type
	BNE		LAB_TMER			* if not both the same type do "Type mismatch"
							* error then warm start

* if you do want a non existant variable to return an error then leave the novar
* value at the top of this file set to zero

 ifeq	novar

	MOVE.l	(a0),d0			* get variable 2
	MOVE.l	(a2),(a0)+			* copy variable 1 to variable 2
	MOVE.l	d0,(a2)+			* save variable 2 to variable 1

	TST.b		d4				* check data type
	BPL.s		RTS_015			* exit if not string

	MOVE.w	(a0),d0			* get string 2 length
	MOVE.w	(a2),(a0)			* copy string 1 length to string 2 length
	MOVE.w	d0,(a2)			* save string 2 length to string 1 length

 endc


* if you want a non existant variable to return a null value then set the novar
* value at the top of this file to some non zero value

 ifne	novar

	MOVE.l	a2,d2				* copy the variable 1 pointer
	MOVE.l	d2,d3				* and again for any length
	BEQ.s		no_variable1		* if variable 1 doesn't exist skip the
							* value get

	MOVE.l	(a2),d2			* get variable 1 value
	TST.b		d4				* check the data type
	BPL.s		no_variable1		* if not string skip the length get

	MOVE.w	4(a2),d3			* else get variable 1 string length
no_variable1
	MOVE.l	a0,d0				* copy the variable 2 pointer
	MOVE.l	d0,d1				* and again for any length
	BEQ.s		no_variable2		* if variable 2 doesn't exist skip the
							* value get and the new value save

	MOVE.l	(a0),d0			* get variable 2 value
	MOVE.l	d2,(a0)+			* save variable 2 new value
	TST.b		d4				* check the data type
	BPL.s		no_variable2		* if not string skip the length get and
							* new length save

	MOVE.w	(a0),d1			* else get variable 2 string length
	MOVE.w	d3,(a0)			* save variable 2 new string length
no_variable2
	TST.l		d2				* test if variable 1 exists
	BEQ.s		EXIT_SWAP			* if variable 1 doesn't exist skip the
							* new value save

	MOVE.l	d0,(a2)+			* save variable 1 new value
	TST.b		d4				* check the data type
	BPL.s		EXIT_SWAP			* if not string skip the new length save

	MOVE.w	d1,(a2)			* save variable 1 new string length
EXIT_SWAP

 endc

	RTS


*************************************************************************************
*
* perform USR

LAB_USR
	JSR		Usrjmp(a3)			* do user vector
	BRA		LAB_1BFB			* scan for ")", else do syntax error/warm start


*************************************************************************************
*
* perform LOAD

LAB_LOAD
	JMP		V_LOAD(a3)			* do load vector


*************************************************************************************
*
* perform SAVE

LAB_SAVE
	JMP		V_SAVE(a3)			* do save vector


*************************************************************************************
*
* perform CALL

LAB_CALL
	PEA		LAB_GBYT(pc)		* put return address on stack
	BSR		LAB_GEAD			* get even address for word/long memory actions
							* address returned in d0 and on the stack
	RTS						* effectively calls the routine

* if the called routine exits correctly then it will return via the get byte routine.
* this will then get the next byte for the interpreter and return


*************************************************************************************
*
* perform WAIT

LAB_WAIT
	BSR		LAB_GADB			* get two parameters for POKE or WAIT
							* first parameter in a0, second in d0
	MOVE.l	a0,-(sp)			* save address
	MOVE.w	d0,-(sp)			* save byte
	MOVEQ		#0,d2				* clear mask
	BSR		LAB_GBYT			* scan memory
	BEQ.s		LAB_2441			* skip if no third argument

	BSR		LAB_SCGB			* scan for "," & get byte,
							* else do syntax error/warm start
	MOVE.l	d0,d2				* copy mask
LAB_2441
	MOVE.w	(sp)+,d1			* get byte
	MOVEA.l	(sp)+,a0			* get address
LAB_2445
	MOVE.b	(a0),d0			* read memory byte
	EOR.b		d2,d0				* EOR with second argument (mask)
	AND.b		d1,d0				* AND with first argument (byte)
	BEQ.s		LAB_2445			* loop if result is zero

	RTS


*************************************************************************************
*
* perform subtraction, FAC1 from FAC2

LAB_SUBTRACT
	EORI.b	#$80,FAC1_s(a3)		* complement FAC1 sign
	MOVE.b	FAC2_s(a3),FAC_sc(a3)	* copy FAC2 sign byte

	MOVE.b	FAC1_s(a3),d0		* get FAC1 sign byte
	EOR.b		d0,FAC_sc(a3)		* EOR with FAC2 sign


*************************************************************************************
*
* add FAC2 to FAC1

LAB_ADD
	MOVE.b	FAC1_e(a3),d0		* get exponent
	BEQ		LAB_279B			* FAC1 was zero so copy FAC2 to FAC1 & return

							* FAC1 is non zero
	LEA		FAC2_m(a3),a0		* set pointer1 to FAC2 mantissa
	MOVE.b	FAC2_e(a3),d0		* get FAC2 exponent
	BEQ.s		RTS_016			* exit if zero

	SUB.b		FAC1_e(a3),d0		* subtract FAC1 exponent
	BEQ.s		LAB_24A8			* branch if = (go add mantissa)

	BCS.s		LAB_249C			* branch if FAC2 < FAC1

							* FAC2 > FAC1
	MOVE.w	FAC2_e(a3),FAC1_e(a3)	* copy sign and exponent of FAC2
	NEG.b		d0				* negate exponent difference (make diff -ve)
	SUBQ.w	#8,a0				* pointer1 to FAC1

LAB_249C
	NEG.b		d0				* negate exponent difference (make diff +ve)
	MOVE.l	d1,-(sp)			* save d1
	CMP.b		#32,d0			* compare exponent diff with 32
	BLT.s		LAB_2467			* branch if range >= 32

	MOVEQ		#0,d1				* clear d1
	BRA.s		LAB_2468			* go clear smaller mantissa

LAB_2467
	MOVE.l	(a0),d1			* get FACx mantissa
	LSR.l		d0,d1				* shift d0 times right
LAB_2468
	MOVE.l	d1,(a0)			* save it back
	MOVE.l	(sp)+,d1			* restore d1

							* exponents are equal now do mantissa add or
							* subtract
LAB_24A8
	TST.b		FAC_sc(a3)			* test sign compare (FAC1 EOR FAC2)
	BMI.s		LAB_24F8			* if <> go do subtract

	MOVE.l	FAC2_m(a3),d0		* get FAC2 mantissa
	ADD.l		FAC1_m(a3),d0		* add FAC1 mantissa
	BCC.s		LAB_24F7			* save and exit if no carry (FAC1 is normal)

	ROXR.l	#1,d0				* else shift carry back into mantissa
	ADDQ.b	#1,FAC1_e(a3)		* increment FAC1 exponent
	BCS		LAB_OFER			* if carry do overflow error & warm start

LAB_24F7
	MOVE.l	d0,FAC1_m(a3)		* save mantissa
RTS_016
	RTS
							* signs are different
LAB_24F8
	LEA		FAC1_m(a3),a1		* pointer 2 to FAC1
	CMPA.l	a0,a1				* compare pointers
	BNE.s		LAB_24B4			* branch if <>

	ADDQ.w	#8,a1				* else pointer2 to FAC2

							* take smaller from bigger (take sign of bigger)
LAB_24B4
	MOVE.l	(a1),d0			* get larger mantissa
	MOVE.l	(a0),d1			* get smaller mantissa
	MOVE.l	d0,FAC1_m(a3)		* save larger mantissa
	SUB.l		d1,FAC1_m(a3)		* subtract smaller


*************************************************************************************
*
* do +/- (carry is sign) & normalise FAC1

LAB_24D0
	BCC.s		LAB_24D5			* branch if result is +ve

							* erk! subtract is the wrong way round so
							* negate everything
	EORI.b	#$FF,FAC1_s(a3)		* complement FAC1 sign
	NEG.l		FAC1_m(a3)			* negate FAC1 mantissa


*************************************************************************************
*
* normalise FAC1

LAB_24D5
	MOVE.l	FAC1_m(a3),d0		* get mantissa
	BMI.s		LAB_24DA			* mantissa is normal so just exit

	BNE.s		LAB_24D9			* mantissa is not zero so go normalise FAC1

	MOVE.w	d0,FAC1_e(a3)		* else make FAC1 = +zero
	RTS

LAB_24D9
	MOVE.l	d1,-(sp)			* save d1
	MOVE.l	d0,d1				* mantissa to d1
	MOVEQ		#0,d0				* clear d0
	MOVE.b	FAC1_e(a3),d0		* get exponent byte
	BEQ.s		LAB_24D8			* if exponent is zero then clean up and exit
LAB_24D6
	ADD.l		d1,d1				* shift mantissa, ADD is quicker for a single
							* shift
	DBMI		d0,LAB_24D6			* decrement exponent and loop if mantissa and
							* exponent +ve

	TST.w		d0				* test exponent
	BEQ.s		LAB_24D8			* if exponent is zero make FAC1 zero

	BPL.s		LAB_24D7			* if exponent is >zero go save FAC1

	MOVEQ		#1,d0				* else set for zero after correction
LAB_24D7
	SUBQ.b	#1,d0				* adjust exponent for loop
	MOVE.l	d1,FAC1_m(a3)		* save normalised mantissa
LAB_24D8
	MOVE.l	(sp)+,d1			* restore d1
	MOVE.b	d0,FAC1_e(a3)		* save corrected exponent
LAB_24DA
	RTS


*************************************************************************************
*
* perform LOG()

LAB_LOG
	TST.b		FAC1_s(a3)			* test sign
	BMI		LAB_FCER			* if -ve do function call error/warm start

	MOVEQ		#0,d7				* clear d7
	MOVE.b	d7,FAC_sc(a3)		* clear sign compare
	MOVE.b	FAC1_e(a3),d7		* get exponent
	BEQ		LAB_FCER			* if 0 do function call error/warm start

	SUB.l		#$81,d7			* normalise exponent
	MOVE.b	#$81,FAC1_e(a3)		* force a value between 1 and 2
	MOVE.l	FAC1_m(a3),d6		* copy mantissa

	MOVE.l	#$80000000,FAC2_m(a3)	* set mantissa for 1
	MOVE.w	#$8100,FAC2_e(a3)		* set exponent for 1
	BSR		LAB_ADD			* find arg+1
	MOVEQ		#0,d0				* setup for calc skip
	MOVE.w	d0,FAC2_e(a3)		* set FAC1 for zero result
	ADD.l		d6,d6				* shift 1 bit out
	MOVE.l	d6,FAC2_m(a3)		* put back FAC2
	BEQ.s		LAB_LONN			* if 0 skip calculation

	MOVE.w	#$8000,FAC2_e(a3)		* set exponent for .5
	BSR		LAB_DIVIDE			* do (arg-1)/(arg+1)
	TST.b		FAC1_e(a3)			* test exponent
	BEQ.s		LAB_LONN			* if 0 skip calculation

	MOVE.b	FAC1_e(a3),d1		* get exponent
	SUB.b		#$82,d1			* normalise and two integer bits
	NEG.b		d1				* negate for shift
**	CMP.b		#$1F,d1			* will mantissa vanish?
**	BGT.s		LAB_dunno			* if so do ???

	MOVE.l	FAC1_m(a3),d0		* get mantissa
	LSR.l		d1,d0				* shift in two integer bits

* d0 = arg
* d0 = x, d1 = y
* d2 = x1, d3 = y1
* d4 = shift count
* d5 = loop count
* d6 = z
* a0 = table pointer

	MOVEQ		#0,d6				* z = 0
	MOVE.l	#1<<30,d1			* y = 1
	LEA		TAB_HTHET(pc),a0		* get pointer to hyperbolic tangent table
	MOVEQ		#30,d5			* loop 31 times
	MOVEQ		#1,d4				* set shift count
	BRA.s		LAB_LOCC			* entry point for loop

LAB_LAAD
	ASR.l		d4,d2				* x1 >> i
	SUB.l		d2,d1				* y = y - x1
	ADD.l		(a0),d6			* z = z + tanh(i)
LAB_LOCC
	MOVE.l	d0,d2				* x1 = x
	MOVE.l	d1,d3				* y1 = Y
	ASR.l		d4,d3				* y1 >> i
	BCC.s		LAB_LOLP

	ADDQ.l	#1,d3
LAB_LOLP
	SUB.l		d3,d0				* x = x - y1
	BPL.s		LAB_LAAD			* branch if > 0

	MOVE.l	d2,d0				* get x back
	ADDQ.w	#4,a0				* next entry
	ADDQ.l	#1,d4				* next i
	LSR.l		#1,d3				* /2
	BEQ.s		LAB_LOCX			* branch y1 = 0

	DBF		d5,LAB_LOLP			* decrement and loop if not done

							* now sort out the result
LAB_LOCX
	ADD.l		d6,d6				* *2
	MOVE.l	d6,d0				* setup for d7 = 0
LAB_LONN
	MOVE.l	d0,d4				* save cordic result
	MOVEQ		#0,d5				* set default exponent sign
	TST.l		d7				* check original exponent sign
	BEQ.s		LAB_LOXO			* branch if original was 0

	BPL.s		LAB_LOXP			* branch if was +ve

	NEG.l		d7				* make original exponent +ve
	MOVEQ		#$80-$100,d5		* make sign -ve
LAB_LOXP
	MOVE.b	d5,FAC1_s(a3)		* save original exponent sign
	SWAP		d7				* 16 bit shift
	LSL.l		#8,d7				* easy first part
	MOVEQ		#$88-$100,d5		* start with byte
LAB_LONE
	SUBQ.l	#1,d5				* decrement exponent
	ADD.l		d7,d7				* shift mantissa
	BPL.s		LAB_LONE			* loop if not normal

LAB_LOXO
	MOVE.l	d7,FAC1_m(a3)		* save original exponent as mantissa
	MOVE.b	d5,FAC1_e(a3)		* save exponent for this
	MOVE.l	#$B17217F8,FAC2_m(a3)	* LOG(2) mantissa
	MOVE.w	#$8000,FAC2_e(a3)		* LOG(2) exponent & sign
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* make sign compare = FAC1 sign
	BSR.s		LAB_MULTIPLY		* do multiply
	MOVE.l	d4,FAC2_m(a3)		* save cordic result
	BEQ.s		LAB_LOWZ			* branch if zero

	MOVE.w	#$8200,FAC2_e(a3)		* set exponent & sign
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* clear sign compare
	BSR		LAB_ADD			* and add for final result

LAB_LOWZ
	RTS


*************************************************************************************
*
* multiply FAC1 by FAC2

LAB_MULTIPLY
	MOVEM.l	d0-d4,-(sp)			* save registers
	TST.b		FAC1_e(a3)			* test FAC1 exponent
	BEQ.s		LAB_MUUF			* if exponent zero go make result zero

	MOVE.b	FAC2_e(a3),d0		* get FAC2 exponent
	BEQ.s		LAB_MUUF			* if exponent zero go make result zero

	MOVE.b	FAC_sc(a3),FAC1_s(a3)	* sign compare becomes sign

	ADD.b		FAC1_e(a3),d0		* multiply exponents by adding
	BCC.s		LAB_MNOC			* branch if no carry

	SUB.b		#$80,d0			* normalise result
	BCC		LAB_OFER			* if no carry do overflow

	BRA.s		LAB_MADD			* branch

							* no carry for exponent add
LAB_MNOC
	SUB.b		#$80,d0			* normalise result
	BCS.s		LAB_MUUF			* return zero if underflow

LAB_MADD
	MOVE.b	d0,FAC1_e(a3)		* save exponent

							* d1 (FAC1) x d2 (FAC2)
	MOVE.l	FAC1_m(a3),d1		* get FAC1 mantissa
	MOVE.l	FAC2_m(a3),d2		* get FAC2 mantissa

	MOVE.w	d1,d4				* copy low word FAC1
	MOVE.l	d1,d0				* copy long word FAC1
	SWAP		d0				* high word FAC1 to low word FAC1
	MOVE.w	d0,d3				* copy high word FAC1

	MULU		d2,d1				* low word FAC2 x low word FAC1
	MULU		d2,d0				* low word FAC2 x high word FAC1
	SWAP		d2				* high word FAC2 to low word FAC2
	MULU		d2,d4				* high word FAC2 x low word FAC1
	MULU		d2,d3				* high word FAC2 x high word FAC1

* done multiply, now add partial products

*			d1 =					aaaa  ----	FAC2_L x FAC1_L
*			d0 =				bbbb  aaaa		FAC2_L x FAC1_H
*			d4 =				bbbb  aaaa		FAC2_H x FAC1_L
*			d3 =			cccc  bbbb			FAC2_H x FAC1_H
*			product =		mmmm  mmmm

	ADD.L		#$8000,d1			* round up lowest word
	CLR.w		d1				* clear low word, don't need it
	SWAP		d1				* align high word
	ADD.l		d0,d1				* add FAC2_L x FAC1_H (can't be carry)
LAB_MUF1
	ADD.l		d4,d1				* now add intermediate (FAC2_H x FAC1_L)
	BCC.s		LAB_MUF2			* branch if no carry

	ADD.l		#$10000,d3			* else correct result
LAB_MUF2
	ADD.l		#$8000,d1			* round up low word
	CLR.w		d1				* clear low word
	SWAP		d1				* align for final add
	ADD.l		d3,d1				* add FAC2_H x FAC1_H, result
	BMI.s		LAB_MUF3			* branch if normalisation not needed

	ADD.l		d1,d1				* shift mantissa
	SUBQ.b	#1,FAC1_e(a3)		* adjust exponent
	BEQ.s		LAB_MUUF			* branch if underflow

LAB_MUF3
	MOVE.l	d1,FAC1_m(a3)		* save mantissa
LAB_MUEX
	MOVEM.l	(sp)+,d0-d4			* restore registers
	RTS
							* either zero or underflow result
LAB_MUUF
	MOVEQ		#0,d0				* quick clear
	MOVE.l	d0,FAC1_m(a3)		* clear mantissa
	MOVE.w	d0,FAC1_e(a3)		* clear sign and exponent
	BRA.s		LAB_MUEX			* restore regs & exit


*************************************************************************************
*
* do FAC2/FAC1, result in FAC1
* fast hardware divide version

LAB_DIVIDE
	MOVE.l	d7,-(sp)			* save d7
	MOVEQ		#0,d0				* clear FAC2 exponent
	MOVE.l	d0,d2				* clear FAC1 exponent

	MOVE.b	FAC1_e(a3),d2		* get FAC1 exponent
	BEQ		LAB_DZER			* if zero go do /0 error

	MOVE.b	FAC2_e(a3),d0		* get FAC2 exponent
	BEQ.s		LAB_DIV0			* if zero return zero

	SUB.w		d2,d0				* get result exponent by subtracting
	ADD.w		#$80,d0			* correct 16 bit exponent result

	MOVE.b	FAC_sc(a3),FAC1_s(a3)	* sign compare is result sign

* now to do 32/32 bit mantissa divide

	CLR.b		flag(a3)			* clear 'flag' byte
	MOVE.l	FAC1_m(a3),d3		* get FAC1 mantissa
	MOVE.l	FAC2_m(a3),d4		* get FAC2 mantissa
	CMP.l		d3,d4				* compare FAC2 with FAC1 mantissa
	BEQ.s		LAB_MAN1			* set mantissa result = 1 if equal

	BCS.s		AC1gtAC2			* branch if FAC1 > FAC2

	SUB.l		d3,d4				* subtract FAC1 from FAC2, result now must be <1
	ADDQ.b	#3,flag(a3)			* FAC2>FAC1 so set 'flag' byte
AC1gtAC2
	BSR.s		LAB_32_16			* do 32/16 divide
	SWAP		d1				* move 16 bit result to high word
	MOVE.l	d2,d4				* copy remainder longword
	BSR.s		LAB_3216			* do 32/16 divide again (skip copy d4 to d2)
	DIVU.w	d5,d2				* now divide remainder to make guard word
	MOVE.b	flag(a3),d7			* now normalise, get flag byte back
	BEQ.s		LAB_DIVX			* skip add if null

* else result was >1 so we need to add 1 to result mantissa and adjust exponent

	LSR.b		#1,d7				* shift 1 into eXtend
	ROXR.l	#1,d1				* shift extend result >>
	ROXR.w	#1,d2				* shift extend guard word >>
	ADDQ.b	#1,d0				* adjust exponent

* now round result to 32 bits

LAB_DIVX
	ADD.w		d2,d2				* guard bit into eXtend bit
	BCC.s		L_DIVRND			* branch if guard=0

	ADDQ.l	#1,d1				* add guard to mantissa
	BCC.s		L_DIVRND			* branch if no overflow

LAB_SET1
	ROXR.l	#1,d1				* shift extend result >>
	ADDQ.w	#1,d0				* adjust exponent

							* test for over/under flow
L_DIVRND
	MOVE.w	d0,d3				* copy exponent
	BMI.s		LAB_DIV0			* if -ve return zero

	ANDI.w	#$FF00,d3			* mask word high byte
	BNE		LAB_OFER			* branch if overflow

							* move result into FAC1
LAB_XDIV
	MOVE.l	(sp)+,d7			* restore d7
	MOVE.b	d0,FAC1_e(a3)		* save result exponent
	MOVE.l	d1,FAC1_m(a3)		* save result mantissa
	RTS

* FAC1 mantissa = FAC2 mantissa so set result mantissa

LAB_MAN1
	MOVEQ		#1,d1				* set bit
	LSR.l		d1,d1				* bit into eXtend
	BRA.s		LAB_SET1			* set mantissa, adjust exponent and exit

* result is zero

LAB_DIV0
	MOVEQ		#0,d0				* zero exponent & sign
	MOVE.l	d0,d1				* zero mantissa
	BRA		LAB_XDIV			* exit divide

* divide 16 bits into 32, AB/Ex
*
* d4			AAAA	BBBB			* 32 bit numerator
* d3			EEEE	xxxx			* 16 bit denominator
*
* returns -
*
* d1			xxxx	DDDD			* 16 bit result
* d2				HHHH	IIII		* 32 bit remainder

LAB_32_16
	MOVE.l	d4,d2				* copy FAC2 mantissa		(AB)
LAB_3216
	MOVE.l	d3,d5				* copy FAC1 mantissa		(EF)
	CLR.w		d5				* clear low word d1		(Ex)
	SWAP		d5				* swap high word to low word	(xE)

* d3			EEEE	FFFF			* denominator copy
* d5		0000	EEEE				* denominator high word
* d2			AAAA	BBBB			* numerator copy
* d4			AAAA	BBBB			* numerator

	DIVU.w	d5,d4				* do FAC2/FAC1 high word	(AB/E)
	BVC.s		LAB_LT_1			* if no overflow DIV was ok

	MOVEQ		#-1,d4			* else set default value

* done the divide, now check the result, we have ...

* d3			EEEE	FFFF			* denominator copy
* d5		0000	EEEE				* denominator high word
* d2			AAAA	BBBB			* numerator copy
* d4			MMMM	DDDD			* result MOD and DIV

LAB_LT_1
	MOVE.w	d4,d6				* copy 16 bit result
	MOVE.w	d4,d1				* copy 16 bit result again

* we now have ..
* d3			EEEE	FFFF			* denominator copy
* d5		0000	EEEE				* denominator high word
* d6			xxxx  DDDD			* result DIV copy
* d1			xxxx  DDDD			* result DIV copy
* d2			AAAA	BBBB			* numerator copy
* d4			MMMM	DDDD			* result MOD and DIV

* now multiply out 32 bit denominator by 16 bit result
* QRS = AB*D

	MULU.w	d3,d6				* FFFF * DDDD =       rrrr  SSSS
	MULU.w	d5,d4				* EEEE * DDDD = QQQQ  rrrr

* we now have ..
* d3			EEEE	FFFF			* denominator copy
* d5		0000	EEEE				* denominator high word
* d6				rrrr  SSSS		* 48 bit result partial low
* d1			xxxx  DDDD			* result DIV copy
* d2			AAAA	BBBB			* numerator copy
* d4			QQQQ	rrrr			* 48 bit result partial

	MOVE.w	d6,d7				* copy low word of low multiply

* d7				xxxx	SSSS		* 48 bit result partial low

	CLR.w		d6				* clear low word of low multiply
	SWAP		d6				* high word of low multiply to low word

* d6			0000	rrrr			* high word of 48 bit result partial low

	ADD.l		d6,d4

* d4			QQQQ	RRRR			* 48 bit result partial high longword

	MOVEQ		#0,d6				* clear to extend numerator to 48 bits

* now do GHI = AB0 - QRS (which is the remainder)

	SUB.w		d7,d6				* low word subtract

* d6				xxxx	IIII		* remainder low word

	SUBX.l	d4,d2				* high longword subtract

* d2			GGGG	HHHH			* remainder high longword

* now if we got the divide correct then the remainder high longword will be +ve

	BPL.s		L_DDIV			* branch if result is ok (<needed)

* remainder was -ve so DDDD is too big

LAB_REMM
	SUBQ.w	#1,d1				* adjust DDDD

* d3				xxxx	FFFF		* denominator copy
* d6				xxxx	IIII		* remainder low word

	ADD.w		d3,d6				* add EF*1 low remainder low word

* d5			0000	EEEE			* denominator high word
* d2			GGGG	HHHH			* remainder high longword

	ADDX.l	d5,d2				* add extend EF*1 to remainder high longword
	BMI.s		LAB_REMM			* loop if result still too big

* all done and result correct or <

L_DDIV
	SWAP		d2				* remainder mid word to high word

* d2			HHHH	GGGG			* (high word /should/ be $0000)

	MOVE.w	d6,d2				* remainder in high word

* d2				HHHH	IIII		* now is 32 bit remainder
* d1			xxxx	DDDD			* 16 bit result

	RTS


*************************************************************************************
*
* unpack memory (a0) into FAC1

LAB_UFAC
	MOVE.l	(a0),d0			* get packed value
	SWAP		d0				* exponent and sign into least significant word
	MOVE.w	d0,FAC1_e(a3)		* save exponent and sign
	BEQ.s		LAB_NB1T			* branch if exponent (and the rest) zero

	OR.w		#$80,d0			* set MSb
	SWAP		d0				* word order back to normal
	ASL.l		#8,d0				* shift exponent & clear guard byte
LAB_NB1T
	MOVE.l	d0,FAC1_m(a3)		* move into FAC1

	MOVE.b	FAC1_e(a3),d0		* get FAC1 exponent
	RTS


*************************************************************************************
*
* set numeric variable, pack FAC1 into Lvarpl

LAB_PFAC
	MOVE.l	a0,-(sp)			* save pointer
	MOVEA.l	Lvarpl(a3),a0		* get destination pointer
	BTST		#6,Dtypef(a3)		* test data type
	BEQ.s		LAB_277C			* branch if floating

	BSR		LAB_2831			* convert FAC1 floating to fixed
							* result in d0 and Itemp
	MOVE.l	d0,(a0)			* save in var
	MOVE.l	(sp)+,a0			* restore pointer
	RTS


*************************************************************************************
*
* normalise round and pack FAC1 into (a0)

LAB_2778
	MOVE.l	a0,-(sp)			* save pointer
LAB_277C
	BSR		LAB_24D5			* normalise FAC1
	BSR.s		LAB_27BA			* round FAC1
	MOVE.l	FAC1_m(a3),d0		* get FAC1 mantissa
	ROR.l		#8,d0				* align 24/32 bit mantissa
	SWAP		d0				* exponent/sign into 0-15
	AND.w		#$7F,d0			* clear exponent and sign bit
	ANDI.b	#$80,FAC1_s(a3)		* clear non sign bits in sign
	OR.w		FAC1_e(a3),d0		* OR in exponent and sign
	SWAP		d0				* move exponent and sign back to 16-31
	MOVE.l	d0,(a0)			* store in destination
	MOVE.l	(sp)+,a0			* restore pointer
	RTS


*************************************************************************************
*
* copy FAC2 to FAC1

LAB_279B
	MOVE.w	FAC2_e(a3),FAC1_e(a3)	* copy exponent & sign
	MOVE.l	FAC2_m(a3),FAC1_m(a3)	* copy mantissa
	RTS


*************************************************************************************
*
* round FAC1

LAB_27BA
	MOVE.b	FAC1_e(a3),d0		* get FAC1 exponent
	BEQ.s		LAB_27C4			* branch if zero

	MOVE.l	FAC1_m(a3),d0		* get FAC1
	ADD.l		#$80,d0			* round to 24 bit
	BCC.s		LAB_27C3			* branch if no overflow

	ROXR.l	#1,d0				* shift FAC1 mantissa
	ADDQ.b	#1,FAC1_e(a3)		* correct exponent
	BCS		LAB_OFER			* if carry do overflow error & warm start

LAB_27C3
	AND.b		#$00,d0			* clear guard byte
	MOVE.l	d0,FAC1_m(a3)		* save back to FAC1
	RTS

LAB_27C4
	MOVE.b	d0,FAC1_s(a3)		* make zero always +ve
RTS_017
	RTS


*************************************************************************************
*
* get FAC1 sign
* return d0=-1,C=1/-ve d0=+1,C=0/+ve

LAB_27CA
	MOVEQ		#0,d0				* clear d0
	MOVE.b	FAC1_e(a3),d0		* get FAC1 exponent
	BEQ.s		RTS_017			* exit if zero (already correct SGN(0)=0)


*************************************************************************************
*
* return d0=-1,C=1/-ve d0=+1,C=0/+ve
* no = 0 check

LAB_27CE
	MOVE.b	FAC1_s(a3),d0		* else get FAC1 sign (b7)


*************************************************************************************
*
* return d0=-1,C=1/-ve d0=+1,C=0/+ve
* no = 0 check, sign in d0

LAB_27D0
	EXT.w		d0				* make word
	EXT.l		d0				* make longword
	ASR.l		#8,d0				* move sign bit through byte to carry
	BCS.s		RTS_017			* exit if carry set

	MOVEQ		#1,d0				* set result for +ve sign
	RTS


*************************************************************************************
*
* perform SGN()

LAB_SGN
	BSR.s		LAB_27CA			* get FAC1 sign
							* return d0=-1/-ve d0=+1/+ve


*************************************************************************************
*
* save d0 as integer longword

LAB_27DB
	MOVE.l	d0,FAC1_m(a3)		* save FAC1 mantissa
	MOVE.w	#$A000,FAC1_e(a3)		* set FAC1 exponent & sign
	ADD.l		d0,d0				* top bit into carry
	BRA		LAB_24D0			* do +/- (carry is sign) & normalise FAC1


*************************************************************************************
*
* perform ABS()

LAB_ABS
	MOVE.b	#0,FAC1_s(a3)		* clear FAC1 sign
	RTS


*************************************************************************************
*
* compare FAC1 with FAC2
* returns d0=+1 Cb=0 if FAC1 > FAC2
* returns d0= 0 Cb=0 if FAC1 = FAC2
* returns d0=-1 Cb=1 if FAC1 < FAC2

LAB_27FA
	MOVE.b	FAC2_e(a3),d1		* get FAC2 exponent
	BEQ.s		LAB_27CA			* branch if FAC2 exponent=0 & get FAC1 sign
							* d0=-1,C=1/-ve d0=+1,C=0/+ve

	MOVE.b	FAC_sc(a3),d0		* get FAC sign compare
	BMI.s		LAB_27CE			* if signs <> do return d0=-1,C=1/-ve
							* d0=+1,C=0/+ve & return

	MOVE.b	FAC1_s(a3),d0		* get FAC1 sign
	CMP.b		FAC1_e(a3),d1		* compare FAC1 exponent with FAC2 exponent
	BNE.s		LAB_2828			* branch if different

	MOVE.l	FAC2_m(a3),d1		* get FAC2 mantissa
	CMP.l		FAC1_m(a3),d1		* compare mantissas
	BEQ.s		LAB_282F			* exit if mantissas equal

* gets here if number <> FAC1

LAB_2828
	BCS.s		LAB_27D0			* if FAC1 > FAC2 return d0=-1,C=1/-ve d0=+1,
							* C=0/+ve

	EORI.b	#$80,d0			* else toggle FAC1 sign
LAB_282E
	BRA.s		LAB_27D0			* return d0=-1,C=1/-ve d0=+1,C=0/+ve

LAB_282F
	MOVEQ		#0,d0				* clear result
	RTS


*************************************************************************************
*
* convert FAC1 floating to fixed
* result in d0 and Itemp, sets flags correctly

LAB_2831
	MOVE.l	FAC1_m(a3),d0		* copy mantissa
	BEQ.s		LAB_284J			* branch if mantissa = 0

	MOVE.l	d1,-(sp)			* save d1
	MOVEQ		#$A0,d1			* set for no floating bits
	SUB.b		FAC1_e(a3),d1		* subtract FAC1 exponent
	BCS		LAB_OFER			* do overflow if too big

	BNE.s		LAB_284G			* branch if exponent was not $A0

	TST.b		FAC1_s(a3)			* test FAC1 sign
	BPL.s		LAB_284H			* branch if FAC1 +ve

	NEG.l		d0
	BVS.s		LAB_284H			* branch if was $80000000

	BRA		LAB_OFER			* do overflow if too big

LAB_284G
	CMP.b		#$20,d1			* compare with minimum result for integer
	BCS.s		LAB_284L			* if < minimum just do shift

	MOVEQ		#0,d0				* else return zero
LAB_284L
	LSR.l		d1,d0				* shift integer

	TST.b		FAC1_s(a3)			* test FAC1 sign (b7)
	BPL.s		LAB_284H			* branch if FAC1 +ve

	NEG.l		d0				* negate integer value
LAB_284H
	MOVE.l	(sp)+,d1			* restore d1
LAB_284J
	MOVE.l	d0,Itemp(a3)		* save result to Itemp
	RTS


*************************************************************************************
*
* perform INT()

LAB_INT
	MOVEQ		#$A0,d0			* set for no floating bits
	SUB.b		FAC1_e(a3),d0		* subtract FAC1 exponent
	BLS.s		LAB_IRTS			* exit if exponent >= $A0
							* (too big for fraction part!)

	CMP.b		#$20,d0			* compare with minimum result for integer
	BCC		LAB_POZE			* if >= minimum go return 0
							* (too small for integer part!)

	MOVEQ		#-1,d1			* set integer mask
	ASL.l		d0,d1				* shift mask [8+2*d0]
	AND.l		d1,FAC1_m(a3)		* mask mantissa
LAB_IRTS
	RTS


*************************************************************************************
*
* print " in line [LINE #]"

LAB_2953
	LEA		LAB_LMSG(pc),a0		* point to " in line " message
	BSR		LAB_18C3			* print null terminated string

							* Print Basic line #
	MOVE.l	Clinel(a3),d0		* get current line


*************************************************************************************
*
* print d0 as unsigned integer

LAB_295E
	LEA		Bin2dec(pc),a1		* get table address
	MOVEQ		#0,d1				* table index
	LEA		Usdss(a3),a0		* output string start
	MOVE.l	d1,d2				* output string index
LAB_2967
	MOVE.l	(a1,d1.w),d3		* get table value
	BEQ.s		LAB_2969			* exit if end marker

	MOVEQ		#'0'-1,d4			* set character to "0"-1
LAB_2968
	ADDQ.w	#1,d4				* next numeric character
	SUB.l		d3,d0				* subtract table value
	BPL.s		LAB_2968			* not overdone so loop

	ADD.l		d3,d0				* correct value
	MOVE.b	d4,(a0,d2.w)		* character out to string
	ADDQ.w	#4,d1				* increment table pointer
	ADDQ.w	#1,d2				* increment output string pointer
	BRA.s		LAB_2967			* loop

LAB_2969
	ADD.b		#'0',d0			* make last character
	MOVE.b	d0,(a0,d2.w)		* character out to string
	SUBQ.w	#1,a0				* decrement a0 (allow simple loop)

							* now find non zero start of string
LAB_296A
	ADDQ.w	#1,a0				* increment a0 (this will never carry to b16)
	LEA		BHsend-1(a3),a1		* get string end
	CMPA.l	a1,a0				* are we at end
	BEQ		LAB_18C3			* if so print null terminated string and RETURN

	CMPI.b	#'0',(a0)			* is character "0" ?
	BEQ.s		LAB_296A			* loop if so

	BRA		LAB_18C3			* print null terminated string from memory & RET


*************************************************************************************
*
* convert FAC1 to ASCII string result in (a0)
* STR$() function enters here

* now outputs 7 significant digits

* d0 is character out
* d1 is save index
* d2 is gash

* a0 is output string pointer

LAB_2970
	LEA		Decss(a3),a1		* set output string start

	MOVEQ		#' ',d2			* character = " ", assume +ve
	BCLR.b	#7,FAC1_s(a3)		* test and clear FAC1 sign (b7)
	BEQ.s		LAB_2978			* branch if +ve

	MOVEQ		#'-',d2			* else character = "-"
LAB_2978
	MOVE.b	d2,(a1)			* save the sign character
	MOVE.b	FAC1_e(a3),d2		* get FAC1 exponent
	BNE.s		LAB_2989			* branch if FAC1<>0

							* exponent was $00 so FAC1 is 0
	MOVEQ		#'0',d0			* set character = "0"
	MOVEQ		#1,d1				* set output string index
	BRA		LAB_2A89			* save last character, [EOT] & exit

							* FAC1 is some non zero value
LAB_2989
	MOVE.b	#0,numexp(a3)		* clear number exponent count
	CMP.b		#$81,d2			* compare FAC1 exponent with $81 (>1.00000)

	BCC.s		LAB_299C			* branch if FAC1=>1

							* else FAC1 < 1
	MOVE.l	#$98968000,FAC2_m(a3)	* 10000000 mantissa
	MOVE.w	#$9800,FAC2_e(a3)		* 10000000 exponent & sign
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* make FAC1 sign sign compare
	BSR		LAB_MULTIPLY		* do FAC2*FAC1

	MOVE.b	#$F9,numexp(a3)		* set number exponent count (-7)
	BRA.s		LAB_299C			* go test for fit

LAB_29B9
	MOVE.w	FAC1_e(a3),FAC2_e(a3)	* copy exponent & sign from FAC1 to FAC2
	MOVE.l	FAC1_m(a3),FAC2_m(a3)	* copy FAC1 mantissa to FAC2 mantissa
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* save FAC1_s as sign compare

	MOVE.l	#$CCCCCCCD,FAC1_m(a3)	* 1/10 mantissa
	MOVE.w	#$7D00,FAC1_e(a3)		* 1/10 exponent & sign
	BSR		LAB_MULTIPLY		* do FAC2*FAC1, effectively divide by 10 but
							* faster

	ADDQ.b	#1,numexp(a3)		* increment number exponent count
LAB_299C
	MOVE.l	#$98967F70,FAC2_m(a3)	* 9999999.4375 mantissa
	MOVE.w	#$9800,FAC2_e(a3)		* 9999999.4375 exponent & sign
							* (max before scientific notation)
	BSR		LAB_27F0			* fast compare FAC1 with FAC2
							* returns d0=+1 C=0 if FAC1 > FAC2
							* returns d0= 0 C=0 if FAC1 = FAC2
							* returns d0=-1 C=1 if FAC1 < FAC2
	BHI.s		LAB_29B9			* go do /10 if FAC1 > 9999999.4375

	BEQ.s		LAB_29C3			* branch if FAC1 = 9999999.4375

							* FAC1 < 9999999.4375
	MOVE.l	#$F423F800,FAC2_m(a3)	* set mantissa for 999999.5
	MOVE.w	#$9400,FAC2_e(a3)		* set exponent for 999999.5

	LEA		FAC1_m(a3),a0		* set pointer for x10
LAB_29A7
	BSR		LAB_27F0			* fast compare FAC1 with FAC2
							* returns d0=+1 C=0 if FAC1 > FAC2
							* returns d0= 0 C=0 if FAC1 = FAC2
							* returns d0=-1 C=1 if FAC1 < FAC2
	BHI.s		LAB_29C0			* branch if FAC1 > 99999.9375,no decimal places

							* FAC1 <= 999999.5 so do x 10
	MOVE.l	(a0),d0			* get FAC1 mantissa
	MOVE.b	4(a0),d1			* get FAC1 exponent
	MOVE.l	d0,d2				* copy it
	LSR.l		#2,d0				* /4
	ADD.l		d2,d0				* add FAC1 (x1.125)
	BCC.s		LAB_29B7			* branch if no carry

	ROXR.l	#1,d0				* shift carry back in
	ADDQ.b	#1,d1				* increment exponent (never overflows)
LAB_29B7
	ADDQ.b	#3,d1				* correct exponent ( 8 x 1.125 = 10 )
							* (never overflows)
	MOVE.l	d0,(a0)			* save new mantissa
	MOVE.b	d1,4(a0)			* save new exponent
	SUBQ.b	#1,numexp(a3)		* decrement number exponent count
	BRA.s		LAB_29A7			* go test again

							* now we have just the digits to do
LAB_29C0
	MOVE.l	#$80000000,FAC2_m(a3)	* set mantissa for 0.5
	MOVE.w	#$8000,FAC2_e(a3)		* set exponent for 0.5
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* sign compare = sign
	BSR		LAB_ADD			* add the 0.5 to FAC1 (round FAC1)

LAB_29C3
	BSR		LAB_2831			* convert FAC1 floating to fixed
							* result in d0 and Itemp
	MOVEQ		#$01,d2			* set default digits before dp = 1
	MOVE.b	numexp(a3),d0		* get number exponent count
	ADD.b		#8,d0				* allow 7 digits before point
	BMI.s		LAB_29D9			* if -ve then 1 digit before dp

	CMP.b		#$09,d0			* d0>=9 if n>=1E7
	BCC.s		LAB_29D9			* branch if >= $09

							* < $08
	SUBQ.b	#1,d0				* take 1 from digit count
	MOVE.b	d0,d2				* copy byte
	MOVEQ		#$02,d0			* set exponent adjust
LAB_29D9
	MOVEQ		#0,d1				* set output string index
	SUBQ.b	#2,d0				* -2
	MOVE.b	d0,expcnt(a3)		* save exponent adjust
	MOVE.b	d2,numexp(a3)		* save digits before dp count
	MOVE.b	d2,d0				* copy digits before dp count
	BEQ.s		LAB_29E4			* branch if no digits before dp

	BPL.s		LAB_29F7			* branch if digits before dp

LAB_29E4
	ADDQ.l	#1,d1				* increment index
	MOVE.b	#'.',(a1,d1.w)		* save to output string

	TST.b		d2				* test digits before dp count
	BEQ.s		LAB_29F7			* branch if no digits before dp

	ADDQ.l	#1,d1				* increment index
	MOVE.b	#'0',(a1,d1.w)		* save to output string
LAB_29F7
	MOVEQ		#0,d2				* clear index (point to 1,000,000)
	MOVEQ		#$80-$100,d0		* set output character
LAB_29FB
	LEA		LAB_2A9A(pc),a0		* get base of table
	MOVE.l	(a0,d2.w),d3		* get table value
LAB_29FD
	ADDQ.b	#1,d0				* increment output character
	ADD.l		d3,Itemp(a3)		* add to (now fixed) mantissa
	BTST		#7,d0				* set test sense (z flag only)
	BCS.s		LAB_2A18			* did carry so has wrapped past zero

	BEQ.s		LAB_29FD			* no wrap and +ve test so try again

	BRA.s		LAB_2A1A			* found this digit

LAB_2A18
	BNE.s		LAB_29FD			* wrap and -ve test so try again

LAB_2A1A
	BCC.s		LAB_2A21			* branch if +ve test result

	NEG.b		d0				* negate the digit number
	ADD.b		#$0B,d0			* and subtract from 11 decimal
LAB_2A21
	ADD.b		#$2F,d0			* add "0"-1 to result
	ADDQ.w	#4,d2				* increment index to next less power of ten
	ADDQ.w	#1,d1				* increment output string index
	MOVE.b	d0,d3				* copy character to d3
	AND.b		#$7F,d3			* mask out top bit
	MOVE.b	d3,(a1,d1.w)		* save to output string
	SUB.b		#1,numexp(a3)		* decrement # of characters before the dp
	BNE.s		LAB_2A3B			* branch if still characters to do

							* else output the point
	ADDQ.l	#1,d1				* increment index
	MOVE.b	#'.',(a1,d1.w)		* save to output string
LAB_2A3B
	AND.b		#$80,d0			* mask test sense bit
	EORI.b	#$80,d0			* invert it
	CMP.b		#LAB_2A9B-LAB_2A9A,d2	* compare table index with max+4
	BNE.s		LAB_29FB			* loop if not max

							* now remove trailing zeroes
LAB_2A4B
	MOVE.b	(a1,d1.w),d0		* get character from output string
	SUBQ.l	#1,d1				* decrement output string index
	CMP.b		#'0',d0			* compare with "0"
	BEQ.s		LAB_2A4B			* loop until non "0" character found

	CMP.b		#'.',d0			* compare with "."
	BEQ.s		LAB_2A58			* branch if was dp

							* else restore last character
	ADDQ.l	#1,d1				* increment output string index
LAB_2A58
	MOVE.b	#'+',2(a1,d1.w)		* save character "+" to output string
	TST.b		expcnt(a3)			* test exponent count
	BEQ.s		LAB_2A8C			* if zero go set null terminator & exit

							* exponent isn't zero so write exponent
	BPL.s		LAB_2A68			* branch if exponent count +ve

	MOVE.b	#'-',2(a1,d1.w)		* save character "-" to output string
	NEG.b		expcnt(a3)			* convert -ve to +ve
LAB_2A68
	MOVE.b	#'E',1(a1,d1.w)		* save character "E" to output string
	MOVE.b	expcnt(a3),d2		* get exponent count
	MOVEQ		#$2F,d0			* one less than "0" character
LAB_2A74
	ADDQ.b	#1,d0				* increment 10's character
	SUB.b		#$0A,d2			* subtract 10 from exponent count
	BCC.s		LAB_2A74			* loop while still >= 0

	ADD.b		#$3A,d2			* add character ":", $30+$0A, result is 10-value
	MOVE.b	d0,3(a1,d1.w)		* save 10's character to output string
	MOVE.b	d2,4(a1,d1.w)		* save 1's character to output string
	MOVE.b	#0,5(a1,d1.w)		* save null terminator after last character
	BRA.s		LAB_2A91			* go set string pointer (a0) and exit

LAB_2A89
	MOVE.b	d0,(a1,d1.w)		* save last character to output string
LAB_2A8C
	MOVE.b	#0,1(a1,d1.w)		* save null terminator after last character
LAB_2A91
	MOVEA.l	a1,a0				* set result string pointer (a0)
	RTS


*************************************************************************************
*
* fast compare FAC1 with FAC2
* assumes both are +ve and FAC2>0
* returns d0=+1 C=0 if FAC1 > FAC2
* returns d0= 0 C=0 if FAC1 = FAC2
* returns d0=-1 C=1 if FAC1 < FAC2

LAB_27F0
	MOVEQ		#0,d0				* set for FAC1 = FAC2
	MOVE.b	FAC2_e(a3),d1		* get FAC2 exponent
	CMP.b		FAC1_e(a3),d1		* compare FAC1 exponent with FAC2 exponent
	BNE.s		LAB_27F1			* branch if different

	MOVE.l	FAC2_m(a3),d1		* get FAC2 mantissa
	CMP.l		FAC1_m(a3),d1		* compare mantissas
	BEQ.s		LAB_27F3			* exit if mantissas equal

LAB_27F1
	BCS.s		LAB_27F2			* if FAC1 > FAC2 return d0=+1,C=0

	SUBQ.l	#1,d0				* else FAC1 < FAC2 return d0=-1,C=1
	RTS

LAB_27F2
	ADDQ.l	#1,d0
LAB_27F3
	RTS


*************************************************************************************
*
* make FAC1 = 1

LAB_POON
	MOVE.l	#$80000000,FAC1_m(a3)	* 1 mantissa
	MOVE.w	#$8100,FAC1_e(a3)		* 1 exonent & sign
	RTS


*************************************************************************************
*
* make FAC1 = 0

LAB_POZE
	MOVEQ		#0,d0				* clear longword
	MOVE.l	d0,FAC1_m(a3)		* 0 mantissa
	MOVE.w	d0,FAC1_e(a3)		* 0 exonent & sign
	RTS


*************************************************************************************
*
* perform power function
* the number is in FAC2, the power is in FAC1
* no longer trashes Itemp

LAB_POWER
	TST.b		FAC1_e(a3)			* test power
	BEQ.s		LAB_POON			* if zero go return 1

	TST.b		FAC2_e(a3)			* test number
	BEQ.s		LAB_POZE			* if zero go return 0

	MOVE.b	FAC2_s(a3),-(sp)		* save number sign
	BPL.s		LAB_POWP			* power of positive number

	MOVEQ		#0,d1				* clear d1
	MOVE.b	d1,FAC2_s(a3)		* make sign +ve

							* number sign was -ve and can only be raised to
							* an integer power which gives an x +j0 result,
							* else do 'function call' error
	MOVE.b	FAC1_e(a3),d1		* get power exponent
	SUB.w		#$80,d1			* normalise to .5
	BLS		LAB_FCER			* if 0<power<1 then do 'function call' error

							* now shift all the integer bits out
	MOVE.l	FAC1_m(a3),d0		* get power mantissa
	ASL.l		d1,d0				* shift mantissa
	BNE		LAB_FCER			* if power<>INT(power) then do 'function call'
							* error

	BCS.s		LAB_POWP			* if integer value odd then leave result -ve

	MOVE.b	d0,(sp)			* save result sign +ve
LAB_POWP
	MOVE.l	FAC1_m(a3),-(sp)		* save power mantissa
	MOVE.w	FAC1_e(a3),-(sp)		* save power sign & exponent

	BSR		LAB_279B			* copy number to FAC1
	BSR		LAB_LOG			* find log of number

	MOVE.w	(sp)+,d0			* get power sign & exponent
	MOVE.l	(sp)+,FAC2_m(a3)		* get power mantissa
	MOVE.w	d0,FAC2_e(a3)		* save sign & exponent to FAC2
	MOVE.b	d0,FAC_sc(a3)		* save sign as sign compare
	MOVE.b	FAC1_s(a3),d0		* get FAC1 sign
	EOR.b		d0,FAC_sc(a3)		* make sign compare (FAC1_s EOR FAC2_s)

	BSR		LAB_MULTIPLY		* multiply by power
	BSR.s		LAB_EXP			* find exponential
	MOVE.b	(sp)+,FAC1_s(a3)		* restore number sign
	RTS


*************************************************************************************
*
* do - FAC1

LAB_GTHAN
	TST.b		FAC1_e(a3)			* test for non zero FAC1
	BEQ.s		RTS_020			* branch if null

	EORI.b	#$80,FAC1_s(a3)		* (else) toggle FAC1 sign bit
RTS_020
	RTS


*************************************************************************************
*
							* return +1
LAB_EX1
	MOVE.l	#$80000000,FAC1_m(a3)	* +1 mantissa
	MOVE.w	#$8100,FAC1_e(a3)		* +1 sign & exponent
	RTS
							* do over/under flow
LAB_EXOU
	TST.b		FAC1_s(a3)			* test sign
	BPL		LAB_OFER			* was +ve so do overflow error

							* else underflow so return zero
	MOVEQ		#0,d0				* clear longword
	MOVE.l	d0,FAC1_m(a3)		* 0 mantissa
	MOVE.w	d0,FAC1_e(a3)		* 0 sign & exponent
	RTS
							* fraction was zero so do 2^n
LAB_EXOF
	MOVE.l	#$80000000,FAC1_m(a3)	* +n mantissa
	MOVE.b	#0,FAC1_s(a3)		* clear sign
	TST.b		cosout(a3)			* test sign flag
	BPL.s		LAB_EXOL			* branch if +ve

	NEG.l		d1				* else do 1/2^n
LAB_EXOL
	ADD.b		#$81,d1			* adjust exponent
	MOVE.b	d1,FAC1_e(a3)		* save exponent
	RTS

* perform EXP()	(x^e)
* valid input range is -88 to +88

LAB_EXP
	MOVE.b	FAC1_e(a3),d0		* get exponent
	BEQ.s		LAB_EX1			* return 1 for zero in

	CMP.b		#$64,d0			* compare exponent with min
	BCS.s		LAB_EX1			* if smaller just return 1

**	MOVEM.l	d1-d6/a0,-(sp)		* save the registers
	MOVE.b	#0,cosout(a3)		* flag +ve number
	MOVE.l	FAC1_m(a3),d1		* get mantissa
	CMP.b		#$87,d0			* compare exponent with max
	BHI.s		LAB_EXOU			* go do over/under flow if greater

	BNE.s		LAB_EXCM			* branch if less

							* else is 2^7
	CMP.l		#$B00F33C7,d1		* compare mantissa with n*2^7 max
	BCC.s		LAB_EXOU			* if => go over/underflow

LAB_EXCM
	TST.b		FAC1_s(a3)			* test sign
	BPL.s		LAB_EXPS			* branch if arg +ve

	MOVE.b	#$FF,cosout(a3)		* flag -ve number
	MOVE.b	#0,FAC1_s(a3)		* take absolute value
LAB_EXPS
							* now do n/LOG(2)
	MOVE.l	#$B8AA3B29,FAC2_m(a3)	* 1/LOG(2) mantissa
	MOVE.w	#$8100,FAC2_e(a3)		* 1/LOG(2) exponent & sign
	MOVE.b	#0,FAC_sc(a3)		* we know they're both +ve
	BSR		LAB_MULTIPLY		* effectively divide by log(2)

							* max here is +/- 127
							* now separate integer and fraction
	MOVE.b	#0,tpower(a3)		* clear exponent add byte
	MOVE.b	FAC1_e(a3),d5		* get exponent
	SUB.b		#$80,d5			* normalise
	BLS.s		LAB_ESML			* branch if < 1 (d5 is 0 or -ve)

							* result is > 1
	MOVE.l	FAC1_m(a3),d0		* get mantissa
	MOVE.l	d0,d1				* copy it
	MOVE.l	d5,d6				* copy normalised exponent

	NEG.w		d6				* make -ve
	ADD.w		#32,d6			* is now 32-d6
	LSR.l		d6,d1				* just integer bits
	MOVE.b	d1,tpower(a3)		* set exponent add byte

	LSL.l		d5,d0				* shift out integer bits
	BEQ		LAB_EXOF			* fraction is zero so do 2^n

	MOVE.l	d0,FAC1_m(a3)		* fraction to FAC1
	MOVE.w	#$8000,FAC1_e(a3)		* set exponent & sign

							* multiple was < 1
LAB_ESML
	MOVE.l	#$B17217F8,FAC2_m(a3)	* LOG(2) mantissa
	MOVE.w	#$8000,FAC2_e(a3)		* LOG(2) exponent & sign
	MOVE.b	#0,FAC_sc(a3)		* clear sign compare
	BSR		LAB_MULTIPLY		* multiply by log(2)

	MOVE.l	FAC1_m(a3),d0		* get mantissa
	MOVE.b	FAC1_e(a3),d5		* get exponent
	SUB.w		#$82,d5			* normalise and -2 (result is -1 to -30)
	NEG.w		d5				* make +ve
	LSR.l		d5,d0				* shift for 2 integer bits

* d0 = arg
* d6 = x, d1 = y
* d2 = x1, d3 = y1
* d4 = shift count
* d5 = loop count
							* now do cordic set-up
	MOVEQ		#0,d1				* y = 0
	MOVE.l	#KFCTSEED,d6		* x = 1 with jkh inverse factored out
	LEA		TAB_HTHET(pc),a0		* get pointer to hyperbolic arctan table
	MOVEQ		#0,d4				* clear shift count
 
							* cordic loop, shifts 4 and 13 (and 39
							* if it went that far) need to be repeated
	MOVEQ		#3,d5				* 4 loops
	BSR.s		LAB_EXCC			* do loops 1 through 4
	SUBQ.w	#4,a0				* do table entry again
	SUBQ.l	#1,d4				* do shift count again
	MOVEQ		#9,d5				* 10 loops
	BSR.s		LAB_EXCC			* do loops 4 (again) through 13
	SUBQ.w	#4,a0				* do table entry again
	SUBQ.l	#1,d4				* do shift count again
	MOVEQ		#18,d5			* 19 loops
	BSR.s		LAB_EXCC			* do loops 13 (again) through 31
 
							* now get the result
	TST.b		cosout(a3)			* test sign flag
	BPL.s		LAB_EXPL			* branch if +ve

	NEG.l		d1				* do -y
	NEG.b		tpower(a3)			* do -exp
LAB_EXPL
	MOVEQ		#$83-$100,d0		* set exponent
	ADD.l		d1,d6				* y = y +/- x
	BMI.s		LAB_EXRN			* branch if result normal

LAB_EXNN
	SUBQ.l	#1,d0				* decrement exponent
	ADD.l		d6,d6				* shift mantissa
	BPL.s		LAB_EXNN			* loop if not normal

LAB_EXRN
	MOVE.l	d6,FAC1_m(a3)		* save exponent result
	ADD.b		tpower(a3),d0		* add integer part
	MOVE.b	d0,FAC1_e(a3)		* save exponent
**	MOVEM.l	(sp)+,d1-d6/a0		* restore registers
	RTS
 
							* cordic loop
LAB_EXCC
	ADDQ.l	#1,d4				* increment shift count
	MOVE.l	d6,d2				* x1 = x
	ASR.l		d4,d2				* x1 >> n
	MOVE.l	d1,d3				* y1 = y
	ASR.l		d4,d3				* y1 >> n
	TST.l		d0				* test arg
	BMI.s		LAB_EXAD			* branch if -ve

	ADD.l		d2,d1				* y = y + x1
	ADD.l		d3,d6				* x = x + y1
	SUB.l		(a0)+,d0			* arg = arg - atnh(a0)
	DBF		d5,LAB_EXCC			* decrement and loop if not done

	RTS

LAB_EXAD
	SUB.l		d2,d1				* y = y - x1
	SUB.l		d3,d6				* x = x + y1
	ADD.l		(a0)+,d0			* arg = arg + atnh(a0)
	DBF		d5,LAB_EXCC			* decrement and loop if not done

	RTS


*************************************************************************************
*
* RND(n), 32 bit Galois version. make n=0 for 19th next number in sequence or n<>0
* to get 19th next number in sequence after seed n. This version of the PRNG uses
* the Galois method and a sample of 65536 bytes produced gives the following values.

* Entropy = 7.997442 bits per byte
* Optimum compression would reduce these 65536 bytes by 0 percent

* Chi square distribution for 65536 samples is 232.01, and
* randomly would exceed this value 75.00 percent of the time

* Arithmetic mean value of data bytes is 127.6724, 127.5 would be random
* Monte Carlo value for Pi is 3.122871269, error 0.60 percent
* Serial correlation coefficient is -0.000370, totally uncorrelated would be 0.0

LAB_RND
	TST.b		FAC1_e(a3)			* get FAC1 exponent
	BEQ.s		NextPRN			* do next random number if zero

							* else get seed into random number store
	LEA		PRNlword(a3),a0		* set PRNG pointer
	BSR		LAB_2778			* pack FAC1 into (a0)
NextPRN
	MOVEQ		#$AF-$100,d1		* set EOR value
	MOVEQ		#18,d2			* do this 19 times
	MOVE.l	PRNlword(a3),d0		* get current
Ninc0
	ADD.l		d0,d0				* shift left 1 bit
	BCC.s		Ninc1				* branch if bit 32 not set

	EOR.b		d1,d0				* do Galois LFSR feedback
Ninc1
	DBF		d2,Ninc0			* loop

	MOVE.l	d0,PRNlword(a3)		* save back to seed word
	MOVE.l	d0,FAC1_m(a3)		* copy to FAC1 mantissa
	MOVE.w	#$8000,FAC1_e(a3)		* set the exponent and clear the sign
	BRA		LAB_24D5			* normalise FAC1 & return


*************************************************************************************
*
* cordic TAN(x) routine, TAN(x) = SIN(x)/COS(x)
* x = angle in radians

LAB_TAN
	BSR.s		LAB_SIN			* go do SIN/COS cordic compute
	MOVE.w	FAC1_e(a3),FAC2_e(a3)	* copy exponent & sign from FAC1 to FAC2
	MOVE.l	FAC1_m(a3),FAC2_m(a3)	* copy FAC1 mantissa to FAC2 mantissa
	MOVE.l	d1,FAC1_m(a3)		* get COS(x) mantissa
	MOVE.b	d3,FAC1_e(a3)		* get COS(x) exponent
	BEQ		LAB_OFER			* do overflow if COS = 0

	BSR		LAB_24D5			* normalise FAC1
	BRA		LAB_DIVIDE			* do FAC2/FAC1 and return, FAC_sc set by SIN
							* COS calculation


*************************************************************************************
*
* cordic SIN(x), COS(x) routine
* x = angle in radians

LAB_COS
	MOVE.l	#$C90FDAA3,FAC2_m(a3)	* pi/2 mantissa (LSB is rounded up so
							* COS(PI/2)=0)
	MOVE.w	#$8100,FAC2_e(a3)		* pi/2 exponent and sign
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* sign = FAC1 sign (b7)
	BSR		LAB_ADD			* add FAC2 to FAC1, adjust for COS(x)


*************************************************************************************
*
* SIN/COS cordic calculator

LAB_SIN
	MOVE.b	#0,cosout(a3)		* set needed result

	MOVE.l	#$A2F9836F,FAC2_m(a3)	* 1/pi mantissa (LSB is rounded up so SIN(PI)=0)
	MOVE.w	#$7F00,FAC2_e(a3)		* 1/pi exponent & sign
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* sign = FAC1 sign (b7)
	BSR		LAB_MULTIPLY		* multiply by 1/pi

	MOVE.b	FAC1_e(a3),d0		* get FAC1 exponent
	BEQ.s		LAB_SCZE			* branch if zero

	LEA		TAB_SNCO(pc),a0		* get pointer to constants table
	MOVE.l	FAC1_m(a3),d6		* get FAC1 mantissa
	SUBQ.b	#1,d0				* 2 radians in 360 degrees so /2
	BEQ.s		LAB_SCZE			* branch if zero

	SUB.b		#$80,d0			* normalise exponent
	BMI.s		LAB_SCL0			* branch if < 1

							* X is > 1
	CMP.b		#$20,d0			* is it >= 2^32
	BCC.s		LAB_SCZE			* may as well do zero

	LSL.l		d0,d6				* shift out integer part bits
	BNE.s		LAB_CORD			* if fraction go test quadrant and adjust

							* else no fraction so do zero
LAB_SCZE
	MOVEQ		#$81-$100,d2		* set exponent for 1.0
	MOVEQ		#0,d3				* set exponent for 0.0
	MOVE.l	#$80000000,d0		* mantissa for 1.0
	MOVE.l	d3,d1				* mantissa for 0.0
	BRA.s		outloop			* go output it

							* x is < 1
LAB_SCL0
	NEG.b		d0				* make +ve
	CMP.b		#$1E,d0			* is it <= 2^-30
	BCC.s		LAB_SCZE			* may as well do zero

	LSR.l		d0,d6				* shift out <= 2^-32 bits

* cordic calculator, argument in d6
* table pointer in a0, returns in d0-d3

LAB_CORD
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* copy as sign compare for TAN
	ADD.l		d6,d6				* shift 0.5 bit into carry
	BCC.s		LAB_LTPF			* branch if less than 0.5

	EORI.b	#$FF,FAC1_s(a3)		* toggle result sign
LAB_LTPF
	ADD.l		d6,d6				* shift 0.25 bit into carry
	BCC.s		LAB_LTPT			* branch if less than 0.25

	EORI.b	#$FF,cosout(a3)		* toggle needed result
	EORI.b	#$FF,FAC_sc(a3)		* toggle sign compare for TAN

LAB_LTPT
	LSR.l		#2,d6				* shift the bits back (clear integer bits)
	BEQ.s		LAB_SCZE			* no fraction so go do zero

							* set start values
	MOVEQ		#1,d5				* set bit count
	MOVE.l	-4(a0),d0			* get multiply constant (1st itteration d0)
	MOVE.l	d0,d1				* 1st itteration d1
	SUB.l		(a0)+,d6			* 1st always +ve so do 1st step
	BRA.s		mainloop			* jump into routine

subloop
	SUB.l		(a0)+,d6			* z = z - arctan(i)/2pi
	SUB.l		d3,d0				* x = x - y1
	ADD.l		d2,d1				* y = y + x1
	BRA.s		nexta				* back to main loop

mainloop
	MOVE.l	d0,d2				* x1 = x
	ASR.l		d5,d2				* / (2 ^ i)
	MOVE.l	d1,d3				* y1 = y
	ASR.l		d5,d3				* / (2 ^ i)
	TST.l		d6				* test sign (is 2^0 bit)
	BPL.s		subloop			* go do subtract if > 1

	ADD.l		(a0)+,d6			* z = z + arctan(i)/2pi
	ADD.l		d3,d0				* x = x + y1
	SUB.l		d2,d1				* y = y + x1
nexta
	ADDQ.l	#1,d5				* i = i + 1
	CMP.l		#$1E,d5			* check end condition
	BNE.s		mainloop			* loop if not all done

							* now untangle output value
	MOVEQ		#$81-$100,d2		* set exponent for 0 to .99 rec.
	MOVE.l	d2,d3				* copy it for cos output
outloop
	TST.b		cosout(a3)			* did we want cos output?
	BMI.s		subexit			* if so skip

	EXG		d0,d1				* swap SIN and COS mantissas
	EXG		d2,d3				* swap SIN and COS exponents
subexit
	MOVE.l	d0,FAC1_m(a3)		* set result mantissa
	MOVE.b	d2,FAC1_e(a3)		* set result exponent
	BRA		LAB_24D5			* normalise FAC1 & return



*************************************************************************************
*
* perform ATN()

LAB_ATN
	MOVE.b	FAC1_e(a3),d0		* get FAC1 exponent
	BEQ		RTS_021			* ATN(0) = 0 so skip calculation

	MOVE.b	#0,cosout(a3)		* set result needed
	CMP.b		#$81,d0			* compare exponent with 1
	BCS.s		LAB_ATLE			* branch if n<1

	BNE.s		LAB_ATGO			* branch if n>1

	MOVE.l	FAC1_m(a3),d0		* get mantissa
	ADD.l		d0,d0				* shift left
	BEQ.s		LAB_ATLE			* branch if n=1

LAB_ATGO
	MOVE.l	#$80000000,FAC2_m(a3)	* set mantissa for 1
	MOVE.w	#$8100,FAC2_e(a3)		* set exponent for 1
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* sign compare = sign
	BSR		LAB_DIVIDE			* do 1/n
	MOVE.b	#$FF,cosout(a3)		* set inverse result needed
LAB_ATLE
	MOVE.l	FAC1_m(a3),d0		* get FAC1 mantissa
	MOVEQ		#$82,d1			* set to correct exponent
	SUB.b		FAC1_e(a3),d1		* subtract FAC1 exponent (always <= 1)
	LSR.l		d1,d0				* shift in two integer part bits
	LEA		TAB_ATNC(pc),a0		* get pointer to arctan table
	MOVEQ		#0,d6				* Z = 0
	MOVE.l	#1<<30,d1			* y = 1
	MOVEQ		#29,d5			* loop 30 times
	MOVEQ		#1,d4				* shift counter
	BRA.s		LAB_ATCD			* enter loop

LAB_ATNP
	ASR.l		d4,d2				* x1 / 2^i
	ADD.l		d2,d1				* y = y + x1
	ADD.l		(a0),d6			* z = z + atn(i)
LAB_ATCD
	MOVE.l	d0,d2				* x1 = x
	MOVE.l	d1,d3				* y1 = y
	ASR.l		d4,d3				* y1 / 2^i
LAB_CATN
	SUB.l		d3,d0				* x = x - y1
	BPL.s		LAB_ATNP			* branch if x >= 0

	MOVE.l	d2,d0				* else get x back
	ADDQ.w	#4,a0				* increment pointer
	ADDQ.l	#1,d4				* increment i
	ASR.l		#1,d3				* y1 / 2^i
	DBF		d5,LAB_CATN			* decrement and loop if not done

	MOVE.b	#$82,FAC1_e(a3)		* set new exponent
	MOVE.l	d6,FAC1_m(a3)		* save mantissa
	BSR		LAB_24D5			* normalise FAC1

	TST.b		cosout(a3)			* was it > 1 ?
	BPL.s		RTS_021			* branch if not

	MOVE.b	FAC1_s(a3),d7		* get sign
	MOVE.b	#0,FAC1_s(a3)		* clear sign
	MOVE.l	#$C90FDAA2,FAC2_m(a3)	* set -(pi/2)
	MOVE.w	#$8180,FAC2_e(a3)		* set exponent and sign
	MOVE.b	#$FF,FAC_sc(a3)		* set sign compare
	BSR		LAB_ADD			* perform addition, FAC2 to FAC1
	MOVE.b	d7,FAC1_s(a3)		* restore sign
RTS_021
	RTS


*************************************************************************************
*
* perform BITSET

LAB_BITSET
	BSR		LAB_GADB			* get two parameters for POKE or WAIT
							* first parameter in a0, second in d0
	CMP.b		#$08,d0			* only 0 to 7 are allowed
	BCC		LAB_FCER			* branch if > 7

	BSET		d0,(a0)			* set bit
	RTS


*************************************************************************************
*
* perform BITCLR

LAB_BITCLR
	BSR		LAB_GADB			* get two parameters for POKE or WAIT
							* first parameter in a0, second in d0
	CMP.b		#$08,d0			* only 0 to 7 are allowed
	BCC		LAB_FCER			* branch if > 7

	BCLR		d0,(a0)			* clear bit
	RTS


*************************************************************************************
*
* perform BITTST()

LAB_BTST
	MOVE.b	(a5)+,d0			* increment BASIC pointer
	BSR		LAB_GADB			* get two parameters for POKE or WAIT
							* first parameter in a0, second in d0
	CMP.b		#$08,d0			* only 0 to 7 are allowed
	BCC		LAB_FCER			* branch if > 7

	MOVE.l	d0,d1				* copy bit # to test
	BSR		LAB_GBYT			* get next BASIC byte
	CMP.b		#')',d0			* is next character ")"
	BNE		LAB_SNER			* if not ")" go do syntax error, then warm start

	BSR		LAB_IGBY			* update execute pointer (to character past ")")
	MOVEQ		#0,d0				* set the result as zero
	BTST		d1,(a0)			* test bit
	BEQ		LAB_27DB			* branch if zero (already correct)

	MOVEQ		#-1,d0			* set for -1 result
	BRA		LAB_27DB			* go do SGN tail


*************************************************************************************
*
* perform USING$()

fsd	EQU	 0					*   (sp) format string descriptor pointer
fsti	EQU	 4					*  4(sp) format string this index
fsli	EQU	 6					*  6(sp) format string last index
fsdpi	EQU	 8					*  8(sp) format string decimal point index
fsdc	EQU	10					* 10(sp) format string decimal characters
fend	EQU	12-4					*  x(sp) end-4, fsd is popped by itself

ofchr	EQU	'#'					* the overflow character

LAB_USINGS
	TST.b		Dtypef(a3)			* test data type, $80=string
	BPL		LAB_FOER			* if not string type go do format error

	MOVEA.l	FAC1_m(a3),a2		* get the format string descriptor pointer
	MOVE.w	4(a2),d7			* get the format string length
	BEQ		LAB_FOER			* if null string go do format error

* clear the format string values

	MOVEQ		#0,d0				* clear d0
	MOVE.w	d0,-(sp)			* clear the format string decimal characters
	MOVE.w	d0,-(sp)			* clear the format string decimal point index
	MOVE.w	d0,-(sp)			* clear the format string last index
	MOVE.w	d0,-(sp)			* clear the format string this index
	MOVE.l	a2,-(sp)			* save the format string descriptor pointer

* make a null return string for the first string add

	MOVEQ		#0,d1				* make a null string
	MOVEA.l	d1,a0				* with a null pointer
	BSR		LAB_RTST			* push a string on the descriptor stack
							* a0 = pointer, d1 = length

* do the USING$() function next value

	MOVE.b	(a5)+,d0			* get the next BASIC byte
LAB_U002
	CMP.b		#',',d0			* compare with comma
	BNE		LAB_SNER			* if not "," go do syntax error

	BSR		LAB_ProcFo			* process the format string
	TST.b		d2				* test the special characters flag
	BEQ		LAB_FOER			* if no special characters go do format error

	BSR		LAB_EVEX			* evaluate the expression
	TST.b		Dtypef(a3)			* test the data type
	BMI		LAB_TMER			* if string type go do type missmatch error

	TST.b		FAC1_e(a3)			* test FAC1 exponent
	BEQ.s		LAB_U004			* if FAC1 = 0 skip the rounding

	MOVE.w	fsdc(sp),d1			* get the format string decimal character count
	CMP.w		#8,d1				* compare the fraction digit count with 8
	BCC.s		LAB_U004			* if >= 8 skip the rounding

	MOVE.w	d1,d0				* else copy the fraction digit count
	ADD.w		d1,d1				* * 2
	ADD.w		d0,d1				* * 3
	ADD.w		d1,d1				* * 6
	LEA		LAB_P_10(pc),a0		* get the rounding table base
	MOVE.l	2(a0,d1.w),FAC2_m(a3)	* get the rounding mantissa
	MOVE.w	(a0,d1.w),d0		* get the rounding exponent
	SUB.w		#$100,d0			* effectively divide the mantissa by 2
	MOVE.w	d0,FAC2_e(a3)		* save the rounding exponent
	MOVE.b	#$00,FAC_sc(a3)		* clear the sign compare
	BSR		LAB_ADD			* round the value to n places
LAB_U004
	BSR		LAB_2970			* convert FAC1 to string - not on stack

	BSR		LAB_DupFmt			* duplicate the processed format string section
							* returns length in d1, pointer in a0

* process the number string, length in d6, decimal point index in d2

	LEA		Decss(a3),a2		* set the number string start
	MOVEQ		#0,d6				* clear the number string index
	MOVEQ		#'.',d4			* set the decimal point character
LAB_U005
	MOVE.w	d6,d2				* save the index to flag the decimal point
LAB_U006
	ADDQ.w	#1,d6				* increment the number string index
	MOVE.b	(a2,d6.w),d0		* get a number string character
	BEQ.s		LAB_U010			* if null then number complete

	CMP.b		#'E',d0			* compare the character with an "E"
	BEQ.s		LAB_U008			* was sx[.x]Esxx so go handle sci notation

	CMP.b		d4,d0				* compare the character with "."
	BNE.s		LAB_U006			* if not decimal point go get the next digit

	BRA.s		LAB_U005			* go save the index and get the next digit

* have found an sx[.x]Esxx number, the [.x] will not be present for a single digit

LAB_U008
	MOVE.w	d6,d3				* copy the index to the "E"
	SUBQ.w	#1,d3				* -1 gives the last digit index

	ADDQ.w	#1,d6				* increment the index to the exponent sign
	MOVE.b	(a2,d6.w),d0		* get the exponent sign character
	CMP.b		#'-',d0			* compare the exponent sign with "-"
	BNE		LAB_FCER			* if it wasn't sx[.x]E-xx go do function
							* call error

* found an sx[.x]E-xx number so check the exponent magnitude

	ADDQ.w	#1,d6				* increment the index to the exponent 10s
	MOVE.b	(a2,d6.w),d0		* get the exponent 10s character
	CMP.b		#'0',d0			* compare the exponent 10s with "0"
	BEQ.s		LAB_U009			* if it was sx[.x]E-0x go get the exponent
							* 1s character

	MOVEQ		#10,d0			* else start writing at index 10
	BRA.s		LAB_U00A			* go copy the digits

* found an sx[.x]E-0x number so get the exponent magnitude

LAB_U009
	ADDQ.w	#1,d6				* increment the index to the exponent 1s
	MOVEQ		#$0F,d0			* set the mask for the exponent 1s digit
	AND.b		(a2,d6.w),d0		* get and convert the exponent 1s digit
LAB_U00A
	MOVE.w	d3,d2				* copy the number last digit index
	CMPI.w	#1,d2				* is the number of the form sxE-0x
	BNE.s		LAB_U00B			* if it is sx.xE-0x skip the increment

							* else make room for the decimal point
	ADDQ.w	#1,d2				* add 1 to the write index
LAB_U00B
	ADD.w		d0,d2				* add the exponent 1s to the write index
	MOVEQ		#10,d0			* set the maximum write index
	SUB.w		d2,d0				* compare the index with the maximum
	BGT.s		LAB_U00C			* if the index < the maximum continue

	ADD.w		d0,d2				* else set the index to the maximum
	ADD.w		d0,d3				* adjust the read index
	CMPI.w	#1,d3				* compare the adjusted index with 1
	BGT.s		LAB_U00C			* if > 1 continue

	MOVEQ		#0,d3				* else allow for the decimal point
LAB_U00C
	MOVE.w		d2,d6				* copy the write index as the number
							* string length
	MOVEQ		#0,d0				* clear d0 to null terminate the number
							* string
LAB_U00D
	MOVE.b	d0,(a2,d2.w)		* save the character to the number string
	SUBQ.w	#1,d2				* decrement the number write index
	CMPI.w	#1,d2				* compare the number write index with 1
	BEQ.s		LAB_U00F			* if at the decimal point go save it

							* else write a digit to the number string
	MOVEQ		#'0',d0			* default to "0"
	TST.w		d3				* test the number read index
	BEQ.s		LAB_U00D			* if zero just go save the "0"

LAB_U00E
	MOVE.b	(a2,d3.w),d0		* read the next number digit
	SUBQ.w	#1,d3				* decrement the read index
	CMP.b		d4,d0				* compare the digit with "."
	BNE.s		LAB_U00D			* if not "." go save the digit

	BRA.s		LAB_U00E			* else go get the next digit

LAB_U00F
	MOVE.b	d4,(a2,d2.w)		* save the decimal point
LAB_U010
	TST.w		d2				* test the number string decimal point index
	BNE.s		LAB_U014			* if dp present skip the reset

	MOVE.w	d6,d2				* make the decimal point index = the length

* copy the fractional digit characters from the number string

LAB_U014
	MOVE.w	d2,d3				* copy the number string decimal point index
	ADDQ.w	#1,d3				* increment the number string index
	MOVE.w	fsdpi(sp),d4		* get the new format string decimal point index
LAB_U018
	ADDQ.w	#1,d4				* increment the new format string index
	CMP.w		d4,d1				* compare it with the new format string length
	BLS.s		LAB_U022			* if done the fraction digits go do integer

	MOVE.b	(a0,d4.w),d0		* get a new format string character
	CMP.b		#'%',d0			* compare it with "%"
	BEQ.s		LAB_U01C			* if "%" go copy a number character

	CMP.b		#'#',d0			* compare it with "#"
	BNE.s		LAB_U018			* if not "#" go do the next new format character

LAB_U01C
	MOVEQ		#'0',d0			* default to "0" character
	CMP.w		d3,d6				* compare the number string index with length
	BLS.s		LAB_U020			* if there skip the character get

	MOVE.b	(a2,d3.w),d0		* get a character from the number string
	ADDQ.w	#1,d3				* increment the number string index
LAB_U020
	MOVE.b	d0,(a0,d4.w)		* save the number character to the new format
							* string
	BRA.s		LAB_U018			* go do the next new format character

* now copy the integer digit characters from the number string

LAB_U022
	MOVEQ		#0,d6				* clear the sign done flag
	MOVEQ		#0,d5				* clear the sign present flag
	SUBQ.w	#1,d2				* decrement the number string index
	BNE.s		LAB_U026			* if not now at sign continue

	MOVEQ		#1,d2				* increment the number string index
	MOVE.b	#'0',(a2,d2.w)		* replace the point with a zero
LAB_U026
	MOVE.w	fsdpi(sp),d4		* get the new format string decimal point index
	CMP.w		d4,d1				* compare it with the new format string length
	BCC.s		LAB_U02A			* if within the string go use the index

	MOVE.w	d1,d4				* else set the index to the end of the string
LAB_U02A
	SUBQ.w	#1,d4				* decrement the new format string index
	BMI.s		LAB_U03E			* if all done go test for any overflow

	MOVE.b	(a0,d4.w),d0		* else get a new format string character

	MOVEQ		#'0',d7			* default to "0" character
	CMP.b		#'%',d0			* compare it with "%"
	BEQ.s		LAB_U02B			* if "%" go copy a number character

	MOVEQ		#' ',d7			* default to " " character
	CMP.b		#'#',d0			* compare it with "#"
	BNE.s		LAB_U02C			* if not "#" go try ","

LAB_U02B
	TST.w		d2				* test the number string index
	BNE.s		LAB_U036			* if not at the sign go get a number character

	BRA.s		LAB_U03C			* else go save the default character

LAB_U02C
	CMP.b		#',',d0			* compare it with ","
	BNE.s		LAB_U030			* if not "," go try the sign characters

	TST.w		d2				* test the number string index
	BNE.s		LAB_U02E			* if not at the sign keep the ","

	CMP.b		#'%',-1(a0,d4.w)		* else compare the next format string character
							* with "%"
	BNE.s		LAB_U03C			* if not "%" keep the default character

LAB_U02E
	MOVE.b	d0,d7				* else use the "," character
	BRA.s		LAB_U03C			* go save the character to the string

LAB_U030
	CMP.b		#'-',d0			* compare it with "-"
	BEQ.s		LAB_U034			* if "-" go do the sign character

	CMP.b		#'+',d0			* compare it with "+"
	BNE.s		LAB_U02A			* if not "+" go do the next new format character

	CMP.b		#'-',(a2)			* compare the sign character with "-"
	BEQ.s		LAB_U034			* if "-" don't change the sign character

	MOVE.b	#'+',(a2)			* else make the sign character "+"
LAB_U034
	MOVE.b	d0,d5				* set the sign present flag
	TST.w		d2				* test the number string index
	BEQ.s		LAB_U038			* if at the sign keep the default character

LAB_U036
	MOVE.b	(a2,d2.w),d7		* else get a character from the number string
	SUBQ.w	#1,d2				* decrement the number string index
	BRA.s		LAB_U03C			* go save the character

LAB_U038
	TST.b		d6				* test the sign done flag
	BNE.s		LAB_U03C			* if the sign has been done go use the space
							* character

	MOVE.b	(a2),d7			* else get the sign character
	MOVE.b	d7,d6				* flag that the sign has been done
LAB_U03C
	MOVE.b	d7,(a0,d4.w)		* save the number character to the new format
							* string
	BRA.s		LAB_U02A			* go do the next new format character

* test for overflow conditions

LAB_U03E
	TST.w		d2				* test the number string index
	BNE.s		LAB_U040			* if all the digits aren't done go output
							* an overflow indication

* test for sign overflows

	TST.b		d5				* test the sign present flag
	BEQ.s		LAB_U04A			* if no sign present go add the string

* there was a sign in the format string

	TST.b		d6				* test the sign done flag
	BNE.s		LAB_U04A			* if the sign is done go add the string

* the sign isn't done so see if it was mandatory

	CMPI.b	#'+',d5			* compare the sign with "+"
	BEQ.s		LAB_U040			* if it was "+" go output an overflow
							* indication

* the sign wasn't mandatory but the number may have been negative

	CMP.b		#'-',(a2)			* compare the sign character with "-"
	BNE.s		LAB_U04A			* if it wasn't "-" go add the string

* else the sign was "-" and a sign hasn't been output so ..

* the number overflowed the format string so replace all the special format characters
* with the overflow character

LAB_U040
	MOVEQ		#ofchr,d5			* set the overflow character
	MOVE.w	d1,d7				* copy the new format string length
	SUBQ.w	#1,d7				* adjust for the loop type
	MOVE.w	fsti(sp),d6			* copy the new format string last index
	SUBQ.w	#1,d6				* -1 gives the last character of this string
	BGT.s		LAB_U044			* if not zero continue

	MOVE.w	d7,d6				* else set the format string index to the end
LAB_U044
	MOVE.b	(a1,d6.w),d0		* get a character from the format string
	CMPI.b	#'#',d0			* compare it with "#" special format character
	BEQ.s		LAB_U046			* if "#" go use the overflow character

	CMPI.b	#'%',d0			* compare it with "%" special format character
	BEQ.s		LAB_U046			* if "%" go use the overflow character

	CMPI.b	#',',d0			* compare it with "," special format character
	BEQ.s		LAB_U046			* if "," go use the overflow character

	CMPI.b	#'+',d0			* compare it with "+" special format character
	BEQ.s		LAB_U046			* if "+" go use the overflow character

	CMPI.b	#'-',d0			* compare it with "-" special format character
	BEQ.s		LAB_U046			* if "-" go use the overflow character

	CMPI.b	#'.',d0			* compare it with "." special format character
	BNE.s		LAB_U048			* if not "." skip the using overflow character

LAB_U046
	MOVE.b	d5,d0				* use the overflow character
LAB_U048
	MOVE.b	d0,(a0,d7.w)		* save the character to the new format string
	SUBQ.w	#1,d6				* decrement the format string index
	DBF		d7,LAB_U044			* decrement the count and loop if not all done

* add the new string to the previous string

LAB_U04A
	LEA		6(a4),a0			* get the descriptor pointer for string 1
	MOVE.l	a4,FAC1_m(a3)		* save the descriptor pointer for string 2
	BSR		LAB_224E			* concatenate the strings

* now check for any tail on the format string

	MOVE.w	fsti(sp),d0			* get this index
	BEQ.s		LAB_U04C			* if at start of string skip the output

	MOVE.w	d0,fsli(sp)			* save this index to the last index
	BSR		LAB_ProcFo			* now process the format string
	TST.b		d2				* test the special characters flag
	BNE.s		LAB_U04C			* if special characters present skip the output

* else output the new string part

	BSR.s		LAB_DupFmt			* duplicate the processed format string section
	MOVE.w	fsti(sp),fsli(sp)		* copy this index to the last index

* add the new string to the previous string

	LEA		6(a4),a0			* get the descriptor pointer for string 1
	MOVE.l	a4,FAC1_m(a3)		* save the descriptor pointer for string 2
	BSR		LAB_224E			* concatenate the strings

* check for another value or end of function

LAB_U04C
	MOVE.b	(a5)+,d0			* get the next BASIC byte
	CMP.b		#')',d0			* compare with close bracket
	BNE		LAB_U002			* if not ")" go do next value

* pop the result string off the descriptor stack

	MOVEA.l	a4,a0				* copy the result string descriptor pointer
	MOVE.l	Sstorl(a3),d1		* save the bottom of string space
	BSR		LAB_22BA			* pop (a0) descriptor, returns with ..
							* d0 = length, a0 = pointer
	MOVE.l	d1,Sstorl(a3)		* restore the bottom of string space
	MOVEA.l	a0,a1				* copy the string result pointer
	MOVE.w	d0,d1				* copy the string result length

* pop the format string off the descriptor stack

	MOVEA.l	(sp)+,a0			* pull the format string descriptor pointer
	BSR		LAB_22BA			* pop (a0) descriptor, returns with ..
							* d0 = length, a0 = pointer

	LEA		fend(sp),sp			* dump the saved values

* push the result string back on the descriptor stack and return

	MOVEA.l	a1,a0				* copy the result string pointer back
	BRA		LAB_RTST			* push a string on the descriptor stack and
							* return. a0 = pointer, d1 = length


*************************************************************************************
*
* duplicate the processed format string section

							* make a string as long as the format string
LAB_DupFmt
	MOVEA.l	4+fsd(sp),a1		* get the format string descriptor pointer
	MOVE.w	4(a1),d7			* get the format string length
	MOVE.w	4+fsli(sp),d2		* get the format string last index
	MOVE.w	4+fsti(sp),d6		* get the format string this index
	MOVE.w	d6,d1				* copy the format string this index
	SUB.w		d2,d1				* subtract the format string last index
	BHI.s		LAB_D002			* if > 0 skip the correction

	ADD.w		d7,d1				* else add the format string length as the
							* correction
LAB_D002
	BSR		LAB_2115			* make string space d1 bytes long
							* return a0/Sutill = pointer, others unchanged

* push the new string on the descriptor stack

	BSR		LAB_RTST			* push a string on the descriptor stack and
							* return. a0 = pointer, d1 = length

* copy the characters from the format string

	MOVEA.l	4+fsd(sp),a1		* get the format string descriptor pointer
	MOVEA.l	(a1),a1			* get the format string pointer
	MOVEQ		#0,d4				* clear the new string index
LAB_D00A
	MOVE.b	(a1,d2.w),(a0,d4.w)	* get a character from the format string and
							* save it to the new string
	ADDQ.w	#1,d4				* increment the new string index
	ADDQ.w	#1,d2				* increment the format string index
	CMP.w		d2,d7				* compare the format index with the length
	BNE.s		LAB_D00E			* if not there skip the reset

	MOVEQ		#0,d2				* else reset the format string index
LAB_D00E
	CMP.w		d2,d6				* compare the index with this index
	BNE.s		LAB_D00A			* if not equal go do the next character

	RTS


**************************************************************************************
*
* process the format string

LAB_ProcFo
	MOVEA.l	4+fsd(sp),a1		* get the format string descriptor pointer
	MOVE.w	4(a1),d7			* get the format string length
	MOVEA.l	(a1),a1			* get the format string pointer
	MOVE.w	4+fsli(sp),d6		* get the format string last index

	MOVE.w	d7,4+fsdpi(sp)		* set the format string decimal point index
*##	MOVE.w	#-1,4+fsdpi(sp)		* set the format string decimal point index
	MOVEQ		#0,d5				* no decimal point
	MOVEQ		#0,d3				* no decimal characters
	MOVEQ		#0,d2				* no special characters
LAB_P004
	MOVE.b	(a1,d6.w),d0		* get a format string byte

	CMP.b		#',',d0			* compare it with ","
	BEQ.s		LAB_P01A			* if "," go do the next format string byte

	CMP.b		#'#',d0			* compare it with "#"
	BEQ.s		LAB_P008			* if "#" go flag special characters

	CMP.b		#'%',d0			* compare it with "%"
	BNE.s		LAB_P00C			* if not "%" go try "+"

LAB_P008
	TST.l		d5				* test the decimal point flag
	BPL.s		LAB_P00E			* if no point skip counting decimal characters

	ADDQ.w	#1,d3				* else increment the decimal character count
	BRA.s		LAB_P01A			* go do the next character

LAB_P00C
	CMP.b		#'+',d0			* compare it with "+"
	BEQ.s		LAB_P00E			* if "+" go flag special characters

	CMP.b		#'-',d0			* compare it with "-"
	BNE.s		LAB_P010			* if not "-" go check decimal point

LAB_P00E
	OR.b		d0,d2				* flag special characters
	BRA.s		LAB_P01A			* go do the next character

LAB_P010
	CMP.b		#'.',d0			* compare it with "."
	BNE.s		LAB_P018			* if not "." go check next

* "." a decimal point

	TST.l		d5				* if there is already a decimal point
	BMI.s		LAB_P01A			* go do the next character

	MOVE.w	d6,d0				* copy the decimal point index
	SUB.w		4+fsli(sp),d0		* calculate it from the scan start
	MOVE.w	d0,4+fsdpi(sp)		* save the decimal point index
	MOVEQ		#-1,d5			* flag decimal point
	OR.b		d0,d2				* flag special characters
	BRA.s		LAB_P01A			* go do the next character

* was not a special character

LAB_P018
	TST.b		d2				* test if there have been special characters
	BNE.s		LAB_P01E			* if so exit the format string process

LAB_P01A
	ADDQ.w	#1,d6				* increment the format string index
	CMP.w		d6,d7				* compare it with the format string length
	BHI.s		LAB_P004			* if length > index go get the next character

	MOVEQ		#0,d6				* length = index so reset the format string
							* index
LAB_P01E
	MOVE.w	d6,4+fsti(sp)		* save the format string this index
	MOVE.w	d3,4+fsdc(sp)		* save the format string decimal characters

	RTS


*************************************************************************************
*
* perform BIN$()
* # of leading 0s is in d1, the number is in d0

LAB_BINS
	CMP.b		#$21,d1			* max + 1
	BCC		LAB_FCER			* exit if too big ( > or = )

	MOVEQ		#$1F,d2			* bit count-1
	LEA		Binss(a3),a0		* point to string
	MOVEQ		#$30,d4			* "0" character for ADDX
NextB1
	MOVEQ		#0,d3				* clear byte
	LSR.l		#1,d0				* shift bit into Xb
	ADDX.b	d4,d3				* add carry and character to zero
	MOVE.b	d3,(a0,d2.w)		* save character to string
	DBF		d2,NextB1			* decrement and loop if not done

* this is the exit code and is also used by HEX$()

EndBHS
	MOVE.b	#0,BHsend(a3)		* null terminate the string
	TST.b		d1				* test # of characters
	BEQ.s		NextB2			* go truncate string

	NEG.l		d1				* make -ve
	ADD.l		#BHsend,d1			* effectively (end-length)
	LEA		0(a3,d1.w),a0		* effectively add (end-length) to pointer
	BRA.s		BinPr				* go print string

* truncate string to remove leading "0"s

NextB2
	MOVE.b	(a0),d0			* get byte
	BEQ.s		BinPr				* if null then end of string so add 1 and go
							* print it

	CMP.b		#'0',d0			* compare with "0"
	BNE.s		GoPr				* if not "0" then go print string from here

	ADDQ.w	#1,a0				* else increment pointer
	BRA.s		NextB2			* loop always

* make fixed length output string - ignore overflows!

BinPr
	LEA		BHsend(a3),a1		* get string end
	CMPA.l	a1,a0				* are we at the string end
	BNE.s		GoPr				* branch if not

	SUBQ.w	#1,a0				* else need at least one zero
GoPr
	BRA		LAB_20AE			* print " terminated string to FAC1, stack & RET


*************************************************************************************
*
* perform HEX$()
* # of leading 0s is in d1, the number is in d0

LAB_HEXS
	CMP.b		#$09,d1			* max + 1
	BCC		LAB_FCER			* exit if too big ( > or = )

	MOVEQ		#$07,d2			* nibble count-1
	LEA		Hexss(a3),a0		* point to string
	MOVEQ		#$30,d4			* "0" character for ABCD
NextH1
	MOVE.b	d0,d3				* copy lowest byte
	ROR.l		#4,d0				* shift nibble into 0-3
	AND.b		#$0F,d3			* just this nibble
	MOVE.b	d3,d5				* copy it
	ADD.b		#$F6,d5			* set extend bit
	ABCD		d4,d3				* decimal add extend and character to zero
	MOVE.b	d3,(a0,d2.w)		* save character to string
	DBF		d2,NextH1			* decrement and loop if not done

	BRA.s		EndBHS			* go process string


*************************************************************************************
*
* ctrl-c check routine. includes limited "life" byte save for INGET routine

VEC_CC
	TST.b		ccflag(a3)			* check [CTRL-C] check flag
	BNE.s		RTS_022			* exit if [CTRL-C] check inhibited

	JSR		V_INPT(a3)			* scan input device
	BCC.s		LAB_FBA0			* exit if buffer empty

	MOVE.b	d0,ccbyte(a3)		* save received byte
	MOVE.b	#$20,ccnull(a3)		* set "life" timer for bytes countdown
	BRA		LAB_1636			* return to BASIC

LAB_FBA0
	TST.b		ccnull(a3)			* get countdown byte
	BEQ.s		RTS_022			* exit if finished

	SUBQ.b	#1,ccnull(a3)		* else decrement countdown
RTS_022
	RTS


*************************************************************************************
*
* get byte from input device, no waiting
* returns with carry set if byte in A

INGET
	JSR		V_INPT(a3)			* call scan input device
	BCS.s		LAB_FB95			* if byte go reset timer

	MOVE.b	ccnull(a3),d0		* get countdown
	BEQ.s		RTS_022			* exit if empty

	MOVE.b	ccbyte(a3),d0		* get last received byte
LAB_FB95
	MOVE.b	#$00,ccnull(a3)		* clear timer because we got a byte
	ORI.b		#1,CCR			* set carry, flag we got a byte
	RTS


*************************************************************************************
*
* perform MAX()

LAB_MAX
	BSR		LAB_EVEZ			* evaluate expression (no decrement)
	TST.b		Dtypef(a3)			* test data type
	BMI		LAB_TMER			* if string do Type missmatch Error/warm start

LAB_MAXN
	BSR.s		LAB_PHFA			* push FAC1, evaluate expression,
							* pull FAC2 & compare with FAC1
	BCC.s		LAB_MAXN			* branch if no swap to do

	BSR		LAB_279B			* copy FAC2 to FAC1
	BRA.s		LAB_MAXN			* go do next


*************************************************************************************
*
* perform MIN()

LAB_MIN
	BSR		LAB_EVEZ			* evaluate expression (no decrement)
	TST.b		Dtypef(a3)			* test data type
	BMI		LAB_TMER			* if string do Type missmatch Error/warm start

LAB_MINN
	BSR.s		LAB_PHFA			* push FAC1, evaluate expression,
							* pull FAC2 & compare with FAC1
	BLS.s		LAB_MINN			* branch if no swap to do

	BSR		LAB_279B			* copy FAC2 to FAC1
	BRA.s		LAB_MINN			* go do next (branch always)

* exit routine. don't bother returning to the loop code
* check for correct exit, else so syntax error

LAB_MMEC
	CMP.b		#')',d0			* is it end of function?
	BNE		LAB_SNER			* if not do MAX MIN syntax error

	LEA		4(sp),sp			* dump return address (faster)
	BRA		LAB_IGBY			* update BASIC execute pointer (to chr past ")")
							* and return

* check for next, evaluate & return or exit
* this is the routine that does most of the work

LAB_PHFA
	BSR		LAB_GBYT			* get next BASIC byte
	CMP.b		#',',d0			* is there more ?
	BNE.s		LAB_MMEC			* if not go do end check

	MOVE.w	FAC1_e(a3),-(sp)		* push exponent and sign
	MOVE.l	FAC1_m(a3),-(sp)		* push mantissa

	BSR		LAB_EVEZ			* evaluate expression (no decrement)
	TST.b		Dtypef(a3)			* test data type
	BMI		LAB_TMER			* if string do Type missmatch Error/warm start


							* pop FAC2 (MAX/MIN expression so far)
	MOVE.l	(sp)+,FAC2_m(a3)		* pop mantissa

	MOVE.w	(sp)+,d0			* pop exponent and sign
	MOVE.w	d0,FAC2_e(a3)		* save exponent and sign
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* get FAC1 sign
	EOR.b		d0,FAC_sc(a3)		* EOR to create sign compare
	BRA		LAB_27FA			* compare FAC1 with FAC2 & return
							* returns d0=+1 Cb=0 if FAC1 > FAC2
							* returns d0= 0 Cb=0 if FAC1 = FAC2
							* returns d0=-1 Cb=1 if FAC1 < FAC2


*************************************************************************************
*
* perform WIDTH

LAB_WDTH
	CMP.b		#',',d0			* is next byte ","
	BEQ.s		LAB_TBSZ			* if so do tab size

	BSR		LAB_GTBY			* get byte parameter, result in d0 and Itemp
	TST.b		d0				* test result
	BEQ.s		LAB_NSTT			* branch if set for infinite line

	CMP.b		#$10,d0			* else make min width = 16d
	BCS		LAB_FCER			* if less do function call error & exit

* this next compare ensures that we can't exit WIDTH via an error leaving the
* tab size greater than the line length.

	CMP.b		TabSiz(a3),d0		* compare with tab size
	BCC.s		LAB_NSTT			* branch if >= tab size

	MOVE.b	d0,TabSiz(a3)		* else make tab size = terminal width
LAB_NSTT
	MOVE.b	d0,TWidth(a3)		* set the terminal width
	BSR		LAB_GBYT			* get BASIC byte back
	BEQ.s		WExit				* exit if no following

	CMP.b		#',',d0			* else is it ","
	BNE		LAB_SNER			* if not do syntax error

LAB_TBSZ
	BSR		LAB_SGBY			* increment and get byte, result in d0 and Itemp
	TST.b		d0				* test TAB size
	BMI		LAB_FCER			* if >127 do function call error & exit

	CMP.b		#1,d0				* compare with min-1
	BCS		LAB_FCER			* if <=1 do function call error & exit

	MOVE.b	TWidth(a3),d1		* set flags for width
	BEQ.s		LAB_SVTB			* skip check if infinite line

	CMP.b		TWidth(a3),d0		* compare TAB with width
	BGT		LAB_FCER			* branch if too big

LAB_SVTB
	MOVE.b	d0,TabSiz(a3)		* save TAB size

* calculate tab column limit from TAB size. The Iclim is set to the last tab
* position on a line that still has at least one whole tab width between it
* and the end of the line.

WExit
	MOVE.b	TWidth(a3),d0		* get width
	BEQ.s		LAB_WDLP			* branch if infinite line

	CMP.b		TabSiz(a3),d0		* compare with tab size
	BCC.s		LAB_WDLP			* branch if >= tab size

	MOVE.b	d0,TabSiz(a3)		* else make tab size = terminal width
LAB_WDLP
	SUB.b		TabSiz(a3),d0		* subtract tab size
	BCC.s		LAB_WDLP			* loop while no borrow

	ADD.b		TabSiz(a3),d0		* add tab size back
	ADD.b		TabSiz(a3),d0		* add tab size back again

	NEG.b		d0				* make -ve
	ADD.b		TWidth(a3),d0		* subtract remainder from width
	MOVE.b	d0,Iclim(a3)		* save tab column limit
RTS_023
	RTS


*************************************************************************************
*
* perform SQR()

* d0 is number to find the root of
* d1 is the root result
* d2 is the remainder
* d3 is a counter
* d4 is temp

LAB_SQR
	TST.b		FAC1_s(a3)			* test FAC1 sign
	BMI		LAB_FCER			* if -ve do function call error

	TST.b		FAC1_e(a3)			* test exponent
	BEQ.s		RTS_023			* exit if zero

	MOVEM.l	d1-d4,-(sp)			* save registers
	MOVE.l	FAC1_m(a3),d0		* copy FAC1
	MOVEQ		#0,d2				* clear remainder
	MOVE.l	d2,d1				* clear root

	MOVEQ		#$1F,d3			* $1F for DBF, 64 pairs of bits to
							* do for a 32 bit result
	BTST		#0,FAC1_e(a3)		* test exponent odd/even
	BNE.s		LAB_SQE2			* if odd only 1 shift first time

LAB_SQE1
	ADD.l		d0,d0				* shift highest bit of number ..
	ADDX.l	d2,d2				* .. into remainder .. never overflows
	ADD.l		d1,d1				* root = root * 2 .. never overflows
LAB_SQE2
	ADD.l		d0,d0				* shift highest bit of number ..
	ADDX.l	d2,d2				* .. into remainder .. never overflows

	MOVE.l	d1,d4				* copy root
	ADD.l		d4,d4				* 2n
	ADDQ.l	#1,d4				* 2n+1

	CMP.l		d4,d2				* compare 2n+1 to remainder
	BCS.s		LAB_SQNS			* skip sub if remainder smaller

	SUB.l		d4,d2				* subtract temp from remainder
	ADDQ.l	#1,d1				* increment root
LAB_SQNS
	DBF		d3,LAB_SQE1			* loop if not all done

	MOVE.l	d1,FAC1_m(a3)		* save result mantissa
	MOVE.b	FAC1_e(a3),d0		* get exponent (d0 is clear here)
	SUB.w		#$80,d0			* normalise
	LSR.w		#1,d0				* /2
	BCC.s		LAB_SQNA			* skip increment if carry clear

	ADDQ.w	#1,d0				* add bit zero back in (allow for half shift)
LAB_SQNA
	ADD.w		#$80,d0			* re-bias to $80
	MOVE.b	d0,FAC1_e(a3)		* save it
	MOVEM.l	(sp)+,d1-d4			* restore registers
	BRA		LAB_24D5			* normalise FAC1 & return


*************************************************************************************
*
* perform VARPTR()

LAB_VARPTR
	MOVE.b	(a5)+,d0			* increment pointer
LAB_VARCALL
	BSR		LAB_GVAR			* get variable address in a0
	BSR		LAB_1BFB			* scan for ")", else do syntax error/warm start
	MOVE.l	a0,d0				* copy the variable address
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & return


*************************************************************************************
*
* perform RAMBASE

LAB_RAM
	LEA		ram_base(a3),a0		* get start of EhBASIC RAM
	MOVE.l	a0,d0				* copy it
	BRA		LAB_AYFC			* convert d0 to signed longword in FAC1 & return


*************************************************************************************
*
* perform PI

LAB_PI
	MOVE.l	#$C90FDAA2,FAC1_m(a3)	* pi mantissa (32 bit)
	MOVE.w	#$8200,FAC1_e(a3)		* pi exponent and sign
	RTS


*************************************************************************************
*
* perform TWOPI

LAB_TWOPI
	MOVE.l	#$C90FDAA2,FAC1_m(a3)	* 2pi mantissa (32 bit)
	MOVE.w	#$8300,FAC1_e(a3)		* 2pi exponent and sign
	RTS


*************************************************************************************
*
* get ASCII string equivalent into FAC1 as integer32 or float

* entry is with a5 pointing to the first character of the string
* exit with a5 pointing to the first character after the string

* d0 is character
* d1 is mantissa
* d2 is partial and table mantissa
* d3 is mantissa exponent (decimal & binary)
* d4 is decimal exponent

* get FAC1 from string
* this routine now handles hex and binary values from strings
* starting with "$" and "%" respectively

LAB_2887
	MOVEM.l	d1-d5,-(sp)			* save registers
	MOVEQ		#$00,d1			* clear temp accumulator
	MOVE.l	d1,d3				* set mantissa decimal exponent count
	MOVE.l	d1,d4				* clear decimal exponent
	MOVE.b	d1,FAC1_s(a3)		* clear sign byte
	MOVE.b	d1,Dtypef(a3)		* set float data type
	MOVE.b	d1,expneg(a3)		* clear exponent sign
	BSR		LAB_GBYT			* get first byte back
	BCS.s		LAB_28FE			* go get floating if 1st character numeric

	CMP.b		#'-',d0			* or is it -ve number
	BNE.s		LAB_289A			* branch if not

	MOVE.b	#$FF,FAC1_s(a3)		* set sign byte
	BRA.s		LAB_289C			* now go scan & check for hex/bin/int

LAB_289A
							* first character wasn't numeric or -
	CMP.b		#'+',d0			* compare with '+'
	BNE.s		LAB_289D			* branch if not '+' (go check for '.'/hex/binary
							* /integer)
	
LAB_289C
							* was "+" or "-" to start, so get next character
	BSR		LAB_IGBY			* increment & scan memory
	BCS.s		LAB_28FE			* branch if numeric character

LAB_289D
	CMP.b		#'.',d0			* else compare with '.'
	BEQ		LAB_2904			* branch if '.'

							* code here for hex/binary/integer numbers
	CMP.b		#'$',d0			* compare with '$'
	BEQ		LAB_CHEX			* branch if '$'

	CMP.b		#'%',d0			* else compare with '%'
	BEQ		LAB_CBIN			* branch if '%'

	BRA		LAB_2Y01			* not #.$%& so return 0

LAB_28FD
	BSR		LAB_IGBY			* get next character
	BCC.s		LAB_2902			* exit loop if not a digit

LAB_28FE
	BSR		d1x10				* multiply d1 by 10 and add character
	BCC.s		LAB_28FD			* loop for more if no overflow

LAB_28FF
							* overflowed mantissa, count 10s exponent
	ADDQ.l	#1,d3				* increment mantissa decimal exponent count
	BSR		LAB_IGBY			* get next character
	BCS.s		LAB_28FF			* loop while numeric character

							* done overflow, now flush fraction or do E
	CMP.b		#'.',d0			* else compare with '.'
	BNE.s		LAB_2901			* branch if not '.'

LAB_2900
							* flush remaining fraction digits
	BSR		LAB_IGBY			* get next character
	BCS		LAB_2900			* loop while numeric character

LAB_2901
							* done number, only (possible) exponent remains
	CMP.b		#'E',d0			* else compare with 'E'
	BNE.s		LAB_2Y01			* if not 'E' all done, go evaluate

							* process exponent
	BSR		LAB_IGBY			* get next character
	BCS.s		LAB_2X04			* branch if digit

	CMP.b		#'-',d0			* or is it -ve number
	BEQ.s		LAB_2X01			* branch if so

	CMP.b		#TK_MINUS,d0		* or is it -ve number
	BNE.s		LAB_2X02			* branch if not

LAB_2X01
	MOVE.b	#$FF,expneg(a3)		* set exponent sign
	BRA.s		LAB_2X03			* now go scan & check exponent

LAB_2X02
	CMP.b		#'+',d0			* or is it +ve number
	BEQ.s		LAB_2X03			* branch if so

	CMP.b		#TK_PLUS,d0			* or is it +ve number
	BNE		LAB_SNER			* wasn't - + TK_MINUS TK_PLUS or # so do error

LAB_2X03
	BSR		LAB_IGBY			* get next character
	BCC.s		LAB_2Y01			* if not digit all done, go evaluate
LAB_2X04
	MULU		#10,d4			* multiply decimal exponent by 10
	AND.l		#$FF,d0			* mask character
	SUB.b		#'0',d0			* convert to value
	ADD.l		d0,d4				* add to decimal exponent
	CMP.b		#48,d4			* compare with decimal exponent limit+10
	BLE.s		LAB_2X03			* loop if no overflow/underflow

LAB_2X05
							* exponent value has overflowed
	BSR		LAB_IGBY			* get next character
	BCS.s		LAB_2X05			* loop while numeric digit

	BRA.s		LAB_2Y01			* all done, go evaluate

LAB_2902
	CMP.b		#'.',d0			* else compare with '.'
	BEQ.s		LAB_2904			* branch if was '.'

	BRA.s		LAB_2901			* branch if not '.' (go check/do 'E')

LAB_2903
	SUBQ.l	#1,d3				* decrement mantissa decimal exponent
LAB_2904
							* was dp so get fraction part
	BSR		LAB_IGBY			* get next character
	BCC.s		LAB_2901			* exit loop if not a digit (go check/do 'E')

	BSR		d1x10				* multiply d1 by 10 and add character
	BCC.s		LAB_2903			* loop for more if no overflow

	BRA.s		LAB_2900			* else go flush remaining fraction part

LAB_2Y01
							* now evaluate result
	TST.b		expneg(a3)			* test exponent sign
	BPL.s		LAB_2Y02			* branch if sign positive

	NEG.l		d4				* negate decimal exponent
LAB_2Y02
	ADD.l		d3,d4				* add mantissa decimal exponent
	MOVEQ		#32,d3			* set up max binary exponent
	TST.l		d1				* test mantissa
	BEQ.s		LAB_rtn0			* if mantissa=0 return 0

	BMI.s		LAB_2Y04			* branch if already mormalised

	SUBQ.l	#1,d3				* decrement bianry exponent for DBMI loop
LAB_2Y03
	ADD.l		d1,d1				* shift mantissa
	DBMI		d3,LAB_2Y03			* decrement & loop if not normalised

							* ensure not too big or small
LAB_2Y04
	CMP.l		#38,d4			* compare decimal exponent with max exponent
	BGT		LAB_OFER			* if greater do overflow error and warm start

	CMP.l		#-38,d4			* compare decimal exponent with min exponent
	BLT.s		LAB_ret0			* if less just return zero

	NEG.l		d4				* negate decimal exponent to go right way
	MULS		#6,d4				* 6 bytes per entry
	MOVE.l	a0,-(sp)			* save register
	LEA		LAB_P_10(pc),a0		* point to table
	MOVE.b	(a0,d4.w),FAC2_e(a3)	* copy exponent for multiply
	MOVE.l	2(a0,d4.w),FAC2_m(a3)	* copy table mantissa
	MOVE.l	(sp)+,a0			* restore register

	EORI.b	#$80,d3			* normalise input exponent
	MOVE.l	d1,FAC1_m(a3)		* save input mantissa
	MOVE.b	d3,FAC1_e(a3)		* save input exponent
	MOVE.b	FAC1_s(a3),FAC_sc(a3)	* set sign as sign compare

	MOVEM.l	(sp)+,d1-d5			* restore registers
	BRA		LAB_MULTIPLY		* go multiply input by table

LAB_ret0
	MOVEQ		#0,d1				* clear mantissa
LAB_rtn0
	MOVE.l	d1,d3				* clear exponent
	MOVE.b	d3,FAC1_e(a3)		* save exponent
	MOVE.l	d1,FAC1_m(a3)		* save mantissa
	MOVEM.l	(sp)+,d1-d5			* restore registers
	RTS


*************************************************************************************
*
* $ for hex add-on

* gets here if the first character was "$" for hex
* get hex number

LAB_CHEX
	MOVE.b	#$40,Dtypef(a3)		* set integer numeric data type
	MOVEQ		#32,d3			* set up max binary exponent
LAB_CHXX
	BSR		LAB_IGBY			* increment & scan memory
	BCS.s		LAB_ISHN			* branch if numeric character

	OR.b		#$20,d0			* case convert, allow "A" to "F" and "a" to "f"
	SUB.b		#'a',d0			* subtract "a"
	BCS.s		LAB_CHX3			* exit if <"a"

	CMP.b		#$06,d0			* compare normalised with $06 (max+1)
	BCC.s		LAB_CHX3			* exit if >"f"

	ADD.b		#$3A,d0			* convert to nibble+"0"
LAB_ISHN
	BSR.s		d1x16				* multiply d1 by 16 and add the character
	BCC.s		LAB_CHXX			* loop for more if no overflow

							* overflowed mantissa, count 16s exponent
LAB_CHX1
	ADDQ.l	#4,d3				* increment mantissa exponent count
	BVS		LAB_OFER			* do overflow error if overflowed

	BSR		LAB_IGBY			* get next character
	BCS.s		LAB_CHX1			* loop while numeric character

	OR.b		#$20,d0			* case convert, allow "A" to "F" and "a" to "f"
	SUB.b		#'a',d0			* subtract "a"
	BCS.s		LAB_CHX3			* exit if <"a"

	CMP.b		#$06,d0			* compare normalised with $06 (max+1)
	BCS.s		LAB_CHX1			* loop if <="f"

							* now return value
LAB_CHX3
	TST.l		d1				* test mantissa
	BEQ.s		LAB_rtn0			* if mantissa=0 return 0

	BMI.s		LAB_exxf			* branch if already mormalised

	SUBQ.l	#1,d3				* decrement bianry exponent for DBMI loop
LAB_CHX2
	ADD.l		d1,d1				* shift mantissa
	DBMI		d3,LAB_CHX2			* decrement & loop if not normalised

LAB_exxf
	EORI.b	#$80,d3			* normalise exponent
	MOVE.b	d3,FAC1_e(a3)		* save exponent
	MOVE.l	d1,FAC1_m(a3)		* save mantissa
	MOVEM.l	(sp)+,d1-d5			* restore registers
RTS_024
	RTS


*************************************************************************************
*
* % for binary add-on

* gets here if the first character was "%" for binary
* get binary number

LAB_CBIN
	MOVE.b	#$40,Dtypef(a3)		* set integer numeric data type
	MOVEQ		#32,d3			* set up max binary exponent
LAB_CBXN
	BSR		LAB_IGBY			* increment & scan memory
	BCC.s		LAB_CHX3			* if not numeric character go return value

	CMP.b		#'2',d0			* compare with "2" (max+1)
	BCC.s		LAB_CHX3			* if >="2" go return value

	MOVE.l	d1,d2				* copy value
	BSR.s		d1x02				* multiply d1 by 2 and add character
	BCC.s		LAB_CBXN			* loop for more if no overflow

							* overflowed mantissa, count 2s exponent
LAB_CBX1
	ADDQ.l	#1,d3				* increment mantissa exponent count
	BVS		LAB_OFER			* do overflow error if overflowed

	BSR		LAB_IGBY			* get next character
	BCC.s		LAB_CHX3			* if not numeric character go return value

	CMP.b		#'2',d0			* compare with "2" (max+1)
	BCS.s		LAB_CBX1			* loop if <"2"

	BRA.s		LAB_CHX3			* if not numeric character go return value

* half way decent times 16 and times 2 with overflow checks

d1x16
	MOVE.l	d1,d2				* copy value
	ADD.l		d2,d2				* times two
	BCS.s		RTS_024			* return if overflow

	ADD.l		d2,d2				* times four
	BCS.s		RTS_024			* return if overflow

	ADD.l		d2,d2				* times eight
	BCS.s		RTS_024			* return if overflow

d1x02
	ADD.l		d2,d2				* times sixteen (ten/two)
	BCS.s		RTS_024			* return if overflow

* now add in new digit

	AND.l		#$FF,d0			* mask character
	SUB.b		#'0',d0			* convert to value
	ADD.l		d0,d2				* add to result
	BCS.s		RTS_024			* return if overflow, it should never ever do
							* this

	MOVE.l	d2,d1				* copy result
	RTS

* half way decent times 10 with overflow checks

d1x10
	MOVE.l	d1,d2				* copy value
	ADD.l		d2,d2				* times two
	BCS.s		RTS_025			* return if overflow

	ADD.l		d2,d2				* times four
	BCS.s		RTS_025			* return if overflow

	ADD.l		d1,d2				* times five
	BCC.s		d1x02				* do times two and add in new digit if ok

RTS_025
	RTS


*************************************************************************************
*
* token values needed for BASIC

TK_END		EQU $80			* $80
TK_FOR		EQU TK_END+1		* $81
TK_NEXT		EQU TK_FOR+1		* $82
TK_DATA		EQU TK_NEXT+1		* $83
TK_INPUT		EQU TK_DATA+1		* $84
TK_DIM		EQU TK_INPUT+1		* $85
TK_READ		EQU TK_DIM+1		* $86
TK_LET		EQU TK_READ+1		* $87
TK_DEC		EQU TK_LET+1		* $88
TK_GOTO		EQU TK_DEC+1		* $89
TK_RUN		EQU TK_GOTO+1		* $8A
TK_IF			EQU TK_RUN+1		* $8B
TK_RESTORE		EQU TK_IF+1			* $8C
TK_GOSUB		EQU TK_RESTORE+1		* $8D
TK_RETURN		EQU TK_GOSUB+1		* $8E
TK_REM		EQU TK_RETURN+1		* $8F
TK_STOP		EQU TK_REM+1		* $90
TK_ON			EQU TK_STOP+1		* $91
TK_NULL		EQU TK_ON+1			* $92
TK_INC		EQU TK_NULL+1		* $93
TK_WAIT		EQU TK_INC+1		* $94
TK_LOAD		EQU TK_WAIT+1		* $95
TK_SAVE		EQU TK_LOAD+1		* $96
TK_DEF		EQU TK_SAVE+1		* $97
TK_POKE		EQU TK_DEF+1		* $98
TK_DOKE		EQU TK_POKE+1		* $99
TK_LOKE		EQU TK_DOKE+1		* $9A
TK_CALL		EQU TK_LOKE+1		* $9B
TK_DO			EQU TK_CALL+1		* $9C
TK_LOOP		EQU TK_DO+1			* $9D
TK_PRINT		EQU TK_LOOP+1		* $9E
TK_CONT		EQU TK_PRINT+1		* $9F
TK_LIST		EQU TK_CONT+1		* $A0
TK_CLEAR		EQU TK_LIST+1		* $A1
TK_NEW		EQU TK_CLEAR+1		* $A2
TK_WIDTH		EQU TK_NEW+1		* $A3
TK_GET		EQU TK_WIDTH+1		* $A4
TK_SWAP		EQU TK_GET+1		* $A5
TK_BITSET		EQU TK_SWAP+1		* $A6
TK_BITCLR		EQU TK_BITSET+1		* $A7
TK_TAB		EQU TK_BITCLR+1		* $A8
TK_ELSE		EQU TK_TAB+1		* $A9
TK_TO			EQU TK_ELSE+1		* $AA
TK_FN			EQU TK_TO+1			* $AB
TK_SPC		EQU TK_FN+1			* $AC
TK_THEN		EQU TK_SPC+1		* $AD
TK_NOT		EQU TK_THEN+1		* $AE
TK_STEP		EQU TK_NOT+1		* $AF
TK_UNTIL		EQU TK_STEP+1		* $B0
TK_WHILE		EQU TK_UNTIL+1		* $B1
TK_PLUS		EQU TK_WHILE+1		* $B2
TK_MINUS		EQU TK_PLUS+1		* $B3
TK_MULT		EQU TK_MINUS+1		* $B4
TK_DIV		EQU TK_MULT+1		* $B5
TK_POWER		EQU TK_DIV+1		* $B6
TK_AND		EQU TK_POWER+1		* $B7
TK_EOR		EQU TK_AND+1		* $B8
TK_OR			EQU TK_EOR+1		* $B9
TK_RSHIFT		EQU TK_OR+1			* $BA
TK_LSHIFT		EQU TK_RSHIFT+1		* $BB
TK_GT			EQU TK_LSHIFT+1		* $BC
TK_EQUAL		EQU TK_GT+1			* $BD
TK_LT			EQU TK_EQUAL+1		* $BE
TK_SGN		EQU TK_LT+1			* $BF
TK_INT		EQU TK_SGN+1		* $C0
TK_ABS		EQU TK_INT+1		* $C1
TK_USR		EQU TK_ABS+1		* $C2
TK_FRE		EQU TK_USR+1		* $C3
TK_POS		EQU TK_FRE+1		* $C4
TK_SQR		EQU TK_POS+1		* $C5
TK_RND		EQU TK_SQR+1		* $C6
TK_LOG		EQU TK_RND+1		* $C7
TK_EXP		EQU TK_LOG+1		* $C8
TK_COS		EQU TK_EXP+1		* $C9
TK_SIN		EQU TK_COS+1		* $CA
TK_TAN		EQU TK_SIN+1		* $CB
TK_ATN		EQU TK_TAN+1		* $CC
TK_PEEK		EQU TK_ATN+1		* $CD
TK_DEEK		EQU TK_PEEK+1		* $CE
TK_LEEK		EQU TK_DEEK+1		* $CF
TK_LEN		EQU TK_LEEK+1		* $D0
TK_STRS		EQU TK_LEN+1		* $D1
TK_VAL		EQU TK_STRS+1		* $D2
TK_ASC		EQU TK_VAL+1		* $D3
TK_UCASES		EQU TK_ASC+1		* $D4
TK_LCASES		EQU TK_UCASES+1		* $D5
TK_CHRS		EQU TK_LCASES+1		* $D6
TK_HEXS		EQU TK_CHRS+1		* $D7
TK_BINS		EQU TK_HEXS+1		* $D8
TK_BITTST		EQU TK_BINS+1		* $D9
TK_MAX		EQU TK_BITTST+1		* $DA
TK_MIN		EQU TK_MAX+1		* $DB
TK_RAM		EQU TK_MIN+1		* $DC
TK_PI			EQU TK_RAM+1		* $DD
TK_TWOPI		EQU TK_PI+1			* $DE
TK_VPTR		EQU TK_TWOPI+1		* $DF
TK_SADD		EQU TK_VPTR+1		* $E0
TK_LEFTS		EQU TK_SADD+1		* $E1
TK_RIGHTS		EQU TK_LEFTS+1		* $E2
TK_MIDS		EQU TK_RIGHTS+1		* $E3
TK_USINGS		EQU TK_MIDS+1		* $E4


*************************************************************************************
*
* binary to unsigned decimal table

Bin2dec
	dc.l	$3B9ACA00				* 1000000000
	dc.l	$05F5E100				* 100000000
	dc.l	$00989680				* 10000000
	dc.l	$000F4240				* 1000000
	dc.l	$000186A0				* 100000
	dc.l	$00002710				* 10000
	dc.l	$000003E8				* 1000
	dc.l	$00000064				* 100
	dc.l	$0000000A				* 10
	dc.l	$00000000				* 0 end marker

LAB_RSED
	dc.l	$332E3232				* 858665522

* string to value exponent table

	dc.w	255<<8				* 10**38
	dc.l	$96769951
	dc.w	251<<8				* 10**37
	dc.l	$F0BDC21B
	dc.w	248<<8				* 10**36
	dc.l	$C097CE7C
	dc.w	245<<8				* 10**35
	dc.l	$9A130B96
	dc.w	241<<8				* 10**34
	dc.l	$F684DF57
	dc.w	238<<8				* 10**33
	dc.l	$C5371912
	dc.w	235<<8				* 10**32
	dc.l	$9DC5ADA8
	dc.w	231<<8				* 10**31
	dc.l	$FC6F7C40
	dc.w	228<<8				* 10**30
	dc.l	$C9F2C9CD
	dc.w	225<<8				* 10**29
	dc.l	$A18F07D7
	dc.w	222<<8				* 10**28
	dc.l	$813F3979
	dc.w	218<<8				* 10**27
	dc.l	$CECB8F28
	dc.w	215<<8				* 10**26
	dc.l	$A56FA5BA
	dc.w	212<<8				* 10**25
	dc.l	$84595161
	dc.w	208<<8				* 10**24
	dc.l	$D3C21BCF
	dc.w	205<<8				* 10**23
	dc.l	$A968163F
	dc.w	202<<8				* 10**22
	dc.l	$87867832
	dc.w	198<<8				* 10**21
	dc.l	$D8D726B7
	dc.w	195<<8				* 10**20
	dc.l	$AD78EBC6
	dc.w	192<<8				* 10**19
	dc.l	$8AC72305
	dc.w	188<<8				* 10**18
	dc.l	$DE0B6B3A
	dc.w	185<<8				* 10**17
	dc.l	$B1A2BC2F
	dc.w	182<<8				* 10**16
	dc.l	$8E1BC9BF
	dc.w	178<<8				* 10**15
	dc.l	$E35FA932
	dc.w	175<<8				* 10**14
	dc.l	$B5E620F5
	dc.w	172<<8				* 10**13
	dc.l	$9184E72A
	dc.w	168<<8				* 10**12
	dc.l	$E8D4A510
	dc.w	165<<8				* 10**11
	dc.l	$BA43B740
	dc.w	162<<8				* 10**10
	dc.l	$9502F900
	dc.w	158<<8				* 10**9
	dc.l	$EE6B2800
	dc.w	155<<8				* 10**8
	dc.l	$BEBC2000
	dc.w	152<<8				* 10**7
	dc.l	$98968000
	dc.w	148<<8				* 10**6
	dc.l	$F4240000
	dc.w	145<<8				* 10**5
	dc.l	$C3500000
	dc.w	142<<8				* 10**4
	dc.l	$9C400000
	dc.w	138<<8				* 10**3
	dc.l	$FA000000
	dc.w	135<<8				* 10**2
	dc.l	$C8000000
	dc.w	132<<8				* 10**1
	dc.l	$A0000000
LAB_P_10
	dc.w	129<<8				* 10**0
	dc.l	$80000000
	dc.w	125<<8				* 10**-1
	dc.l	$CCCCCCCD
	dc.w	122<<8				* 10**-2
	dc.l	$A3D70A3D
	dc.w	119<<8				* 10**-3
	dc.l	$83126E98
	dc.w	115<<8				* 10**-4
	dc.l	$D1B71759
	dc.w	112<<8				* 10**-5
	dc.l	$A7C5AC47
	dc.w	109<<8				* 10**-6
	dc.l	$8637BD06
	dc.w	105<<8				* 10**-7
	dc.l	$D6BF94D6
	dc.w	102<<8				* 10**-8
	dc.l	$ABCC7712
	dc.w	99<<8					* 10**-9
	dc.l	$89705F41
	dc.w	95<<8					* 10**-10
	dc.l	$DBE6FECF
	dc.w	92<<8					* 10**-11
	dc.l	$AFEBFF0C
	dc.w	89<<8					* 10**-12
	dc.l	$8CBCCC09
	dc.w	85<<8					* 10**-13
	dc.l	$E12E1342
	dc.w	82<<8					* 10**-14
	dc.l	$B424DC35
	dc.w	79<<8					* 10**-15
	dc.l	$901D7CF7
	dc.w	75<<8					* 10**-16
	dc.l	$E69594BF
	dc.w	72<<8					* 10**-17
	dc.l	$B877AA32
	dc.w	69<<8					* 10**-18
	dc.l	$9392EE8F
	dc.w	65<<8					* 10**-19
	dc.l	$EC1E4A7E
	dc.w	62<<8					* 10**-20
	dc.l	$BCE50865
	dc.w	59<<8					* 10**-21
	dc.l	$971DA050
	dc.w	55<<8					* 10**-22
	dc.l	$F1C90081
	dc.w	52<<8					* 10**-23
	dc.l	$C16D9A01
	dc.w	49<<8					* 10**-24
	dc.l	$9ABE14CD
	dc.w	45<<8					* 10**-25
	dc.l	$F79687AE
	dc.w	42<<8					* 10**-26
	dc.l	$C6120625
	dc.w	39<<8					* 10**-27
	dc.l	$9E74D1B8
	dc.w	35<<8					* 10**-28
	dc.l	$FD87B5F3
	dc.w	32<<8					* 10**-29
	dc.l	$CAD2F7F5
	dc.w	29<<8					* 10**-30
	dc.l	$A2425FF7
	dc.w	26<<8					* 10**-31
	dc.l	$81CEB32C
	dc.w	22<<8					* 10**-32
	dc.l	$CFB11EAD
	dc.w	19<<8					* 10**-33
	dc.l	$A6274BBE
	dc.w	16<<8					* 10**-34
	dc.l	$84EC3C98
	dc.w	12<<8					* 10**-35
	dc.l	$D4AD2DC0
	dc.w	9<<8					* 10**-36
	dc.l	$AA242499
	dc.w	6<<8					* 10**-37
	dc.l	$881CEA14
	dc.w	2<<8					* 10**-38
	dc.l	$D9C7DCED


*************************************************************************************
*
* table of constants for cordic SIN/COS/TAN calculations
* constants are un normalised fractions and are atn(2^-i)/2pi

	dc.l	$4DBA76D4				* SIN/COS multiply constant
TAB_SNCO
	dc.l	$20000000				* atn(2^0)/2pi
	dc.l	$12E4051E				* atn(2^1)/2pi
	dc.l	$09FB385C				* atn(2^2)/2pi
	dc.l	$051111D5				* atn(2^3)/2pi
	dc.l	$028B0D44				* atn(2^4)/2pi
	dc.l	$0145D7E2				* atn(2^5)/2pi
	dc.l	$00A2F61F				* atn(2^6)/2pi
	dc.l	$00517C56				* atn(2^7)/2pi
	dc.l	$0028BE54				* atn(2^8)/2pi
	dc.l	$00145F2F				* atn(2^9)/2pi
	dc.l	$000A2F99				* atn(2^10)/2pi
	dc.l	$000517CD				* atn(2^11)/2pi
	dc.l	$00028BE7				* atn(2^12)/2pi
	dc.l	$000145F4				* atn(2^13)/2pi
	dc.l	$0000A2FA				* atn(2^14)/2pi
	dc.l	$0000517D				* atn(2^15)/2pi
	dc.l	$000028BF				* atn(2^16)/2pi
	dc.l	$00001460				* atn(2^17)/2pi
	dc.l	$00000A30				* atn(2^18)/2pi
	dc.l	$00000518				* atn(2^19)/2pi
	dc.l	$0000028C				* atn(2^20)/2pi
	dc.l	$00000146				* atn(2^21)/2pi
	dc.l	$000000A3				* atn(2^22)/2pi
	dc.l	$00000052				* atn(2^23)/2pi
	dc.l	$00000029				* atn(2^24)/2pi
	dc.l	$00000015				* atn(2^25)/2pi
	dc.l	$0000000B				* atn(2^26)/2pi
	dc.l	$00000006				* atn(2^27)/2pi
	dc.l	$00000003				* atn(2^28)/2pi
	dc.l	$00000002				* atn(2^29)/2pi
	dc.l	$00000001				* atn(2^30)/2pi
	dc.l	$00000001				* atn(2^31)/2pi


*************************************************************************************
*
* table of constants for cordic ATN calculation
* constants are normalised to two integer bits and are atn(2^-i)

TAB_ATNC
	dc.l	$1DAC6705				* atn(2^-1)
	dc.l	$0FADBAFD				* atn(2^-2)
	dc.l	$07F56EA7				* atn(2^-3)
	dc.l	$03FEAB77				* atn(2^-4)
	dc.l	$01FFD55C				* atn(2^-5)
	dc.l	$00FFFAAB				* atn(2^-6)
	dc.l	$007FFF55				* atn(2^-7)
	dc.l	$003FFFEB				* atn(2^-8)
	dc.l	$001FFFFD				* atn(2^-9)
	dc.l	$00100000				* atn(2^-10)
	dc.l	$00080000				* atn(2^-11)
	dc.l	$00040000				* atn(2^-12)
	dc.l	$00020000				* atn(2^-13)
	dc.l	$00010000				* atn(2^-14)
	dc.l	$00008000				* atn(2^-15)
	dc.l	$00004000				* atn(2^-16)
	dc.l	$00002000				* atn(2^-17)
	dc.l	$00001000				* atn(2^-18)
	dc.l	$00000800				* atn(2^-19)
	dc.l	$00000400				* atn(2^-20)
	dc.l	$00000200				* atn(2^-21)
	dc.l	$00000100				* atn(2^-22)
	dc.l	$00000080				* atn(2^-23)
	dc.l	$00000040				* atn(2^-24)
	dc.l	$00000020				* atn(2^-25)
	dc.l	$00000010				* atn(2^-26)
	dc.l	$00000008				* atn(2^-27)
	dc.l	$00000004				* atn(2^-28)
	dc.l	$00000002				* atn(2^-29)
	dc.l	$00000001				* atn(2^-30)
LAB_1D96
	dc.l	$00000000				* atn(2^-31)
	dc.l	$00000000				* atn(2^-32)

* constants are normalised to n integer bits and are tanh(2^-i)
n	equ	2
TAB_HTHET
	dc.l	$8C9F53D0>>n			* atnh(2^-1)	.549306144
	dc.l	$4162BBE8>>n			* atnh(2^-2)	.255412812
	dc.l	$202B1238>>n			* atnh(2^-3)
	dc.l	$10055888>>n			* atnh(2^-4)
	dc.l	$0800AAC0>>n			* atnh(2^-5)
	dc.l	$04001550>>n			* atnh(2^-6)
	dc.l	$020002A8>>n			* atnh(2^-7)
	dc.l	$01000050>>n			* atnh(2^-8)
	dc.l	$00800008>>n			* atnh(2^-9)
	dc.l	$00400000>>n			* atnh(2^-10)
	dc.l	$00200000>>n			* atnh(2^-11)
	dc.l	$00100000>>n			* atnh(2^-12)
	dc.l	$00080000>>n			* atnh(2^-13)
	dc.l	$00040000>>n			* atnh(2^-14)
	dc.l	$00020000>>n			* atnh(2^-15)
	dc.l	$00010000>>n			* atnh(2^-16)
	dc.l	$00008000>>n			* atnh(2^-17)
	dc.l	$00004000>>n			* atnh(2^-18)
	dc.l	$00002000>>n			* atnh(2^-19)
	dc.l	$00001000>>n			* atnh(2^-20)
	dc.l	$00000800>>n			* atnh(2^-21)
	dc.l	$00000400>>n			* atnh(2^-22)
	dc.l	$00000200>>n			* atnh(2^-23)
	dc.l	$00000100>>n			* atnh(2^-24)
	dc.l	$00000080>>n			* atnh(2^-25)
	dc.l	$00000040>>n			* atnh(2^-26)
	dc.l	$00000020>>n			* atnh(2^-27)
	dc.l	$00000010>>n			* atnh(2^-28)
	dc.l	$00000008>>n			* atnh(2^-29)
	dc.l	$00000004>>n			* atnh(2^-30)
	dc.l	$00000002>>n			* atnh(2^-31)
	dc.l	$00000001>>n			* atnh(2^-32)

KFCTSEED	equ	$9A8F4441>>n		* $26A3D110


*************************************************************************************
*
* command vector table

LAB_CTBL
	dc.w	LAB_END-LAB_CTBL			* END
	dc.w	LAB_FOR-LAB_CTBL			* FOR
	dc.w	LAB_NEXT-LAB_CTBL			* NEXT
	dc.w	LAB_DATA-LAB_CTBL			* DATA
	dc.w	LAB_INPUT-LAB_CTBL		* INPUT
	dc.w	LAB_DIM-LAB_CTBL			* DIM
	dc.w	LAB_READ-LAB_CTBL			* READ
	dc.w	LAB_LET-LAB_CTBL			* LET
	dc.w	LAB_DEC-LAB_CTBL			* DEC	
	dc.w	LAB_GOTO-LAB_CTBL			* GOTO
	dc.w	LAB_RUN-LAB_CTBL			* RUN
	dc.w	LAB_IF-LAB_CTBL			* IF
	dc.w	LAB_RESTORE-LAB_CTBL		* RESTORE
	dc.w	LAB_GOSUB-LAB_CTBL		* GOSUB
	dc.w	LAB_RETURN-LAB_CTBL		* RETURN
	dc.w	LAB_REM-LAB_CTBL			* REM
	dc.w	LAB_STOP-LAB_CTBL			* STOP
	dc.w	LAB_ON-LAB_CTBL			* ON
	dc.w	LAB_NULL-LAB_CTBL			* NULL
	dc.w	LAB_INC-LAB_CTBL			* INC	
	dc.w	LAB_WAIT-LAB_CTBL			* WAIT
	dc.w	LAB_LOAD-LAB_CTBL			* LOAD
	dc.w	LAB_SAVE-LAB_CTBL			* SAVE
	dc.w	LAB_DEF-LAB_CTBL			* DEF
	dc.w	LAB_POKE-LAB_CTBL			* POKE
	dc.w	LAB_DOKE-LAB_CTBL			* DOKE
	dc.w	LAB_LOKE-LAB_CTBL			* LOKE
	dc.w	LAB_CALL-LAB_CTBL			* CALL
	dc.w	LAB_DO-LAB_CTBL			* DO	
	dc.w	LAB_LOOP-LAB_CTBL			* LOOP
	dc.w	LAB_PRINT-LAB_CTBL		* PRINT
	dc.w	LAB_CONT-LAB_CTBL			* CONT
	dc.w	LAB_LIST-LAB_CTBL			* LIST
	dc.w	LAB_CLEAR-LAB_CTBL		* CLEAR
	dc.w	LAB_NEW-LAB_CTBL			* NEW
	dc.w	LAB_WDTH-LAB_CTBL			* WIDTH
	dc.w	LAB_GET-LAB_CTBL			* GET
	dc.w	LAB_SWAP-LAB_CTBL			* SWAP
	dc.w	LAB_BITSET-LAB_CTBL		* BITSET
	dc.w	LAB_BITCLR-LAB_CTBL		* BITCLR


*************************************************************************************
*
* function pre process routine table

LAB_FTPP
	dc.w	LAB_PPFN-LAB_FTPP			* SGN(n)	process numeric expression in ()
	dc.w	LAB_PPFN-LAB_FTPP			* INT(n)		"
	dc.w	LAB_PPFN-LAB_FTPP			* ABS(n)		"
	dc.w	LAB_EVEZ-LAB_FTPP			* USR(x)	process any expression
	dc.w	LAB_1BF7-LAB_FTPP			* FRE(x)	process any expression in ()
	dc.w	LAB_1BF7-LAB_FTPP			* POS(x)		"
	dc.w	LAB_PPFN-LAB_FTPP			* SQR(n)	process numeric expression in ()
	dc.w	LAB_PPFN-LAB_FTPP			* RND(n)		"
	dc.w	LAB_PPFN-LAB_FTPP			* LOG(n)		"
	dc.w	LAB_PPFN-LAB_FTPP			* EXP(n)		"
	dc.w	LAB_PPFN-LAB_FTPP			* COS(n)		"
	dc.w	LAB_PPFN-LAB_FTPP			* SIN(n)		"
	dc.w	LAB_PPFN-LAB_FTPP			* TAN(n)		"
	dc.w	LAB_PPFN-LAB_FTPP			* ATN(n)		"
	dc.w	LAB_PPFN-LAB_FTPP			* PEEK(n)		"
	dc.w	LAB_PPFN-LAB_FTPP			* DEEK(n)		"
	dc.w	LAB_PPFN-LAB_FTPP			* LEEK(n)		"
	dc.w	LAB_PPFS-LAB_FTPP			* LEN($)	process string expression in ()
	dc.w	LAB_PPFN-LAB_FTPP			* STR$(n)	process numeric expression in ()
	dc.w	LAB_PPFS-LAB_FTPP			* VAL($)	process string expression in ()
	dc.w	LAB_PPFS-LAB_FTPP			* ASC($)		"
	dc.w	LAB_PPFS-LAB_FTPP			* UCASE$($)		"
	dc.w	LAB_PPFS-LAB_FTPP			* LCASE$($)		"
	dc.w	LAB_PPFN-LAB_FTPP			* CHR$(n)	process numeric expression in ()
	dc.w	LAB_BHSS-LAB_FTPP			* HEX$()	bin/hex pre process
	dc.w	LAB_BHSS-LAB_FTPP			* BIN$()		"
	dc.w	$0000					* BITTST()	none
	dc.w	$0000					* MAX()		"
	dc.w	$0000					* MIN()		"
	dc.w	LAB_PPBI-LAB_FTPP			* RAMBASE	advance pointer
	dc.w	LAB_PPBI-LAB_FTPP			* PI			"
	dc.w	LAB_PPBI-LAB_FTPP			* TWOPI		"
	dc.w	$0000					* VARPTR()	none
	dc.w	$0000					* SADD()		"
	dc.w	LAB_LRMS-LAB_FTPP			* LEFT$()	process string expression
	dc.w	LAB_LRMS-LAB_FTPP			* RIGHT$()		"
	dc.w	LAB_LRMS-LAB_FTPP			* MID$()		"
	dc.w	LAB_EVEZ-LAB_FTPP			* USING$(x)	process any expression


*************************************************************************************
*
* action addresses for functions

LAB_FTBL
	dc.w	LAB_SGN-LAB_FTBL			* SGN()
	dc.w	LAB_INT-LAB_FTBL			* INT()
	dc.w	LAB_ABS-LAB_FTBL			* ABS()
	dc.w	LAB_USR-LAB_FTBL			* USR()
	dc.w	LAB_FRE-LAB_FTBL			* FRE()
	dc.w	LAB_POS-LAB_FTBL			* POS()
	dc.w	LAB_SQR-LAB_FTBL			* SQR()
	dc.w	LAB_RND-LAB_FTBL			* RND()
	dc.w	LAB_LOG-LAB_FTBL			* LOG()
	dc.w	LAB_EXP-LAB_FTBL			* EXP()
	dc.w	LAB_COS-LAB_FTBL			* COS()
	dc.w	LAB_SIN-LAB_FTBL			* SIN()
	dc.w	LAB_TAN-LAB_FTBL			* TAN()
	dc.w	LAB_ATN-LAB_FTBL			* ATN()
	dc.w	LAB_PEEK-LAB_FTBL			* PEEK()
	dc.w	LAB_DEEK-LAB_FTBL			* DEEK()
	dc.w	LAB_LEEK-LAB_FTBL			* LEEK()
	dc.w	LAB_LENS-LAB_FTBL			* LEN()
	dc.w	LAB_STRS-LAB_FTBL			* STR$()
	dc.w	LAB_VAL-LAB_FTBL			* VAL()
	dc.w	LAB_ASC-LAB_FTBL			* ASC()
	dc.w	LAB_UCASE-LAB_FTBL		* UCASE$()
	dc.w	LAB_LCASE-LAB_FTBL		* LCASE$()
	dc.w	LAB_CHRS-LAB_FTBL			* CHR$()
	dc.w	LAB_HEXS-LAB_FTBL			* HEX$()
	dc.w	LAB_BINS-LAB_FTBL			* BIN$()
	dc.w	LAB_BTST-LAB_FTBL			* BITTST()
	dc.w	LAB_MAX-LAB_FTBL			* MAX()
	dc.w	LAB_MIN-LAB_FTBL			* MIN()
	dc.w	LAB_RAM-LAB_FTBL			* RAMBASE
	dc.w	LAB_PI-LAB_FTBL			* PI
	dc.w	LAB_TWOPI-LAB_FTBL		* TWOPI
	dc.w	LAB_VARPTR-LAB_FTBL		* VARPTR()
	dc.w	LAB_SADD-LAB_FTBL			* SADD()
	dc.w	LAB_LEFT-LAB_FTBL			* LEFT$()
	dc.w	LAB_RIGHT-LAB_FTBL		* RIGHT$()
	dc.w	LAB_MIDS-LAB_FTBL			* MID$()
	dc.w	LAB_USINGS-LAB_FTBL		* USING$()


*************************************************************************************
*
* hierarchy and action addresses for operator

LAB_OPPT
	dc.w	$0079					* +
	dc.w	LAB_ADD-LAB_OPPT
	dc.w	$0079					* -
	dc.w	LAB_SUBTRACT-LAB_OPPT
	dc.w	$007B					* *
	dc.w	LAB_MULTIPLY-LAB_OPPT
	dc.w	$007B					* /
	dc.w	LAB_DIVIDE-LAB_OPPT
	dc.w	$007F					* ^
	dc.w	LAB_POWER-LAB_OPPT
	dc.w	$0050					* AND
	dc.w	LAB_AND-LAB_OPPT
	dc.w	$0046					* EOR
	dc.w	LAB_EOR-LAB_OPPT
	dc.w	$0046					* OR
	dc.w	LAB_OR-LAB_OPPT
	dc.w	$0056					* >>
	dc.w	LAB_RSHIFT-LAB_OPPT
	dc.w	$0056					* <<
	dc.w	LAB_LSHIFT-LAB_OPPT
	dc.w	$007D					* >
	dc.w	LAB_GTHAN-LAB_OPPT		* used to evaluate -n
	dc.w	$005A					* =
	dc.w	LAB_EQUAL-LAB_OPPT		* used to evaluate NOT
	dc.w	$0064					* <
	dc.w	LAB_LTHAN-LAB_OPPT


*************************************************************************************
*
* misc constants

* This table is used in converting numbers to ASCII.
* first four entries for expansion to 9.25 digits

LAB_2A9A
	dc.l	$FFF0BDC0				* -1000000
	dc.l	$000186A0				* 100000
	dc.l	$FFFFD8F0				* -10000
	dc.l	$000003E8				* 1000
	dc.l	$FFFFFF9C				* -100
	dc.l	$0000000A				* 10
	dc.l	$FFFFFFFF				* -1
LAB_2A9B


*************************************************************************************
*
* new keyword tables

* offsets to keyword tables

TAB_CHRT
	dc.w	TAB_STAR-TAB_STAR			* "*"	$2A
	dc.w	TAB_PLUS-TAB_STAR			* "+"	$2B
	dc.w	-1					* "," $2C no keywords
	dc.w	TAB_MNUS-TAB_STAR			* "-"	$2D
	dc.w	-1					* "." $2E no keywords
	dc.w	TAB_SLAS-TAB_STAR			* "/"	$2F
	dc.w	-1					* "0" $30 no keywords
	dc.w	-1					* "1" $31 no keywords
	dc.w	-1					* "2" $32 no keywords
	dc.w	-1					* "3" $33 no keywords
	dc.w	-1					* "4" $34 no keywords
	dc.w	-1					* "5" $35 no keywords
	dc.w	-1					* "6" $36 no keywords
	dc.w	-1					* "7" $37 no keywords
	dc.w	-1					* "8" $38 no keywords
	dc.w	-1					* "9" $39 no keywords
	dc.w	-1					* ";" $3A no keywords
	dc.w	-1					* ":" $3B no keywords
	dc.w	TAB_LESS-TAB_STAR			* "<"	$3C
	dc.w	TAB_EQUL-TAB_STAR			* "="	$3D
	dc.w	TAB_MORE-TAB_STAR			* ">"	$3E
	dc.w	TAB_QEST-TAB_STAR			* "?"	$3F
	dc.w	-1					* "@" $40 no keywords
	dc.w	TAB_ASCA-TAB_STAR			* "A"	$41
	dc.w	TAB_ASCB-TAB_STAR			* "B"	$42
	dc.w	TAB_ASCC-TAB_STAR			* "C"	$43
	dc.w	TAB_ASCD-TAB_STAR			* "D"	$44
	dc.w	TAB_ASCE-TAB_STAR			* "E"	$45
	dc.w	TAB_ASCF-TAB_STAR			* "F"	$46
	dc.w	TAB_ASCG-TAB_STAR			* "G"	$47
	dc.w	TAB_ASCH-TAB_STAR			* "H"	$48
	dc.w	TAB_ASCI-TAB_STAR			* "I"	$49
	dc.w	-1					* "J" $4A no keywords
	dc.w	-1					* "K" $4B no keywords
	dc.w	TAB_ASCL-TAB_STAR			* "L"	$4C
	dc.w	TAB_ASCM-TAB_STAR			* "M"	$4D
	dc.w	TAB_ASCN-TAB_STAR			* "N"	$4E
	dc.w	TAB_ASCO-TAB_STAR			* "O"	$4F
	dc.w	TAB_ASCP-TAB_STAR			* "P"	$50
	dc.w	-1					* "Q" $51 no keywords
	dc.w	TAB_ASCR-TAB_STAR			* "R"	$52
	dc.w	TAB_ASCS-TAB_STAR			* "S"	$53
	dc.w	TAB_ASCT-TAB_STAR			* "T"	$54
	dc.w	TAB_ASCU-TAB_STAR			* "U"	$55
	dc.w	TAB_ASCV-TAB_STAR			* "V"	$56
	dc.w	TAB_ASCW-TAB_STAR			* "W"	$57
	dc.w	-1					* "X" $58 no keywords
	dc.w	-1					* "Y" $59 no keywords
	dc.w	-1					* "Z" $5A no keywords
	dc.w	-1					* "[" $5B no keywords
	dc.w	-1					* "\" $5C no keywords
	dc.w	-1					* "]" $5D no keywords
	dc.w	TAB_POWR-TAB_STAR			* "^"	$5E


*************************************************************************************
*
* Table of Basic keywords for LIST command
* [byte]first character,[byte]remaining length -1
* [word]offset from table start

LAB_KEYT
	dc.b	'E',1
	dc.w	KEY_END-TAB_STAR			* END
	dc.b	'F',1
	dc.w	KEY_FOR-TAB_STAR			* FOR
	dc.b	'N',2
	dc.w	KEY_NEXT-TAB_STAR			* NEXT
	dc.b	'D',2
	dc.w	KEY_DATA-TAB_STAR			* DATA
	dc.b	'I',3
	dc.w	KEY_INPUT-TAB_STAR		* INPUT
	dc.b	'D',1
	dc.w	KEY_DIM-TAB_STAR			* DIM
	dc.b	'R',2
	dc.w	KEY_READ-TAB_STAR			* READ
	dc.b	'L',1
	dc.w	KEY_LET-TAB_STAR			* LET
	dc.b	'D',1
	dc.w	KEY_DEC-TAB_STAR			* DEC
	dc.b	'G',2
	dc.w	KEY_GOTO-TAB_STAR			* GOTO
	dc.b	'R',1
	dc.w	KEY_RUN-TAB_STAR			* RUN
	dc.b	'I',0
	dc.w	KEY_IF-TAB_STAR			* IF
	dc.b	'R',5
	dc.w	KEY_RESTORE-TAB_STAR		* RESTORE
	dc.b	'G',3
	dc.w	KEY_GOSUB-TAB_STAR		* GOSUB
	dc.b	'R',4
	dc.w	KEY_RETURN-TAB_STAR		* RETURN
	dc.b	'R',1
	dc.w	KEY_REM-TAB_STAR			* REM
	dc.b	'S',2
	dc.w	KEY_STOP-TAB_STAR			* STOP
	dc.b	'O',0
	dc.w	KEY_ON-TAB_STAR			* ON
	dc.b	'N',2
	dc.w	KEY_NULL-TAB_STAR			* NULL
	dc.b	'I',1
	dc.w	KEY_INC-TAB_STAR			* INC
	dc.b	'W',2
	dc.w	KEY_WAIT-TAB_STAR			* WAIT
	dc.b	'L',2
	dc.w	KEY_LOAD-TAB_STAR			* LOAD
	dc.b	'S',2
	dc.w	KEY_SAVE-TAB_STAR			* SAVE
	dc.b	'D',1
	dc.w	KEY_DEF-TAB_STAR			* DEF
	dc.b	'P',2
	dc.w	KEY_POKE-TAB_STAR			* POKE
	dc.b	'D',2
	dc.w	KEY_DOKE-TAB_STAR			* DOKE
	dc.b	'L',2
	dc.w	KEY_LOKE-TAB_STAR			* LOKE
	dc.b	'C',2
	dc.w	KEY_CALL-TAB_STAR			* CALL
	dc.b	'D',0
	dc.w	KEY_DO-TAB_STAR			* DO
	dc.b	'L',2
	dc.w	KEY_LOOP-TAB_STAR			* LOOP
	dc.b	'P',3
	dc.w	KEY_PRINT-TAB_STAR		* PRINT
	dc.b	'C',2
	dc.w	KEY_CONT-TAB_STAR			* CONT
	dc.b	'L',2
	dc.w	KEY_LIST-TAB_STAR			* LIST
	dc.b	'C',3
	dc.w	KEY_CLEAR-TAB_STAR		* CLEAR
	dc.b	'N',1
	dc.w	KEY_NEW-TAB_STAR			* NEW
	dc.b	'W',3
	dc.w	KEY_WIDTH-TAB_STAR		* WIDTH
	dc.b	'G',1
	dc.w	KEY_GET-TAB_STAR			* GET
	dc.b	'S',2
	dc.w	KEY_SWAP-TAB_STAR			* SWAP
	dc.b	'B',4
	dc.w	KEY_BITSET-TAB_STAR		* BITSET
	dc.b	'B',4
	dc.w	KEY_BITCLR-TAB_STAR		* BITCLR
	dc.b	'T',2
	dc.w	KEY_TAB-TAB_STAR			* TAB(
	dc.b	'E',2
	dc.w	KEY_ELSE-TAB_STAR			* ELSE
	dc.b	'T',0
	dc.w	KEY_TO-TAB_STAR			* TO
	dc.b	'F',0
	dc.w	KEY_FN-TAB_STAR			* FN
	dc.b	'S',2
	dc.w	KEY_SPC-TAB_STAR			* SPC(
	dc.b	'T',2
	dc.w	KEY_THEN-TAB_STAR			* THEN
	dc.b	'N',1
	dc.w	KEY_NOT-TAB_STAR			* NOT
	dc.b	'S',2
	dc.w	KEY_STEP-TAB_STAR			* STEP
	dc.b	'U',3
	dc.w	KEY_UNTIL-TAB_STAR		* UNTIL
	dc.b	'W',3
	dc.w	KEY_WHILE-TAB_STAR		* WHILE

	dc.b	'+',-1
	dc.w	KEY_PLUS-TAB_STAR			* +
	dc.b	'-',-1
	dc.w	KEY_MINUS-TAB_STAR		* -
	dc.b	'*',-1
	dc.w	KEY_MULT-TAB_STAR			* *
	dc.b	'/',-1
	dc.w	KEY_DIV-TAB_STAR			* /
	dc.b	'^',-1
	dc.w	KEY_POWER-TAB_STAR		* ^
	dc.b	'A',1
	dc.w	KEY_AND-TAB_STAR			* AND
	dc.b	'E',1
	dc.w	KEY_EOR-TAB_STAR			* EOR
	dc.b	'O',0
	dc.w	KEY_OR-TAB_STAR			* OR
	dc.b	'>',0
	dc.w	KEY_RSHIFT-TAB_STAR		* >>
	dc.b	'<',0
	dc.w	KEY_LSHIFT-TAB_STAR		* <<
	dc.b	'>',-1
	dc.w	KEY_GT-TAB_STAR			* >
	dc.b	'=',-1
	dc.w	KEY_EQUAL-TAB_STAR		* =
	dc.b	'<',-1
	dc.w	KEY_LT-TAB_STAR			* <

	dc.b	'S',2
	dc.w	KEY_SGN-TAB_STAR			* SGN(
	dc.b	'I',2
	dc.w	KEY_INT-TAB_STAR			* INT(
	dc.b	'A',2
	dc.w	KEY_ABS-TAB_STAR			* ABS(
	dc.b	'U',2
	dc.w	KEY_USR-TAB_STAR			* USR(
	dc.b	'F',2
	dc.w	KEY_FRE-TAB_STAR			* FRE(
	dc.b	'P',2
	dc.w	KEY_POS-TAB_STAR			* POS(
	dc.b	'S',2
	dc.w	KEY_SQR-TAB_STAR			* SQR(
	dc.b	'R',2
	dc.w	KEY_RND-TAB_STAR			* RND(
	dc.b	'L',2
	dc.w	KEY_LOG-TAB_STAR			* LOG(
	dc.b	'E',2
	dc.w	KEY_EXP-TAB_STAR			* EXP(
	dc.b	'C',2
	dc.w	KEY_COS-TAB_STAR			* COS(
	dc.b	'S',2
	dc.w	KEY_SIN-TAB_STAR			* SIN(
	dc.b	'T',2
	dc.w	KEY_TAN-TAB_STAR			* TAN(
	dc.b	'A',2
	dc.w	KEY_ATN-TAB_STAR			* ATN(
	dc.b	'P',3
	dc.w	KEY_PEEK-TAB_STAR			* PEEK(
	dc.b	'D',3
	dc.w	KEY_DEEK-TAB_STAR			* DEEK(
	dc.b	'L',3
	dc.w	KEY_LEEK-TAB_STAR			* LEEK(
	dc.b	'L',2
	dc.w	KEY_LEN-TAB_STAR			* LEN(
	dc.b	'S',3
	dc.w	KEY_STRS-TAB_STAR			* STR$(
	dc.b	'V',2
	dc.w	KEY_VAL-TAB_STAR			* VAL(
	dc.b	'A',2
	dc.w	KEY_ASC-TAB_STAR			* ASC(
	dc.b	'U',5
	dc.w	KEY_UCASES-TAB_STAR		* UCASE$(
	dc.b	'L',5
	dc.w	KEY_LCASES-TAB_STAR		* LCASE$(
	dc.b	'C',3
	dc.w	KEY_CHRS-TAB_STAR			* CHR$(
	dc.b	'H',3
	dc.w	KEY_HEXS-TAB_STAR			* HEX$(
	dc.b	'B',3
	dc.w	KEY_BINS-TAB_STAR			* BIN$(
	dc.b	'B',5
	dc.w	KEY_BITTST-TAB_STAR		* BITTST(
	dc.b	'M',2
	dc.w	KEY_MAX-TAB_STAR			* MAX(
	dc.b	'M',2
	dc.w	KEY_MIN-TAB_STAR			* MIN(
	dc.b	'R',5
	dc.w	KEY_RAM-TAB_STAR			* RAMBASE
	dc.b	'P',0
	dc.w	KEY_PI-TAB_STAR			* PI
	dc.b	'T',3
	dc.w	KEY_TWOPI-TAB_STAR		* TWOPI
	dc.b	'V',5
	dc.w	KEY_VPTR-TAB_STAR			* VARPTR(
	dc.b	'S',3
	dc.w	KEY_SADD-TAB_STAR			* SADD(
	dc.b	'L',4
	dc.w	KEY_LEFTS-TAB_STAR		* LEFT$(
	dc.b	'R',5
	dc.w	KEY_RIGHTS-TAB_STAR		* RIGHT$(
	dc.b	'M',3
	dc.w	KEY_MIDS-TAB_STAR			* MID$(
	dc.b	'U',5
	dc.w	KEY_USINGS-TAB_STAR		* USING$(


*************************************************************************************
*
* BASIC error messages

LAB_BAER
	dc.w	LAB_NF-LAB_BAER			* $00 NEXT without FOR
	dc.w	LAB_SN-LAB_BAER			* $02 syntax
	dc.w	LAB_RG-LAB_BAER			* $04 RETURN without GOSUB
	dc.w	LAB_OD-LAB_BAER			* $06 out of data
	dc.w	LAB_FC-LAB_BAER			* $08 function call
	dc.w	LAB_OV-LAB_BAER			* $0A overflow
	dc.w	LAB_OM-LAB_BAER			* $0C out of memory
	dc.w	LAB_US-LAB_BAER			* $0E undefined statement
	dc.w	LAB_BS-LAB_BAER			* $10 array bounds
	dc.w	LAB_DD-LAB_BAER			* $12 double dimension array
	dc.w	LAB_D0-LAB_BAER			* $14 divide by 0
	dc.w	LAB_ID-LAB_BAER			* $16 illegal direct
	dc.w	LAB_TM-LAB_BAER			* $18 type mismatch
	dc.w	LAB_LS-LAB_BAER			* $1A long string
	dc.w	LAB_ST-LAB_BAER			* $1C string too complex
	dc.w	LAB_CN-LAB_BAER			* $1E continue error
	dc.w	LAB_UF-LAB_BAER			* $20 undefined function
	dc.w	LAB_LD-LAB_BAER			* $22 LOOP without DO
	dc.w	LAB_UV-LAB_BAER			* $24 undefined variable
	dc.w	LAB_UA-LAB_BAER			* $26 undimensioned array
	dc.w	LAB_WD-LAB_BAER			* $28 wrong dimensions
	dc.w	LAB_AD-LAB_BAER			* $2A address
	dc.w	LAB_FO-LAB_BAER			* $2C format
	dc.w	LAB_NI-LAB_BAER			* $2E not implemented

LAB_NF	dc.b	'NEXT without FOR',$00
LAB_SN	dc.b	'Syntax',$00
LAB_RG	dc.b	'RETURN without GOSUB',$00
LAB_OD	dc.b	'Out of DATA',$00
LAB_FC	dc.b	'Function call',$00
LAB_OV	dc.b	'Overflow',$00
LAB_OM	dc.b	'Out of memory',$00
LAB_US	dc.b	'Undefined statement',$00
LAB_BS	dc.b	'Array bounds',$00
LAB_DD	dc.b	'Double dimension',$00
LAB_D0	dc.b	'Divide by zero',$00
LAB_ID	dc.b	'Illegal direct',$00
LAB_TM	dc.b	'Type mismatch',$00
LAB_LS	dc.b	'String too long',$00
LAB_ST	dc.b	'String too complex',$00
LAB_CN	dc.b	'Can''t continue',$00
LAB_UF	dc.b	'Undefined function',$00
LAB_LD	dc.b	'LOOP without DO',$00
LAB_UV	dc.b	'Undefined variable',$00
LAB_UA	dc.b	'Undimensioned array',$00
LAB_WD	dc.b	'Wrong dimensions',$00
LAB_AD	dc.b	'Address',$00
LAB_FO	dc.b	'Format',$00
LAB_NI  dc.b    'Not implemented',$00


*************************************************************************************
*
* keyword table for line (un)crunching

* [keyword,token
* [keyword,token]]
* end marker (#$00)

TAB_STAR
KEY_MULT
	dc.b TK_MULT,$00				* *
TAB_PLUS
KEY_PLUS
	dc.b TK_PLUS,$00				* +
TAB_MNUS
KEY_MINUS
	dc.b TK_MINUS,$00				* -
TAB_SLAS
KEY_DIV
	dc.b TK_DIV,$00				* /
TAB_LESS
KEY_LSHIFT
	dc.b	'<',TK_LSHIFT			* <<
KEY_LT
	dc.b TK_LT					* <
	dc.b	$00
TAB_EQUL
KEY_EQUAL
	dc.b TK_EQUAL,$00				* =
TAB_MORE
KEY_RSHIFT
	dc.b	'>',TK_RSHIFT			* >>
KEY_GT
	dc.b TK_GT					* >
	dc.b	$00
TAB_QEST
	dc.b TK_PRINT,$00				* ?
TAB_ASCA
KEY_ABS
	dc.b	'BS(',TK_ABS			* ABS(
KEY_AND
	dc.b	'ND',TK_AND				* AND
KEY_ASC
	dc.b	'SC(',TK_ASC			* ASC(
KEY_ATN
	dc.b	'TN(',TK_ATN			* ATN(
	dc.b	$00
TAB_ASCB
KEY_BINS
	dc.b	'IN$(',TK_BINS			* BIN$(
KEY_BITCLR
	dc.b	'ITCLR',TK_BITCLR			* BITCLR
KEY_BITSET
	dc.b	'ITSET',TK_BITSET			* BITSET
KEY_BITTST
	dc.b	'ITTST(',TK_BITTST		* BITTST(
	dc.b	$00
TAB_ASCC
KEY_CALL
	dc.b	'ALL',TK_CALL			* CALL
KEY_CHRS
	dc.b	'HR$(',TK_CHRS			* CHR$(
KEY_CLEAR
	dc.b	'LEAR',TK_CLEAR			* CLEAR
KEY_CONT
	dc.b	'ONT',TK_CONT			* CONT
KEY_COS
	dc.b	'OS(',TK_COS			* COS(
	dc.b	$00
TAB_ASCD
KEY_DATA
	dc.b	'ATA',TK_DATA			* DATA
KEY_DEC
	dc.b	'EC',TK_DEC				* DEC
KEY_DEEK
	dc.b	'EEK(',TK_DEEK			* DEEK(
KEY_DEF
	dc.b	'EF',TK_DEF				* DEF
KEY_DIM
	dc.b	'IM',TK_DIM				* DIM
KEY_DOKE
	dc.b	'OKE',TK_DOKE			* DOKE
KEY_DO
	dc.b	'O',TK_DO				* DO
	dc.b	$00
TAB_ASCE
KEY_ELSE
	dc.b	'LSE',TK_ELSE			* ELSE
KEY_END
	dc.b	'ND',TK_END				* END
KEY_EOR
	dc.b	'OR',TK_EOR				* EOR
KEY_EXP
	dc.b	'XP(',TK_EXP			* EXP(
	dc.b	$00
TAB_ASCF
KEY_FOR
	dc.b	'OR',TK_FOR				* FOR
KEY_FN
	dc.b	'N',TK_FN				* FN
KEY_FRE
	dc.b	'RE(',TK_FRE			* FRE(
	dc.b	$00
TAB_ASCG
KEY_GET
	dc.b	'ET',TK_GET				* GET
KEY_GOTO
	dc.b	'OTO',TK_GOTO			* GOTO
KEY_GOSUB
	dc.b	'OSUB',TK_GOSUB			* GOSUB
	dc.b	$00
TAB_ASCH
KEY_HEXS
	dc.b	'EX$(',TK_HEXS,$00		* HEX$(
TAB_ASCI
KEY_IF
	dc.b	'F',TK_IF				* IF
KEY_INC
	dc.b	'NC',TK_INC				* INC
KEY_INPUT
	dc.b	'NPUT',TK_INPUT			* INPUT
KEY_INT
	dc.b	'NT(',TK_INT			* INT(
	dc.b	$00
TAB_ASCL
KEY_LCASES
	dc.b	'CASE$(',TK_LCASES		* LCASE$(
KEY_LEEK
	dc.b	'EEK(',TK_LEEK			* LEEK(
KEY_LEFTS
	dc.b	'EFT$(',TK_LEFTS			* LEFT$(
KEY_LEN
	dc.b	'EN(',TK_LEN			* LEN(
KEY_LET
	dc.b	'ET',TK_LET				* LET
KEY_LIST
	dc.b	'IST',TK_LIST			* LIST
KEY_LOAD
	dc.b	'OAD',TK_LOAD			* LOAD
KEY_LOG
	dc.b	'OG(',TK_LOG			* LOG(
KEY_LOKE
	dc.b	'OKE',TK_LOKE			* LOKE
KEY_LOOP
	dc.b	'OOP',TK_LOOP			* LOOP
	dc.b	$00
TAB_ASCM
KEY_MAX
	dc.b	'AX(',TK_MAX			* MAX(
KEY_MIDS
	dc.b	'ID$(',TK_MIDS			* MID$(
KEY_MIN
	dc.b	'IN(',TK_MIN			* MIN(
	dc.b	$00
TAB_ASCN
KEY_NEW
	dc.b	'EW',TK_NEW				* NEW
KEY_NEXT
	dc.b	'EXT',TK_NEXT			* NEXT
KEY_NOT
	dc.b	'OT',TK_NOT				* NOT
KEY_NULL
	dc.b	'ULL',TK_NULL			* NULL
	dc.b	$00
TAB_ASCO
KEY_ON
	dc.b	'N',TK_ON				* ON
KEY_OR
	dc.b	'R',TK_OR				* OR
	dc.b	$00
TAB_ASCP
KEY_PEEK
	dc.b	'EEK(',TK_PEEK			* PEEK(
KEY_PI
	dc.b	'I',TK_PI				* PI
KEY_POKE
	dc.b	'OKE',TK_POKE			* POKE
KEY_POS
	dc.b	'OS(',TK_POS			* POS(
KEY_PRINT
	dc.b	'RINT',TK_PRINT			* PRINT
	dc.b	$00
TAB_ASCR
KEY_RAM
	dc.b	'AMBASE',TK_RAM			* RAMBASE
KEY_READ
	dc.b	'EAD',TK_READ			* READ
KEY_REM
	dc.b	'EM',TK_REM				* REM
KEY_RESTORE
	dc.b	'ESTORE',TK_RESTORE		* RESTORE
KEY_RETURN
	dc.b	'ETURN',TK_RETURN			* RETURN
KEY_RIGHTS
	dc.b	'IGHT$(',TK_RIGHTS		* RIGHT$(
KEY_RND
	dc.b	'ND(',TK_RND			* RND(
KEY_RUN
	dc.b	'UN',TK_RUN				* RUN
	dc.b	$00
TAB_ASCS
KEY_SADD
	dc.b	'ADD(',TK_SADD			* SADD(
KEY_SAVE
	dc.b	'AVE',TK_SAVE			* SAVE
KEY_SGN
	dc.b	'GN(',TK_SGN			* SGN(
KEY_SIN
	dc.b	'IN(',TK_SIN			* SIN(
KEY_SPC
	dc.b	'PC(',TK_SPC			* SPC(
KEY_SQR
	dc.b	'QR(',TK_SQR			* SQR(
KEY_STEP
	dc.b	'TEP',TK_STEP			* STEP
KEY_STOP
	dc.b	'TOP',TK_STOP			* STOP
KEY_STRS
	dc.b	'TR$(',TK_STRS			* STR$(
KEY_SWAP
	dc.b	'WAP',TK_SWAP			* SWAP
	dc.b	$00
TAB_ASCT
KEY_TAB
	dc.b	'AB(',TK_TAB			* TAB(
KEY_TAN
	dc.b	'AN(',TK_TAN			* TAN
KEY_THEN
	dc.b	'HEN',TK_THEN			* THEN
KEY_TO
	dc.b	'O',TK_TO				* TO
KEY_TWOPI
	dc.b	'WOPI',TK_TWOPI			* TWOPI
	dc.b	$00
TAB_ASCU
KEY_UCASES
	dc.b	'CASE$(',TK_UCASES		* UCASE$(
KEY_UNTIL
	dc.b	'NTIL',TK_UNTIL			* UNTIL
KEY_USINGS
	dc.b	'SING$(',TK_USINGS		* USING$(
KEY_USR
	dc.b	'SR(',TK_USR			* USR(
	dc.b	$00
TAB_ASCV
KEY_VAL
	dc.b	'AL(',TK_VAL			* VAL(
KEY_VPTR
	dc.b	'ARPTR(',TK_VPTR			* VARPTR(
	dc.b	$00
TAB_ASCW
KEY_WAIT
	dc.b	'AIT',TK_WAIT			* WAIT
KEY_WHILE
	dc.b	'HILE',TK_WHILE			* WHILE
KEY_WIDTH
	dc.b	'IDTH',TK_WIDTH			* WIDTH
	dc.b	$00
TAB_POWR
KEY_POWER
	dc.b	TK_POWER,$00			* ^


*************************************************************************************
*
* just messages

LAB_BMSG
	dc.b	$0D,$0A,'Break',$00
LAB_EMSG
	dc.b	' Error',$00
LAB_LMSG
	dc.b	' in line ',$00
LAB_IMSG
	dc.b	'Extra ignored',$0D,$0A,$00
LAB_REDO
	dc.b	'Redo from start',$0D,$0A,$00
LAB_RMSG
	dc.b	$0D,$0A,'Ready',$0D,$0A,$00
LAB_SMSG
	dc.b	' Bytes free',$0D,$0A,$0A
	dc.b	'Enhanced 68k BASIC Version 3.52 (rosco_m68k)',$0D,$0A,$00


*************************************************************************************
* EhBASIC keywords quick reference list								*
*************************************************************************************

* glossary

*		<.>		  required
*		{.|.}		  one of required
*		[.]		  optional
*		...		  may repeat as last

*		any		= anything
*		num		= number
*		state		= statement
*		n		= positive integer
*		str		= string
*		var		= variable
*		nvar		= numeric variable
*		svar		= string variable
*		expr		= expression
*		nexpr		= numeric expression
*		sexpr		= string expression

* statement separator

* :		. [<state>] : [<state>]						* done

* number bases

* %		. %<binary num>							* done
* $		. $<hex num>							* done

* commands

* END		. END									* done
* FOR		. FOR <nvar>=<nexpr> TO <nexpr> [STEP <nexpr>]		* done
* NEXT	. NEXT [<nvar>[,<nvar>]...]					* done
* DATA	. DATA [{num|["]str["]}[,{num|["]str["]}]...]		* done
* INPUT	. INPUT [<">str<">;] <var>[,<var>[,<var>]...]		* done
* DIM		. DIM <var>(<nexpr>[,<nexpr>[,<nexpr>]])			* done
* READ	. READ <var>[,<var>[,<var>]...]				* done
* LET		. [LET] <var>=<expr>						* done
* DEC		. DEC <nvar>[,<nvar>[,<nvar>]...]				* done
* GOTO	. GOTO <n>								* done
* RUN		. RUN [<n>]								* done
* IF		. IF <expr>{GOTO<n>|THEN<{n|comm}>}[ELSE <{n|comm}>]	* done
* RESTORE	. RESTORE [<n>]							* done
* GOSUB	. GOSUB <n>								* done
* RETURN	. RETURN								* done
* REM		. REM [<any>]							* done
* STOP	. STOP								* done
* ON		. ON <nexpr>{GOTO|GOSUB}<n>[,<n>[,<n>]...]		* done
* NULL	. NULL <nexpr>							* done
* INC		. INC <nvar>[,<nvar>[,<nvar>]...]				* done
* WAIT	. WAIT <nexpr>,<nexpr>[,<nexpr>]				* done
* LOAD	. LOAD [<sexpr>]							* done for sim
* SAVE	. SAVE [<sexpr>][,[<n>][-<n>]]				* done for sim
* DEF		. DEF FN<var>(<var>)=<expr>					* done
* POKE	. POKE <nexpr>,<nexpr>						* done
* DOKE	. DOKE <nexpr>,<nexpr>						* done
* LOKE	. LOKE <nexpr>,<nexpr>						* done
* CALL	. CALL <nexpr>							* done
* DO		. DO									* done
* LOOP	. LOOP [{WHILE|UNTIL}<nexpr>]					* done
* PRINT	. PRINT [{;|,}][<expr>][{;|,}[<expr>]...]			* done
* CONT	. CONT								* done
* LIST	. LIST [<n>][-<n>]						* done
* CLEAR	. CLEAR								* done
* NEW		. NEW									* done
* WIDTH	. WIDTH [<n>][,<n>]						* done
* GET		. GET <var>								* done
* SWAP	. SWAP <var>,<var>						* done
* BITSET	. BITSET <nexpr>,<nexpr>					* done
* BITCLR	. BITCLR <nexpr>,<nexpr>					* done

* sub commands (may not start a statement)

* TAB		. TAB(<nexpr>)							* done
* ELSE	. IF <expr>{GOTO<n>|THEN<{n|comm}>}[ELSE <{n|comm}>]	* done
* TO		. FOR <nvar>=<nexpr> TO <nexpr> [STEP <nexpr>]		* done
* FN		. FN <var>(<expr>)						* done
* SPC		. SPC(<nexpr>)							* done
* THEN	. IF <nexpr> {THEN <{n|comm}>|GOTO <n>}			* done
* NOT		. NOT <nexpr>							* done
* STEP	. FOR <nvar>=<nexpr> TO <nexpr> [STEP <nexpr>]		* done
* UNTIL	. LOOP [{WHILE|UNTIL}<nexpr>]					* done
* WHILE	. LOOP [{WHILE|UNTIL}<nexpr>]					* done

* operators

* +		. [expr] + <expr>							* done
* -		. [nexpr] - <nexpr>						* done
* *		. <nexpr> * <nexpr>						* done fast hardware
* /		. <nexpr> / <nexpr>						* done fast hardware
* ^		. <nexpr> ^ <nexpr>						* done
* AND		. <nexpr> AND <nexpr>						* done
* EOR		. <nexpr> EOR <nexpr>						* done
* OR		. <nexpr> OR <nexpr>						* done
* >>		. <nexpr> >> <nexpr>						* done
* <<		. <nexpr> << <nexpr>						* done

* compare functions

* <		. <expr> < <expr>							* done
* =		. <expr> = <expr>							* done
* >		. <expr> > <expr>							* done

* functions

* SGN		. SGN(<nexpr>)							* done
* INT		. INT(<nexpr>)							* done
* ABS		. ABS(<nexpr>)							* done
* USR		. USR(<expr>)							* done
* FRE		. FRE(<expr>)							* done
* POS		. POS(<expr>)							* done
* SQR		. SQR(<nexpr>)							* done fast shift/sub
* RND		. RND(<nexpr>)							* done 32 bit PRNG
* LOG		. LOG(<nexpr>)							* done fast cordic
* EXP		. EXP(<nexpr>)							* done fast cordic
* COS		. COS(<nexpr>)							* done fast cordic
* SIN		. SIN(<nexpr>)							* done fast cordic
* TAN		. TAN(<nexpr>)							* done fast cordic
* ATN		. ATN(<nexpr>)							* done fast cordic
* PEEK	. PEEK(<nexpr>)							* done
* DEEK	. DEEK(<nexpr>)							* done
* LEEK	. LEEK(<nexpr>)							* done
* LEN		. LEN(<sexpr>)							* done
* STR$	. STR$(<nexpr>)							* done
* VAL		. VAL(<sexpr>)							* done
* ASC		. ASC(<sexpr>)							* done
* UCASE$	. UCASE$(<sexpr>)							* done
* LCASE$	. LCASE$(<sexpr>)							* done
* CHR$	. CHR$(<nexpr>)							* done
* HEX$	. HEX$(<nexpr>)							* done
* BIN$	. BIN$(<nexpr>)							* done
* BTST	. BTST(<nexpr>,<nexpr>)						* done
* MAX		. MAX(<nexpr>[,<nexpr>[,<nexpr>]...])			* done
* MIN		. MIN(<nexpr>[,<nexpr>[,<nexpr>]...])			* done
* PI		. PI									* done
* TWOPI	. TWOPI								* done
* VARPTR	. VARPTR(<var>)							* done
* SADD	. SADD(<svar>)							* done
* LEFT$	. LEFT$(<sexpr>,<nexpr>)					* done
* RIGHT$	. RIGHT$(<sexpr>,<nexpr>)					* done
* MID$	. MID$(<sexpr>,<nexpr>[,<nexpr>])				* done
* USING$	. USING$(<sexpr>,<nexpr>[,<nexpr>]...])			* done


*************************************************************************************

	END	code_start

*************************************************************************************

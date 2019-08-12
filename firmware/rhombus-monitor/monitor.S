*****************************************************************************************************
*****************************************************************************************************
*****	Title		: RHOMBUS System Monitor						*****
*****	Written by	: Jason Westervelt							*****
*****	Date		: 12 July 2017								*****
*****	Description	: A ROM monitor for the RHOMBUS minimalist 68020 system			*****
*****			  which was designed around the Motorola Application Note 1015		*****
*****												*****	
*****			  Portions of code borrowed from Hayden Kroepfl (ChartreuseK)		*****
*****												*****	
*****************************************************************************************************
*****************************************************************************************************

						*
					       ***
					      *****
					     *******	
					    **** ****
					   ****   ****
					  ****     ****
					 ****       ****
					****         ****
					 ****       ****
					  ****     ****
					   ****   ****
					    **** ****
					     *******
					      *****
					       ***
					        *

*****************************************************************************************************
*****************************************************************************************************
* Equates section										*****
												*****
****************************************							*****
*   Defines											*****
												*****
NOP		EQU	$4E71		STANDARD 68000 NOP INSTRUCTION				*****
TRAP_14		EQU	$4E4E		Code for TRAP #14					*****
****************************************							*****
*   Addresses											*****
												*****
ROMBAS		EQU	$FC0000		ROM BASE ADDRESS					*****
RAMBAS		EQU	$0		RAM BASE ADDRESS					*****
MFPBAS		EQU	$F80000		MFP BASE ADDRESS					*****
MFPVCT		EQU	$40		VECTOR FOR MFP SOURCED INTERRUPT			*****
STACK		EQU	$100000									*****
												*****
****************************************							*****
*   MC68901 MFP Registers									*****
												*****
MFPGPDR		EQU	MFPBAS+$1	GPIO DATA REGISTER					*****
MFPAER		EQU	MFPBAS+$3	ACTIVE EDGE REGISTER					*****
MFPDDR		EQU     MFPBAS+$5	DATA DIRECTION REGISTER					*****
MFPIERA		EQU     MFPBAS+$7	INTERRUPT ENABLE REGISTER A				*****
MFPIERB 	EQU     MFPBAS+$9	INTERRUPT ENABLE REGISTER B				*****
MFPIPRA		EQU     MFPBAS+$B	INTERRUPT PENDING REGISTER A				*****
MFPIPRB		EQU     MFPBAS+$D	INTERRUPT PENDING REGISTER B				*****
MFPISRA		EQU     MFPBAS+$F	INTERRUPT IN SERVICE REGISTER A				*****
MFPISRB		EQU     MFPBAS+$11	INTERRUPT IN SERVICE REGISTER B				*****
MFPIMRA		EQU     MFPBAS+$13	INTERRUPT MASK REGISTER A				*****
MFPIMRB		EQU     MFPBAS+$15	INTERRUPT MASK REGISTER B				*****
MFPVR		EQU     MFPBAS+$17	VECTOR REGISTER						*****
MFPTACR		EQU     MFPBAS+$19	TIMER A CONTROL REGISTER				*****
MFPTBCR		EQU     MFPBAS+$1B	TIMER B CONTROL REGISTER				*****
MFPTCDCR	EQU     MFPBAS+$1D	TIMER C/D CONTROL REGISTER				*****
MFPTADR		EQU     MFPBAS+$1F	TIMER A DATA REGISTER					*****
MFPTBDR		EQU     MFPBAS+$21	TIMER B DATA REGISTER					*****
MFPTCDR		EQU     MFPBAS+$23	TIMER C DATA REGISTER					*****
MFPTDDR		EQU     MFPBAS+$25	TIMER D DATA REGISTER					*****
MFPSCR		EQU     MFPBAS+$27	SYNCHRONOUS CHARACTER REGISTER				*****
MFPUCR		EQU     MFPBAS+$29	USART CONTROL REGISTER					*****
MFPRSR		EQU     MFPBAS+$2B	RECEIVER STATUS REGISTER				*****
MFPTSR		EQU     MFPBAS+$2D	TRANSMITTER STATUS REGISTER				*****
MFPUDR		EQU     MFPBAS+$2F	USART DATA REGISTER					*****
												*****	
												*****
****************************************							*****
*   ASCII Equates										*****
												*****
CTRLC		EQU	$03									*****
BEL		EQU	$07									*****
BKSP		EQU	$08		CTRL-H							*****
TAB		EQU	$09									*****
LF		EQU	$0A								     	*****
CR		EQU	$0D								      	  *
CTRLX		EQU	$18								       	 ***
ESC		EQU	$1B									** **
SPACE		EQU	$20									 ***
CTRLA		EQU	$01									  *

*****************************************************************************************************
*****************************************************************************************************
*	Program section										*****
*	The ROM in this BIOS is mapped to the variable						*****
*	ROMBAS.  All executable code is resident in ROM.					*****
* START		EQU	ROMBAS									*****
                section .text                                                                   *****
                                                                                                *****
                ORG     $FC0000                                                                 *****
                                                                                                *****
		DC.L	STACK		INITIAL STACK POINTER					*****
		DC.L	RESET		INITIAL PROGRAM COUNTER					*****
ROMBUF		DS.L	32									*****
MEMDAT		EQU	*		MEMORY EXERCISER DATA					*****	
		DC.B	$5									*****
		DC.B	$A									*****
		DC.B	$0									*****
		DC.B	$F									*****
		DS.L	$100									*****
START::                                                                                         *****
RESET		EQU	*		COLD ENTRY POINT					*****
LORAMINIT	EQU	*		THIS WILL TEST AND PREP LOWEST 2K OF RAM 		*****
*	This routine performs a quick check of memory prior to					*****
*	proceeding.  The count of errors is stored in D7 at completion				*****
*	We avoid using stack until the first 2K of RAM is deemed safe				*****
					* A0 ram address being tested				*****
					* A1 pointer to RAM test pattern			*****
					* D0 loop counter					*****
					* D2 byte read/written					*****
					* D3 test pattern index					*****
					* D7 error count					*****
					*							*****
		CLR.L	D7		CLEAR ERROR COUNTER					*****
		MOVE.L	#3,D3		INIT OUTER LOOP COUNTER					*****
		LEA.L	RAMBAS,A0	POINT TO BASE OF RAM					*****
		LEA.L	MEMDAT,A1	POINT TO MEMORY EXERCISER DATA				*****
												*****
.loop0		EQU	*									*****
		MOVE.L	#$7FF,D0	INIT INNER LOOP COUNTER, INITIALLY CHECK 2K		*****
		MOVE.B	(A1,D3),D2	GET MEMORY DATA						*****
												*****
.loop1		EQU	*									*****
		MOVE.B	D2,(A0,D0)	PUT DATA INTO MEMORY					*****
		CMP.B	(A0,D0),D2	COMPARE WITH STORED DATA				*****
		BEQ.S	.loop1_1	JUMP IF MATCHES						*****
		ADDQ	#1,D7		ELSE INCREMENT ERROR COUNT				*****
												*****
.loop1_1	EQU	*									*****
		DBRA	D0,.loop1	TEST ALL OF RAM						*****
		DBRA	D3,.loop0	FOR ALL DATA TYPES (4 TESTS)				*****
												*****
*	When memory test completes, memory is initialized with NOPs and vector table 		*****
*       is initialized with address of generic handler.						*****
*	After initialization, D7 will contain the number of errors from the test section	*****
												*****
memInit		EQU	*									*****
		LEA.L	RAMBAS,A0	POINT AT BASE OF RAM AGAIN				*****
		MOVE.L	#$7FE,D0	USE AS LOOP COUNTER FOR MEMINIT				*****
		MOVE.L	#$3FE,D2	POINT TO BOTTOM OF VECTOR TABLE				*****
		MOVE.W	#NOP,D1		FILL NON-VECTOR MEMORY WITH NOPs			*****
												*****
.loop2		EQU	*									*****
		MOVE.W	D1,(A0,D0)	PUT DATA INTO MEMORY					*****
		SUBQ	#2,D0		DECREMENT COUNTER					*****
		CMP.L	D0,D2		LOOK FOR BOTTOM OF VECTOR TABLE				*****
		BNE.S	.loop2		LOOP UNTIL BOTTOM OF VECTOR TABLE			*****
		SUBQ	#2,D0		ELSE MOVE TO LONG-WORD INIT				*****
		MOVE.L	#EXCHND,D1	PUT GENERIC EXCEPTION HANDLER IN REST OF VECTOR TABLE	*****
												*****
.loop3		EQU	*									*****
		MOVE.L	D1,(A0,D0)	PUT HANDLER ADDRESS THERE				*****
		SUBQ	#4,D0		AND DECREMENT POINTER					*****
		BGE.S	.loop3		FILL REST OF MEMORY					*****
* END RAM INITIALIZATION									*****
		LEA	RAMBAS,A6	POINT A6 TO DATA AREA					*****
		CLR.L	UCOMTAB(A6)	RESET USER COMMAND TABLE POINTER			*****
		BSR.S	CFGUART		CONFIGURE UART						*****
		LEA.L	msgPOR,A0	SEND POWER-ON-RESET MESSAGE				*****
		BSR.W	printString								*****
		LEA.L	msgLORAMck,A0	SEND LOW RAM CHECK MESSAGE				*****
		BSR.W	printString								*****
		LEA.L	msgOK,A0								*****
		BSR.W	printString								*****
		LEA.L	msgEXTABinit,A0								*****
		BSR.W	printString								*****
		BSR	EXCSET		SET UP EXCEPTION TABLE					*****
		LEA.L	msgOK,A0								*****
		BSR.W	printString								*****
		LEA.L	msgDCBinit,A0								*****
		BSR.W	printString								*****
		BSR	SET_DCB		SET UP DCB TABLE IN RAM					*****
		LEA.L	msgOK,A0								*****
		BSR.W	printString								*****
		MOVE.B	#0,ECHO(A6)	ENABLE LOCAL ECHO					*****
		MOVE.B	#0,UCASE(A6)	ENABLE UPPERCASE CONVERSION				*****
		LEA	BANNER,A4	POINT TO BANNER						*****
		BSR.W	HEADING		PRINT THE BANNER					*****
WARM		CLR.L	D7		CLEAR ERROR FLAG					*****
		BSR.W	NEWLINE		PRINT A NEWLINE						*****
		BSR.W	GETLINE		GET A COMMAND LINE					*****
		BSR.W	TIDY		CLEAN UP COMMAND LINE BUFFER				*****
		BSR.W	EXECUTE		INTERPRET AND EXECUTE COMMAND				*****
		BRA	WARM									*****
												 ***
												  *
*****************************************************************************************************
*****************************************************************************************************
* INITIALIZATION SECTION                                                                        *****
                                                                                                *****
CFGUART		EQU	*									*****
		BSR.W	MFPINIT									*****
		RTS										*****
												*****
												*****
EXCSET		EQU	*		SET UP EXCEPTION TABLE					*****
		MOVE.L	#RAMBAS,D0	POINT TO BASE OF RAM					*****
		MOVEC.L	D0,VBR		INITIALIZE VBR						*****
		LEA	RAMBAS,A0	POINT TO VECTOR BASE					*****
		MOVE.L	#ER_BUS,8(A0)	SET UP BUS ERROR EXCEPTION				*****
		MOVE.L	#ER_ADDR,12(A0)	SET UP ADDRESS ERROR EXCEPTION				*****
		MOVE.L	#ER_ILOP,16(A0) SET UP ILLEGAL OPERATION EXCEPTION			*****
		MOVE.L	#TRACE,36(A0)	SET UP TRACE EXCEPTION					*****
		MOVE.L	#TRAP0,128(A0)	SET UP TRAP #0 EXCEPTION				*****
		MOVE.L	#BRKPT,184(A0)	SET UP TRAP #14 = BREAKPOINT VECTOR			*****
		MOVE.L	#WARM,188(A0)	SET UP TRAP #15 EXCEPTION VECTOR			*****
		MOVE.W	#7,D0		CLEAR THE BREAKPOINT TABLE				*****
		LEA	BKPTAB(A6),A0	POINT TO TABLE						*****
EXCSET_2	CLR.L	(A0)+		CLEAR AN ADDRESS ENTRY					*****
		CLR.W	(A0)+		CLEAR A DATA ENTRY					  *
		DBRA	D0,EXCSET_2	REPEAT FOR REMAINING TABLE ENTRIES			 *** 
		RTS										** **
												 ***
												  *
												 
*****************************************************************************************************
*****************************************************************************************************
* TRAPS			                                                                        *****
												*****
TRAP0		CMP.B	#0,D1		D1 =  0 = Get character					*****
		BNE.S	TRAP1									*****
		BSR	GETCHAR									*****
		RTE										*****
												 ***
TRAP1		CMP.B	#1,D1		D1 =  1 = Print character				*****
		BNE.S	TRAP2									*****
		BSR	PUTCHAR									*****
		RTE										*****
												 ***
TRAP2		CMP.B	#2,D1		D2 =  2 = Newline					*****
		BNE.S	TRAP3									*****
		BSR	NEWLINE									*****
		RTE										*****
												 ***
TRAP3		CMP.B	#3,D1		D1 = 3 = Get parameter from buffer			*****
		BNE.S	TRAP4									*****
		BSR	PARAM									*****
		RTE										*****
												 ***
TRAP4		CMP.B	#4,D1		D1 = 4 = Print string pointed at by A4			*****
		BNE.S	TRAP5									*****
		BSR	PRINTSTRING								*****
		RTE										*****
												 ***
TRAP5		CMP.B   #5,D1             D1 = 5 = Get a hex character				*****
		BNE.S   TRAP6									*****
		BSR     HEX									*****
		RTE										*****
												 ***
TRAP6   CMP.B   #6,D1             D1 = 6 = Get a hex byte	
        BNE.S   TRAP7
        BSR     BYTE
        RTE
TRAP7   CMP.B   #7,D1             D1 = 7 = Get a word
        BNE.S   TRAP8
        BSR     WORD
        RTE
TRAP8   CMP.B   #8,D1             D1 = 8 = Get a longword
        BNE.S   TRAP9
        BSR     LONGWD
        RTE
TRAP9   CMP.B   #9,D1             D1 = 9 = Output hex byte
        BNE.S   TRAP10
        BSR     OUT2X
        RTE
TRAP10  CMP.B   #10,D1            D1 = 10 = Output hex word
        BNE.S   TRAP11
        BSR     OUT4X
        RTE
TRAP11  CMP.B   #11,D1            D1 = 11 = Output hex longword
        BNE.S   TRAP12
        BSR     OUT8X
        RTE
TRAP12  CMP.B   #12,D1            D1 = 12 = Print a space
        BNE.S   TRAP13
        BSR     PSPACE
        RTE
TRAP13  CMP.B   #13,D1            D1 = 13 = Get a line of text into
        BNE.S   TRAP14            the line buffer
        BSR     GETLINE
        RTE
TRAP14  CMP.B   #14,D1            D1 = 14 = Tidy up the line in the
        BNE.S   TRAP15            line buffer by removing leading
        BSR     TIDY              leading and multiple embeded spaces
        RTE
TRAP15  CMP.B   #15,D1            D1 = 15 = Execute the command in
        BNE.S   TRAP16            the line buffer
        BSR     EXECUTE
        RTE
TRAP16  CMP.B   #16,D1            D1 = 16 = Call RESTORE to transfer
        BNE.S   TRAP17            the registers in TSK_T to the 68000
        BSR     RESTORE           and therefore execute a program
        RTE
TRAP17  RTE


*****************************************************************************************************
*****************************************************************************************************
* INPUT/OUTPUT SUBROUTINES SECTION								*****
												*****
IO_REQ		MOVEM.L	A0-A1,-(A7)	BACK UP REGISTERS					*****
		LEA	8(A0),A1	A1 POINTS TO DEVICE HANDLER FIELD			*****
		MOVE.L	(A1),A1		A1 CONTAINS DEVICE HANDLER ADDRESS			*****
		JSR	(A1)		CALL DEVICE HANDLER					*****
		MOVEM.L	(A7)+,A0-A1	RESTORE REGISTERS					*****
		RTS										*****
												 ***
CON_IN		MOVEM.L	D1/A1,-(A7)	BACK UP REGISTERS					*****
		LEA	12(A0),A1	GET POINTER TO DEVICE FROM DCB				*****
		MOVE.L	(A1),A1		PUT ADDRESS OF DEVICE IN A1				*****
		CLR.B	19(A0)		CLEAR LOGICAL ERROR IN DCB				*****
		BCLR.B	#7,$1(A1)	ENABLE RTS TO ALLOW RECEIVE				*****
CON_I1		MOVE.B	$2B(A1),D1	READ RECEIVE STATUS REGISTER				*****
		BTST	#7,D1		CHECK RECEIVE BUFFER FULL				*****
		BEQ.S	CON_I1		LOOP UNTIL READY					*****
		MOVE.B	D1,18(A0)	STORE RECEIVER STATUS REGISTER IN DCB			*****
		MOVE.B	$2F(A1),D0	READ USART DATA REGISTER				*****
		MOVEM.L	(A7)+,D1/A1	RESTORE REGISTERS					*****
		RTS										*****
												 ***
CON_OUT		MOVEM.L	A1/D1-D2,-(A7)	BACK UP REGISTERS					*****
		LEA	12(A0),A1	GET POINTER TO DEVICE FROM DCB				*****
		MOVE.L	(A1),A1		PUT ADDRESS OF DEVICE IN A1				*****
		CLR.B	19(A0)		CLEAR LOGICAL ERROR IN DCB				*****
		BSET.B	#7,$1(A1)	NEGATE RTS TO INHIBIT RECEIVE				*****
CON_O1		MOVE.B	$2D(A1),D1	READ TRANSMIT STATUS REGISTER				*****
		BTST	#7,D1		CHECK TRANSMIT BUFFER FULL				*****
		BEQ.S	CON_O1		LOOP UNTIL TRANSMIT BUFFER EMPTY			*****
		MOVE.B	D1,18(A0)	STORE STATUS REGISTER IN DCB				*****
		MOVE.B	D0,$2F(A1)	PUT CHARACTER INTO USART DATA REGISTER			*****
		MOVEM.L	(A7)+,A1/D1-D2	RESTORE WORKING REGISTERS				*****
		RTS										*****
												 ***
BUFF_IN		LEA	12(A0),A1	A1 POINTS TO INPUT BUFFER				*****
		MOVE.L	(A1),A2		A2 HAS INPUT POINTER FROM BUFFER			*****
		MOVE.B	-(A2),D0	READ CHAR FROM BUFFER AND MOVE A2			*****
		MOVE.L	A2,(A1)		RESTORE POINTER IN BUFFER				*****
		RTS										*****
												 ***
BUFF_OUT	LEA	12(A0),A1	A1 POINTS TO OUTPUT BUFFER				*****
		MOVE.L	4(A1),A2	A2 HAS OUTPUT POINTER FROM BUFFER			*****
		MOVE.B	D0,(A2)+	PUT CHAR INTO BUFFER AND MOVE A2			*****
		MOVE.L	A2,(A1)		RESTORE POINTER IN BUFFER				*****
		RTS										*****
												 ***
GETCHAR		MOVE.L	A0,-(A7)	BACK UP REGISTER					*****
		MOVE.L	CONiVEC(A6),A0	A0 POINTS TO NAME OF CONSOLE DCB			*****
		BSR.S	IO_OPEN		OPEN CONSOLE BY PLACING DCB ADDRESS IN A0		*****
		BTST	#3,D7		THIS BIT SET IF OPEN ERROR				*****
		BNE.S	GETCHAR3	BAIL IF ERROR						*****
		BSR	IO_REQ		OTHERWISE DO I/O TRANSACTION				*****
		AND.B	#$7F,D0		STRIP MSB OF INPUT					*****
		TST.B	UCASE(A6)	TEST FOR UPPER -> LOWER CONVERSION			*****
		BNE.S	GETCHAR2	IF FLAG SET, DO NOT PERFORM CONVERSION			*****
		CMP.B	#'a',D0		TEST IF LOWER CASE LETTER				*****
		BLT.S	GETCHAR2	IF NOT LOWER CASE, DO NOT PERFORM CONVERSION		*****
		CMP.B	#'z',D0									*****
		BGT.B	GETCHAR2								*****
		AND.B	#%11011111,D0	CLEAR BIT 5 TO CONVERT TO UPPER CASE			*****
GETCHAR2	TST.B	ECHO(A6)	DO WE WANT ECHO?					*****
		BNE.S	GETCHAR3	NOT ZERO = NO ECHO					*****
		CMP.B	#BKSP,D0	CHECK FOR BACKSPACE, WE WON'T PRINT IT HERE, BUT RATHER	*****
		BEQ.S	GETCHAR3	HANDLE IT LATER IN GETLINE SUBROUTINE			*****
		BSR.S	PUTCHAR		OTHERWISE ECHO						*****
GETCHAR3	MOVE.L	(A7)+,A0	RESTORE REGISTER					*****
		RTS										*****
												 ***
PUTCHAR		MOVE.L	A0,-(A7)	BACK UP REGISTER					*****
		MOVE.L	CONoVEC(A6),A0	A0 POINTS TO NAME OF CONSOLE OUTPUT DCB			*****	
		BSR.S	IO_OPEN		OPEN CONSOLE						*****
		BSR	IO_REQ		PERFORM OUTPUT						*****
		MOVE.L	(A7)+,A0	RESTORE REGISTER					*****
		RTS										*****
												 ***
IO_OPEN		MOVEM.L	A1-A3/D0-D4,-(A7)							*****
		LEA	FIRST(A6),A1	A1 POINTS TO FIRST DCB IN RAM				*****
OPEN1		LEA	(A1),A2		A2 IS TEMP COPY OF POINTER TO DCB			*****
		LEA	(A0),A3		A3 IS TEMP COPY OF POINTER TO DCB NAME			*****
		MOVE.W	#7,D0		MATCH UP TO 8 CHARACTERS OF DCB NAME			*****
OPEN2		MOVE.B	(A2)+,D4	COMPARE DCB NAME WITH STRING				*****
		CMP.B	(A3)+,D4								*****
		BNE.S	OPEN3		NO MATCH, TRY NEXT DCB					*****
		DBRA	D0,OPEN2	ELSE REPEAT UNTIL ALL CHARS MATCHED			*****
		LEA	(A1),A0		MATCH, MOVE THIS DCB ADDRESS TO A0			*****
		BRA.S	OPEN4									*****
OPEN3		EQU	*		NO MATCH, FIND ADDRESS OF NEXT DCB			*****
		MOVE.W	16(A1),D1	GET PARAMETER BLOCK SIZE OF DCB				*****
		LEA	18(A1,D1.W),A1	A1 POINTS TO POINTER OF NEXT DCB			*****
		MOVE.L	(A1),A1		A1 POINTS TO NEXT DCB					*****
		CMP.L	#0,A1		TEST FOR END OF DCB LIST				*****
		BNE	OPEN1		TRY NEXT DCB IF NOT AT END				*****
		OR.B	#8,D7		ELSE FLAG ERROR AND BAIL				*****
OPEN4		MOVEM.L	(A7)+,A1-A3/D0-D4							*****
		RTS										*****
												 ***
NEWLINE		EQU	*		MOVE CURSOR TO BEGINNING OF NEW LINE			*****
		MOVEM.L	A4,-(A7)	SAVE REGISTER						*****
		LEA	PROMPT,A4	POINT TO PROMPT STRING					*****
		BSR.S	PRINTSTRING	PRINT STRING						*****
		MOVEM.L	(A7)+,A4	RESTORE REGISTER					*****
		RTS										*****
												 ***
GETLINE		LEA	LNBUF(A6),A1	A1 POINTS TO START OF LINE BUFFER			*****
		LEA	(A1),A3		A3 POINTS TO START					*****
		LEA	MAXCHR(A1),A2	A2 POINTS TO END					*****
GLN2		BSR	GETCHAR		GET A CHARACTER						*****
		CMP.B	#LF,D0		IGNORE LINEFEEDS					*****
		BEQ.S	GLN2		AND FETCH ANOTHER CHARACTER				*****
		CMP.B	#CTRLA,D0	IF CONTROL-A, REJECT LINE				*****
		BEQ.S	GLN5		AND FETCH A NEW LINE					*****
		CMP.B	#BKSP,D0	IF BACKSPACE, THEN ROLL BACK POINTER			*****
		BNE.S	GLN3		ELSE SKIP OVERLY-COMPLEX DELETE PROCESS			*****
		CMP.L	A1,A3		CHECK FOR EMPTY BUFFER FIRST TO AVOID BAD THINGS	*****
		BEQ	GLN2		IF ALREADY EMPTY, FETCH ANOTHER CHARACTER		*****
		MOVE.B	#BKSP,D0	DELETE THE SPACE TO MOVE CURSOR BACK ON SPACE		*****
		BSR.W	PUTCHAR									*****
		MOVE.B	#' ',D0		WRITE OVER DELETED CHARACTER WITH A SPACE		*****
		BSR.W	PUTCHAR									*****
		MOVE.B	#BKSP,D0	AND DELETE THE SPACE TO MOVE CURSOR BACK ON SPACE	*****
		BSR.W	PUTCHAR									*****
		LEA	-1(A3),A3	ELSE DECREMENT POINTER					*****
		BRA	GLN2		AND FETCH ANOTHER CHARACTER				*****
GLN3		MOVE.B	D0,(A3)+	STORE CHARACTER INTO BUFFER				*****
		CMP.B	#CR,D0		CHECK IF END OF LINE					*****
		BNE.S	GLN4		SKIP EXIT IF NOT CR					*****
*		BRA	NEWLINE		PRINT NEW LINE						*****
		RTS			RETURN ON CR						*****
GLN4		CMP.L	A2,A3		TEST FOR BUFFER OVERFLOW				*****
		BNE	GLN2		IF NOT FULL, GET NEW CHARACTER				*****
GLN5		BSR	NEWLINE		ELSE MOVE TO NEXT LINE					*****
		BRA	GETLINE		AND REPEAT						*****
												 ***
PRINTSTRING	EQU	*		DISPLAY STRING REFERENCED BY A4				*****
		MOVE.L	D0,-(A7)	SAVE REGISTER						*****
PRNT1		MOVE.B	(A4)+,D0	GET CHARACTER TO BE PRINTED				*****
		BEQ.S	PRNT2		BAIL IF NULL TERMINATOR					*****
		BSR	PUTCHAR		OTHERWISE PRINT						*****
		BRA	PRNT1		LOOP UNTIL NULL TERMINATOR FOUND			*****
PRNT2		MOVE.L	(A7)+,D0	RESTORE REGISTER					*****
		RTS										*****
												 ***
HEADING		BRA	PRINTSTRING								*****
												 ***
TIDY		LEA	LNBUF(A6),A0	POINT A0 TO LINE BUFFER					*****
		LEA	(A0),A1		POINT A1 TO START OF LINE BUFFER			*****
TIDY1		MOVE.B	(A0)+,D0	READ A CHARACTER INTO D0				*****
		CMP.B	#SPACE,D0	CHECK FOR LEADING WHITESPACE				*****
		BEQ.S	TIDY1		LOOP UNTIL NON-WHITESPACE CHARACTER FOUND		*****
		LEA	-1(A0),A0	MOVE POINTER BACK TO FIRST CHARACTER			*****
TIDY2		MOVE.B	(A0)+,D0	MOVE STRING LEFT TO REMOVE LEADING SPACES		*****
		MOVE.B	D0,(A1)+								*****
		CMP.B	#SPACE,D0	CHECK FOR MID-LINE SPACE				*****
		BNE.S	TIDY4		CHECK FOR CR IF NOT					*****
TIDY3		CMP.B	#SPACE,(A0)+	SKIP OVER CONSEQUTIVE MID-LINE SPACES			*****
		BEQ.S	TIDY3									*****
		LEA	-1(A0),A0	MOVE POINTER BACK					*****
TIDY4		CMP.B	#CR,D0		TEST FOR CR						*****
		BNE.S	TIDY2		IF NO MATCH, READ NEXT CHARACTER			*****
		LEA	LNBUF(A6),A0	RESTORE BUFFER POINTER					*****
TIDY5		CMP.B	#CR,(A0)	TEST FOR CR						*****
		BEQ.S	TIDY6		BAIL IF CR MATCHED					*****
		CMP.B	#SPACE,(A0)+	TEST FOR COMMAND DELIMITER				*****
		BNE.S	TIDY5		REPEAT UNTIL DELIMITER OR CR MATCHED			*****
TIDY6		MOVE.L	A0,BUFPT(A6)	UPDATE BUFFER POINTER					*****
		RTS										*****

PARAM		MOVE.L	D1,-(A7)	Save D1
        	CLR.L	D1		Clear input accumulator
		MOVE.L	BUFPT(A6),A0	A0 points to parameter in buffer
PARAM1		MOVE.B	(A0)+,D0	Read character from line buffer
		CMP.B	#SPACE,D0	Test for delimiter
		BEQ.S	PARAM4		The permitted delimiter is a
		CMP.B	#CR,D0		space or a carriage return
		BEQ.S	PARAM4		Exit on either space or C/R
		ASL.L	#4,D1		Shift accumulated result 4 bits left
		SUB.B	#$30,D0		Convert new character to hex
		BMI.S	PARAM5		If less than $30 then not-hex
		CMP.B	#$09,D0		If less than 10
		BLE.S	PARAM3		then continue
		SUB.B	#$07,D0		Else assume $A - $F
		CMP.B	#$0F,D0		If more than $F
		BGT.S	PARAM5		then exit to error on not-hex
PARAM3		ADD.B	D0,D1		Add latest nybble to total in D1
		BRA	PARAM1		Repeat until delimiter found
PARAM4		MOVE.L	A0,BUFPT(A6)	Save pointer in memory
		MOVE.L	D1,PARAMETER(A6)	Save parameter in memory
		MOVE.L	D1,D0		Put parameter in D0 for return
		BRA.S	PARAM6		Return without error
PARAM5		OR.B	#2,D7		Set error flag before return
PARAM6		MOVE.L	(A7)+,D1	Restore working register
		RTS			Return with error					*****
												 ***
PARNUM	MOVE.L	BUFPT(A6),A0		A0 points to parameter in buffer			*****
PARNUM0	MOVE.L	D1,-(A7)		Save D1							*****
	CLR.L	D1			Clear input accumulator					*****
	CLR.L	D7			Clear error flags					*****
PARNUM1	MOVE.B	(A0)+,D0		Read character from the line buffer			*****
	CMP.B	#SPACE,D0		Ignore leading spaces					*****
	BEQ.S	PARNUM1			Grab another character until non-space found		*****
	CMP.B	#'0',D0			Look for hex digits 0-9					*****
	BLT.S	NMINVAL										*****
	CMP.B	#'9',D0										*****
	BLE.S	PARNUM2										*****
	CMP.B	#'A',D0			Look for hex digits A-F					*****
	BLT.S	NMINVAL										*****
	CMP.B	#'F',D0										*****
	BLE.S	PARNUM3										*****
NMINVAL	OR.B	#2,D7			Set error flag before return				*****
PARNUM6	MOVE.L	(A7)+,D1		Restore working register				*****
	RTS											*****
PARNUM3	SUB.B	#'7',D0			Convert 'A' to 10, and so on...				*****
	BRA.S	PARLOOP										*****
PARNUM2	SUB.B	#'0',D0			Convert '0' to 0, and so on...				*****
PARLOOP	MOVE.B	(A0)+,D1		Read in another digit					*****
	CMP.B	#'0',D1			Look for hex digits 0-9					*****
	BLT.S	PARNEND			End if non-hex						*****
	CMP.B	#'9',D1										*****
	BLE.S	PARCHR1										*****
	CMP.B	#'A',D1			Look for hex digits A-F					*****
	BLT.S	PARNEND										*****
	CMP.B	#'F',D1										*****
	BLE.S	PARCHR2										*****
PARNEND	SUBQ.L	#1,A0			Roll back buffer on non-hex				*****
	MOVE.L	(A7)+,D1		Restore D1						*****
	RTS											*****
PARCHR2	SUB.B	#'7',D1			Convert 'A' to 10, and so on				*****
	BRA.S	PARCHR3										*****
PARCHR1	SUB.B	#'0',D1			Convert '0' to 0, and so on				*****
PARCHR3	LSL.L	#4,D0			Shift to next nybble					*****
	ADD.B	D1,D0			Place in current nybble					*****
	BRA.S	PARLOOP			Repeat until non-hex					*****

												 ***
HEX      BSR      GETCHAR           Get a character from input device
         SUB.B    #$30,D0           Convert to binary
         BMI.S    NOT_HEX           If less than $30 then exit with error
         CMP.B    #$09,D0           Else test for number (0 to 9)
         BLE.S    HEX_OK            If number then exit - success
         SUB.B    #$07,D0           Else convert letter to hex
         CMP.B    #$0F,D0           If character in range "A" to "F"
         BLE.S    HEX_OK            then exit successfully
NOT_HEX  OR.B     #1,D7             Else set error flag
HEX_OK   RTS                        and return

BYTE     MOVE.L   D1,-(A7)          Save D1
         BSR      HEX               Get first hex character
         ASL.B    #4,D0             Move it to MS nybble position
         MOVE.B   D0,D1             Save MS nybble in D1
         BSR      HEX               Get second hex character
         ADD.B    D1,D0             Merge MS and LS nybbles
         MOVE.L   (A7)+,D1          Restore D1
         RTS

WORD     BSR      BYTE              Get upper order byte
         ASL.W    #8,D0             Move it to MS position
         BRA      BYTE              Get LS byte and return

LONGWD   BSR      WORD              Get upper order word
         SWAP     D0                Move it to MS position
         BRA      WORD              Get lower order word and return

OUT1X    MOVE.W   D0,-(A7)          Save D0
         AND.B    #$0F,D0           Mask off MS nybble
         ADD.B    #$30,D0           Convert to ASCII
         CMP.B    #$39,D0           ASCII = HEX + $30
         BLS.S    OUT1X1            If ASCII <= $39 then print and exit
         ADD.B    #$07,D0           Else ASCII := HEX + 7
OUT1X1   BSR      PUTCHAR           Print the character
         MOVE.W   (A7)+,D0          Restore D0
         RTS

OUT2X    ROR.B    #4,D0             Get MS nybble in LS position
         BSR      OUT1X             Print MS nybble
         ROL.B    #4,D0             Restore LS nybble
         BRA      OUT1X             Print LS nybble and return

OUT4X    ROR.W    #8,D0             Get MS byte in LS position
         BSR      OUT2X             Print MS byte
         ROL.W    #8,D0             Restore LS byte
         BRA      OUT2X             Print LS byte and return

OUT8X    SWAP     D0                Get MS word in LS position
         BSR      OUT4X             Print MS word
         SWAP     D0                Restore LS word
         BRA      OUT4X             Print LS word and return
												 ***
dispRAM		MOVEM.L	D2-D4/A2,-(SP)	Save registers						************************
		MOVE.L	A0,A2		Save start address					************************
		MOVE.L	D0,D2		Save number of bytes					************************
.line		MOVE.L	A2,D0									*****
		BSR.W	OUT8X		Starting address of the line				*****
		LEA	msgColonSpc,A4								*****
		BSR.W	PRINTSTRING								*****
		MOVE.L	#16,D3		16 bytes printed on a line				*****
		MOVE.L	D3,D4		Save number of bytes on this line			*****
.hexbyte	TST.L	D2		Check if out of bytes					*****
		BEQ.S	.endbytesShort								*****
		TST.B	D3		Check if line is finished				*****
		BEQ.S	.endbytes								*****
		MOVE.B	(A2)+,D0	Read in a byte from RAM					*****
		BSR.W	OUT2X		Display it						*****
		MOVE.B	#' ',D0									*****
		BSR.W	PUTCHAR		Separate bytes for readability				*****
		SUBQ.L	#1,D3									*****
		SUBQ.L	#1,D2									*****
		BRA.S	.hexbyte								*****
.endbytesShort	SUB.B	D3,D4		Set D4 to actual number of bytes on this line		*****
		MOVE.B	#' ',D0									*****
.endbytesShrtLp	TST.B	D3		Check if line ended					*****
		BEQ.S	.endbytes								*****
		MOVE.B	#' ',D0									*****
		BSR.W	PUTCHAR		Pad end with spaces					*****
		MOVE.B 	#' ',D0									*****
		BSR.W	PUTCHAR		Pad end with spaces					*****
		MOVE.B 	#' ',D0									*****
		BSR.W	PUTCHAR		Pad end with spaces					*****
		SUBQ.B	#1,D3									*****
		BRA.S	.endbytesShrtLp								*****
.endbytes	SUBA.L	D4,A2		Return to the start address of this line		*****
.endbytesLoop	TST.B	D4		Check if done printing ASCII				*****
		BEQ	.endline								*****
		SUBQ.B	#1,D4									*****
		MOVE.B	(A2)+,D0	Read the byte						*****
		CMP.B	#' ',D0		Check if character is in printable range		*****
		BLT.S	.unprintable								*****
		CMP.B	#'~',D0		Highest printable character				*****
		BGT.S	.unprintable								*****
		BSR.W	PUTCHAR									*****
		BRA.S	.endbytesLoop								*****
.unprintable	MOVE.B	#'.',D0									*****
		BSR.W	PUTCHAR									*****
		BRA.S	.endbytesLoop								*****
.endline	LEA.L	CRLF,A4									*****
		BSR.W	PRINTSTRING								*****
		TST.L	D2									*****
		BLE.S	.end									*****		**
		BRA.W	.line									*****		****
.end		MOVEM.L	(SP)+,D2-D4/A2	Restore registers					**********************		
		RTS										************************	
										**************************************
										*********************		****
										*********************		**

*****************************************************************************************************
*****************************************************************************************************
* COMMAND SUBROUTINES SECTION									*****
												*****
EXECUTE		TST.L	UCOMTAB(A6)	Test pointer to user table				*****
		BEQ.S	EXEC1		If clear then try built-in table			*****
		MOVE.L	UCOMTAB(A6),A3	Else pick up pointer to user table			*****
		BSR.S	SEARCH		Look for command in user table				*****
		BCC.S	EXEC1		If not found then try internal table			*****
		MOVE.L	(A3),A3		Else get absolute address of command			*****
		JMP	(A3)		from user table and execute it				*****
												*****
EXEC1		LEA.L	COMTAB,A3	Try built-in command table				*****
		BSR.S	SEARCH		Look for command in built-in table			*****
		BCS.S	EXEC2		If found then execute command				*****
		LEA.L	ERMES2,A4	Else print "invalid command"				*****
		BRA.W	PRINTSTRING	and return						*****
EXEC2		MOVE.L	(A3),A3		Get the relative command address			*****
		LEA.L	COMTAB,A4	pointed at by A3 and add it to				*****
		ADD.L	A4,A3		the PC to generate the actual				*****
		JMP	(A3)		command address. Then execute it.			*****
												 ***
SEARCH		EQU	*                 Match the command in the line buffer			*****
		CLR.L	D0                with command table pointed at by A3			*****
		MOVE.B	(A3),D0           Get the first character in the			*****
		BEQ.S	SRCH7             current entry. If zero then exit			*****
		LEA.L	6(A3,D0.W),A4     Else calculate address of next entry			*****
		MOVE.B	1(A3),D1          Get number of characters to match			*****
		LEA.L	LNBUF(A6),A5     A5 points to command in line buffer			*****
		MOVE.B	2(A3),D2          Get first character in this entry			*****
		CMP.B	(A5)+,D2          from the table and match with buffer			*****
		BEQ.S	SRCH3             If match then try rest of string			*****
SRCH2		MOVE.L	A4,A3             Else get address of next entry			*****
		BRA	SEARCH            and try the next entry in the table			*****
SRCH3		SUB.B	#1,D1             One less character to match				*****
		BEQ.S	SRCH6             If match counter zero then all done			*****
		LEA.L	3(A3),A3          Else point to next character in table			*****
SRCH4		MOVE.B	(A3)+,D2          Now match a pair of characters			*****
		CMP.B	(A5)+,D2								*****
		BNE	SRCH2             If no match then try next entry			*****
		SUB.B	#1,D1             Else decrement match counter and			*****
		BNE	SRCH4             repeat until no chars left to match			*****
SRCH6		LEA.L	-4(A4),A3         Calculate address of command entry			*****
		OR.B	#1,CCR            point. Mark carry flag as success			*****
		RTS			and return						*****
SRCH7		AND.B	#$FE,CCR	Fail - clear carry to indicate				*****
		RTS			command not found and return				*****
												 ***
MEMORY	BSR	PARAM             Get start address from line buffer
	TST.B	D7                Test for input error
	BNE.S	MEM3              If error then exit
	MOVE.L	D0,A3             A3 points to location to be opened
MEM1	BSR	NEWLINE
	BSR.S	ADR_DW		Print current address and contents
	BSR.S	PSPACE             update pointer, A3, and O/P space
	BSR	GETCHAR           Input char to decide next action
	CMP.B	#CR,D0            If carriage return then exit
	BEQ.S	MEM3              Exit
	CMP.B	#'-',D0           If "-" then move back
	BNE.S	MEM2              Else skip wind-back procedure
	LEA.L	-4(A3),A3         Move pointer back 2+2
	BRA	MEM1              Repeat until carriage return
MEM2	CMP.B	#SPACE,D0         Test for space (= new entry)
	BNE.S	MEM1		If not space then repeat
	BSR	WORD		Else get new word to store
	TST.B	D7		Test for input error
	BNE.S	MEM3		If error then exit						*****
	MOVE.W	D0,-2(A3)	Store new word							*****
	BRA	MEM1		Repeat until carriage return					*****
MEM3	RTS											*****
												 ***
ADR_DB	MOVE.L   D0,-(A7)	Print the contents of A3 and the				*****
	MOVE.L   A3,D0		byte pointed at by A3.						*****
	BSR      OUT8X		Print current address						*****
	BSR.S    PSPACE		Insert delimiter						*****
	MOVE.W   (A3),D0	Get data at this address in D0					*****
	BSR      OUT2X		and print it							*****
	LEA.L    2(A3),A3	Point to next address to display				*****
	MOVE.L   (A7)+,D0	Restore D0							*****
	RTS											*****
												 ***
ADR_DW	MOVE.L   D0,-(A7)	Print the contents of A3 and the				*****
	MOVE.L   A3,D0		word pointed at by A3.						*****
	BSR      OUT8X		print current address						*****
	BSR.S    PSPACE		Insert delimiter						*****
	MOVE.W   (A3),D0	Get data at this address in D0					*****
	BSR      OUT4X		and print it							*****
	LEA.L    2(A3),A3	Point to next address to display				*****
	MOVE.L   (A7)+,D0	Restore D0							*****
	RTS											*****
												 ***
PSPACE	MOVE.B   D0,-(A7)	Print a single space						*****
	MOVE.B   #SPACE,D0									*****
	BSR      PUTCHAR									*****
	MOVE.B   (A7)+,D0									*****
	RTS											*****
												 ***
********************************								*****
* Examine											*****
*												*****
*   Modes:	e ADDR		Display a single byte						*****
*		e ADDR.		Display a single page (16 lines, 256 bytes)			*****
*		e ADDR-ADDR	Display all bytes between two addresses				*****
*		e ADDR+LEN	Display LEN bytes following ADDR				*****
*		e ADDR;		Interactive mode: SPACE shows 16 lines, ENTER shows 1		*****
												*****
EXAMINE		BSR	PARNUM		Get start address					*****
		TST.B	D7		Test for input error					*****
		BNE.W	EXAM3		Bail on error						*****
		MOVE.L	D0,A3		A3 points to location to be examined			*****
*		BSR	NEWLINE									*****
EXLOOP		MOVE.B	(A0)+,D0	Grab next character in command buffer			*****
		CMP.B	#' ',D0		Ignore spaces						*****
		BEQ.S	EXLOOP									*****
		CMP.B	#'-',D0		Range requested						*****
		BEQ.S	EXRANGE									*****
		CMP.B	#'+',D0		Length requested					*****
		BEQ.S	EXLENG									*****
		CMP.B	#';',D0		Interactive mode requested				*****
		BEQ.S	EXINTER									*****
		CMP.B	#'.',D0		Quick line requested					*****
		BEQ.S	EXQUICK									*****
		MOVE.L	#1,D0		Otherwise read a single byte				*****
		BRA.S	EXEND									*****
EXRANGE		BSR.W	PARNUM0		Find ending address					*****
		TST.B	D7		Non-zero return on invalid address			*****
		BNE.W	EXINVAL									*****
		SUB.L	A3,D0		Get the length						*****
		BRA.S	EXEND									*****
EXQUICK		MOVE.L	#$100,D0								*****
		BRA.S	EXEND									*****
EXLENG		BSR.W	PARNUM0		Find the length						*****
		TST.B	D7		Check for error						*****
		BNE.W	EXINVAL									*****
EXEND		LEA.L	CRLF,A4									*****
		BSR.W	PRINTSTRING								*****
		MOVE.L	A3,A0		Parameter parsing complete, pass to dispRAM and return	*****
		BSR.W	dispRAM									*****
		RTS										*****
EXINTER		LEA.L	CRLF,A4									*****
		BSR.W	PRINTSTRING								*****
		MOVE.L	A3,A0		Interactive mode, set current address			*****
		MOVE.L	#$10,D0		16 bytes						*****
		BSR.W	dispRAM									*****
		ADD.L	#$10,A3		Update current address					*****
EXINTEND	LEA.L	EXPROMPT,A4	Show Examine prompt					*****
		BSR.W	PRINTSTRING								*****
		BSR.W	GETCHAR		Grab a character					*****
		CMP.B	#CR,D0		Display another line					*****
		BEQ.S	EXINTER									*****
		CMP.B	#' ',D0		Display a page (256 bytes)				*****
		BEQ.S	EXINTERPG								*****
		CMP.B	#LF,D0		Disregard linefeeds					*****
		BEQ.S	EXINTEND								*****
		RTS			Else Exit						*****
EXINTERPG	LEA.L	CRLF,A4									*****
		BSR.W	PRINTSTRING								*****
		MOVE.L	A3,A0									*****
		MOVE.L	#$100,D0	256 bytes						*****
		BSR.W	dispRAM									*****
		ADD.L	#$100,A3	Adjust current address					*****
		BRA.S	EXINTEND								*****
*		BSR.W	ADR_DB		Print current address and requested values there	*****
*		BSR	NEWLINE									*****
EXAM3		RTS										*****
EXINVAL		OR.B	#2,D7		Set error flag before returning				*****
		RTS										*****
												 ***
EX_DIS  LEA.L   TSK_T(A6),A5      A5 points to display frame
        LEA.L   MES3,A4       Point to heading
        BSR     HEADING           and print it
        MOVE.W  #7,D6             8 pairs of registers to display
        CLR.B   D5                D5 is the line counter
EX_D1   MOVE.B  D5,D0             Put current register number in D0
        BSR     OUT1X             and print it
        BSR     PSPACE            and a space
        ADD.B   #1,D5             Update counter for next pair
        MOVE.L  (A5),D0           Get data register to be displayed
        BSR     OUT8X             from the frame and print it
        LEA.L   MES4,A4       Print string of spaces
        BSR.W   PRINTSTRING           between data and address registers
        MOVE.L  32(A5),D0         Get address register to be displayed
        BSR     OUT8X             which is 32 bytes on from data reg
        BSR     NEWLINE
        LEA.L   4(A5),A5          Point to next pair (ie Di, Ai)
        DBRA    D6,EX_D1          Repeat until all displayed
        LEA.L   32(A5),A5         Adjust pointer by 8 longwords
        BSR     NEWLINE           to point to SSP
        LEA.L   MES2A,A4      Point to "SS ="
        BSR     PRINTSTRING           Print it
        MOVE.L  (A5)+,D0          Get SSP from frame
        BSR     OUT8X             and display it
        BSR     NEWLINE
        LEA.L   MES1,A4       Point to 'SR ='
        BSR     PRINTSTRING           Print it
        MOVE.W  (A5)+,D0          Get status register
        BSR     OUT4X             Display status
        BSR     NEWLINE
        LEA.L   MES2,A4       Point to 'PC ='
        BSR     PRINTSTRING           Print it
        MOVE.L  (A5)+,D0          Get PC
        BSR     OUT8X             Display PC
        BRA     NEWLINE           Newline and return
	
REG_MOD  CLR.L   D1                  D1 to hold name of register
         LEA.L   BUFPT(A6),A0        A0 contains address of buffer pointer
         MOVE.L  (A0),A0             A0 now points to next char in buffer
         MOVE.B  (A0)+,D1            Put first char of name in D1
         ROL.W   #8,D1               Move char one place left
         MOVE.B  (A0)+,D1            Get second char in D1
         LEA.L   1(A0),A0            Move pointer past space in buffer
         MOVE.L  A0,BUFPT(A6)        Update buffer pointer
         CLR.L   D2                  D2 is the character pair counter
         LEA.L   REGNAME,A0          A0 points to string of character pairs
         LEA.L   (A0),A1             A1 also points to string
REG_MD1  CMP.W   (A0)+,D1            Compare a char pair with input
         BEQ.S   REG_MD2             If match then exit loop
         ADD.L   #1,D2               Else increment match counter
         CMP.L   #19,D2              Test for end of loop
         BNE     REG_MD1             Continue until all pairs matched
         LEA.L   ERMES1,A4           If here then error
         BRA     PRINTSTRING         Display error and return
REG_MD2  LEA.L   TSK_T(A6),A1        A1 points to display frame
         ASL.L   #2,D2               Multiply offset by 4 (4 bytes/entry)
         CMP.L   #72,D2              Test for address of PC
         BNE.S   REG_MD3             If not PC then all is OK
         SUB.L   #2,D2               else dec PC pointer as Sr is a word
REG_MD3  LEA.L   (A1,D2),A2          Calculate address of entry in disptable
         MOVE.L  (A2),D0             Get old contents
         BSR     OUT8X               Display them
         BSR     NEWLINE
         BSR     PARAM               Get new data
         TST.B   D7                  Test for input error
         BEQ.S   REG_MD4             If no error then go and store data
         LEA.L   ERMES1,A4           Else point to error message
         BRA     PRINTSTRING         print it and return
REG_MD4  CMP.L   #68,D2              If this address is the SR then
         BEQ.S   REG_MD5             we have only a word to store
         MOVE.L  D0,(A2)             Else store new data in display frame
         RTS
REG_MD5  MOVE.W  D0,(A2)             Store SR (one word)
         RTS

DELAY    EQU       *                Provide a time delay for the host
         MOVEM.L   D0/A4,-(A7)      to settle. Save working registers
         MOVE.L    #$4000,D0        Set up delay constant
DELAY1   SUB.L     #1,D0            Count down         (8 clk cycles)
         BNE       DELAY1           Repeat until zero  (10 clk cycles)
         MOVEM.L   (A7)+,D0/A4      Restore working registers
         RTS
	
*************************************************************************
*
*  GO executes a program either from a supplied address or
*  by using the data in the display frame
GO       BSR     PARAM               Get entry address (if any)
         TST.B   D7                  Test for error in input
         BEQ.S   GO1                 If D7 zero then OK
         LEA.L   ERMES1,A4           Else point to error message,
         BRA     PRINTSTRING         print it and return
GO1      TST.L   D0                  If no address entered then get
         BEQ.S   GO2                 address from display frame
         MOVE.L  D0,TSK_T+70(A6)     Else save address in display frame
         MOVE.W  #$2700,TSK_T+68(A6) Store dummy status in frame
GO2      BRA.S   RESTORE             Restore volatile environment and go
*
GB       BSR     BR_SET              Same as go but presets breakpoints
         BRA.S   GO                  Execute program

*************************************************************************
*
* JUMP causes execution to begin at the address in the line buffer
*
JUMP     BSR     PARAM              Get address from buffer
         TST.B   D7                 Test for input error
         BNE.S   JUMP1              If error flag not zero then exit
         TST.L   D0                 Else test for missing address
         BEQ.S   JUMP1              field. If no address then exit
         MOVE.L  D0,A0              Put jump address in A0 and call the
         JMP     (A0)               subroutine. User to supply RTS!!
JUMP1    LEA.L   ERMES1,A4          Here for error - display error
         BRA     PRINTSTRING        message and return

*        RESTORE moves the volatile environment from the display
*        frame and transfers it to the 68000's registers. This
*        re-runs a program suspended after an exception
*
RESTORE  LEA.L   TSK_T(A6),A3        A3 points to display frame
         LEA.L   74(A3),A3           A3 now points to end of frame + 4
         LEA.L   4(A7),A7            Remove return address from stack
         MOVE.W  #36,D0              Counter for 37 words to be moved
REST1    MOVE.W  -(A3),-(A7)         Move word from display frame to stack
         DBRA    D0,REST1            Repeat until entire frame moved
         MOVEM.L (A7)+,D0-D7         Restore old data registers from stack
         MOVEM.L (A7)+,A0-A6         Restore old address registers
         LEA.L   8(A7),A7            Except SSP/USP - so adjust stack
         RTE                         Return from exception to run program
*
TRACE    EQU     *                   TRACE exception (rudimentary version)
         MOVE.L  MES12,A4            Point to heading
         BSR     HEADING             Print it
         BSR     GROUP1              Save volatile environment
         BSR     EX_DIS              Display it
         BRA     WARM                Return to monitor
			

*************************************************************************
*  Breakpoint routines: BR_GET gets the address of a breakpoint and
*  puts it in the breakpoint table. It does not plant it in the code.
*  BR_SET plants all breakpoints in the code. NOBR removes one or all
*  breakpoints from the table. KILL removes breakpoints from the code.
*
BR_GET   BSR     PARAM               Get breakpoint address in table
         TST.B   D7                  Test for input error
         BEQ.S   BR_GET1             If no error then continue
         LEA.L   ERMES1,A4           Else display error
         BRA     PRINTSTRING         and return
BR_GET1  LEA.L   BKPTAB(A6),A3       A6 points to breakpoint table
         MOVE.L  D0,A5               Save new BP address in A5
         MOVE.L  D0,D6               and in D6 because D0 gets corrupted
         MOVE.W  #7,D5               Eight entries to test
BR_GET2  MOVE.L  (A3)+,D0            Read entry from breakpoint table
         BNE.S   BR_GET3             If not zero display existing BP
         TST.L   D6                  Only store a non-zero breakpoint
         BEQ.S   BR_GET4
         MOVE.L  A5,-4(A3)           Store new breakpoint in table
         MOVE.W  (A5),(A3)           Save code at BP address in table
         CLR.L   D6                  Clear D6 to avoid repetition
BR_GET3  BSR     OUT8X               Display this breakpoint
         BSR     NEWLINE
BR_GET4  LEA.L   2(A3),A3            Step past stored op-code
         DBRA    D5,BR_GET2          Repeat until all entries tested
         RTS                         Return

BR_SET   EQU     *                   Plant any breakpoints in user code
         LEA.L   BKPTAB(A6),A0       A0 points to BP table
         LEA.L   TSK_T+70(A6),A2     A2 points to PC in display frame
         MOVE.L  (A2),A2             Now A2 contains value of PC
         MOVE.W  #7,D0               Up to eight entries to plant
BR_SET1  MOVE.L  (A0)+,D1            Read breakpoint address from table
         BEQ.S   BR_SET2             If zero then skip planting
         CMP.L   A2,D1               Don't want to plant BP at current PC
         BEQ.S   BR_SET2             location, so skip planting if same
         MOVE.L  D1,A1               Transfer BP address to address reg
         MOVE.W  #TRAP_14,(A1)       Plant op-code for TRAP #14 in code
BR_SET2  LEA.L   2(A0),A0            Skip past op-code field in table
         DBRA    D0,BR_SET1          Repeat until all entries tested
         RTS

NOBR     EQU     *                   Clear one or all breakpoints
         BSR     PARAM               Get BP address (if any)
         TST.B   D7                  Test for input error
         BEQ.S   NOBR1               If no error then skip abort
         LEA.L   ERMES1,A4           Point to error message
         BRA     PRINTSTRING         Display it and return
NOBR1    TST.L   D0                  Test for null address (clear all)
         BEQ.S   NOBR4               If no address then clear all entries
         MOVE.L  D0,A1               Else just clear breakpoint in A1
         LEA.L   BKPTAB(A6),A0       A0 points to BP table
         MOVE.W  #7,D0               Up to eight entries to test
NOBR2    MOVE.L  (A0)+,D1            Get entry and
         LEA.L   2(A0),A0            skip past op-code field
         CMP.L   A1,D1               Is this the one?
         BEQ.S   NOBR3               If so go and clear entry
         DBRA    D0,NOBR2            Repeat until all tested
         RTS
NOBR3    CLR.L   -6(A0)              Clear address in BP table
         RTS
NOBR4    LEA.L   BKPTAB(A6),A0       Clear all 8 entries in BP table
         MOVE.W  #7,D0               Eight entries to clear
NOBR5    CLR.L   (A0)+               Clear breakpoint address
         CLR.W   (A0)+               Clear op-code field
         DBRA    D0,NOBR5            Repeat until all done
         RTS

BR_CLR   EQU     *                   Remove breakpoints from code
         LEA.L   BKPTAB(A6),A0       A0 points to breakpoint table
         MOVE.W  #7,D0               Up to eight entries to clear
BR_CLR1  MOVE.L  (A0)+,D1            Get address of BP in D1
         MOVE.L  D1,A1               and put copy in A1
         TST.L   D1                  Test this breakpoint
         BEQ.S   BR_CLR2             If zero then skip BP clearing
         MOVE.W  (A0),(A1)           Else restore op-code
BR_CLR2  LEA.L   2(A0),A0            Skip past op-code field
         DBRA    D0,BR_CLR1          Repeat until all tested
         RTS

*************************************************************************
*
*  LOAD  Loads data formatted in hexadecimal "S" format from Port 2
*        NOTE - I/O is automatically redirected to the aux port for
*        loader functions. S1 or S2 records accepted
*
LOAD     MOVE.L   CONoVEC(A6),-(A7) Save current output device name
         MOVE.L   CONiVEC(A6),-(A7) Save current input device name
         MOVE.L   #DCB4,CONoVEC(A6) Set up aux ACIA as output
         MOVE.L   #DCB3,CONiVEC(A6) Set up aux ACIA as input
         ADD.B    #1,ECHO(A6)       Turn off character echo
         BSR      NEWLINE           Send newline to host
         BSR      DELAY             Wait for host to "settle"
         BSR      DELAY
         MOVE.L   BUFPT(A6),A4      Any string in the line buffer is
LOAD1    MOVE.B   (A4)+,D0          transmitted to the host computer
         BSR      PUTCHAR           before the loading begins
         CMP.B    #CR,D0            Read from the buffer until EOL
         BNE      LOAD1
         BSR      NEWLINE           Send newline before loading
LOAD2    BSR      GETCHAR           Records from the host must begin
         CMP.B    #'S',D0           with S1/S2 (data) or S9/S8 (term)
         BNE.S    LOAD2             Repeat GETCHAR until char = "S"
         BSR      GETCHAR           Get character after "S"
         CMP.B    #'9',D0           Test for the two terminators S9/S8
         BEQ.S    LOAD3             If S9 record then exit else test
         CMP.B    #'8',D0           for S8 terminator. Fall through to
         BNE.S    LOAD6             exit on S8 else continue search
LOAD3    EQU      *                 Exit point from LOAD
         MOVE.L   (A7)+,CONiVEC(A6) Clean up by restoring input device
         MOVE.L   (A7)+,CONoVEC(A6) and output device name
         CLR.B    ECHO(A6)          Restore input character echo
         BTST     #0,D7             Test for input errors
         BEQ.S    LOAD4             If no I/P error then look at checksum
         LEA.L    ERMES1,A4         Else point to error message
         BSR      PRINTSTRING       Print it
LOAD4    BTST     #3,D7             Test for checksum error
         BEQ.S    LOAD5             If clear then exit
         LEA.L    ERMES3,A4         Else point to error message
         BSR      PRINTSTRING       Print it and return
LOAD5    RTS
LOAD6    CMP.B    #'1',D0           Test for S1 record
         BEQ.S    LOAD6A            If S1 record then read it
         CMP.B    #'2',D0           Else test for S2 record
         BNE.S    LOAD2             Repeat until valid header found
         CLR.B    D3                Read the S2 byte count and address,
         BSR.S    LOAD8             clear the checksum
         SUB.B    #4,D0             Calculate size of data field
         MOVE.B   D0,D2             D2 contains data bytes to read
         CLR.L    D0                Clear address accumulator
         BSR.S    LOAD8             Read most sig byte of address
         ASL.L    #8,D0             Move it one byte left
         BSR.S    LOAD8             Read the middle byte of address
         ASL.L    #8,D0             Move it one byte left
         BSR.S    LOAD8             Read least sig byte of address
         MOVE.L   D0,A2             A2 points to destination of record
         BRA.S    LOAD7             Skip past S1 header loader
LOAD6A   CLR.B    D3                S1 record found - clear checksum
         BSR.S    LOAD8             Get byte and update checksum
         SUB.B    #3,D0             Subtract 3 from record length
         MOVE.B   D0,D2             Save byte count in D2
         CLR.L    D0                Clear address accumulator
         BSR.S    LOAD8             Get MS byte of load address
         ASL.L    #8,D0             Move it to MS position
         BSR.S    LOAD8             Get LS byte in D2
         MOVE.L   D0,A2             A2 points to destination of data
LOAD7    BSR.S    LOAD8             Get byte of data for loading
         MOVE.B   D0,(A2)+          Store it
         SUB.B    #1,D2             Decrement byte counter
         BNE      LOAD7             Repeat until count = 0
         BSR.S    LOAD8             Read checksum
         ADD.B    #1,D3             Add 1 to total checksum
         BEQ      LOAD2             If zero then start next record
         OR.B     #%00001000,D7     Else set checksum error bit,
         BRA      LOAD3             restore I/O devices and return
*
LOAD8    BSR     BYTE               Get a byte
         ADD.B   D0,D3              Update checksum
         RTS                         and return


							  *
****************************************							*************************
* MFP Transmit/Receive										*************************	
												*************************
printString	EQU	*									*****
.loop		MOVE.B	(A0)+,D0	Read character data					*****	
		BEQ.S	.printEnd	Check for null terminator				*****		**
		BSR.S	outChar		Write the character					*****		****
		BRA.S	.loop		Loop until null found					**********************
.printEnd	RTS										************************
												**********************
outChar		BSET.B  #7,MFPGPDR	Negate RTS to inhibit receiving				*****		****
.outloop	BTST.B	#7,MFPTSR	Check for empty transmit buffer				*****		**
		BEQ.S	.outloop	Loop until ready					*****
		MOVE.B	D0,MFPUDR	Put character into USART data register			*****
		RTS			ELSE RETURN WHEN COMPLETED				*****
										*********************
										*********************
										*********************

*****************************************************************************************************
*****************************************************************************************************
* DEVICE SECTION										*****
												*****
****************************************							*****
*  DEVICE CONTROL BLOCKS									*****
												*****
SET_DCB		MOVEM.L	A0-A3/D0-D3,-(A7)							*****
		LEA	FIRST(A6),A0	POINTER TO FIRST DDB RAM DESTINATION			*****
		LEA	DCB_LST,A1	POINTER TO FIRST DCB ROM DECLARATION			*****
		MOVE.W	#3,D0		4 DCB(s) TO SET UP (N-1)				*****
SET_DCB1	MOVE.W	#15,D1		16 BYTE DCB HEADER					*****
SET_DCB2	MOVE.B	(A1)+,(A0)+	MOVE BYTE FROM ROM TO RAM				*****
		DBRA	D1,SET_DCB2	REPEAT FOR ENTIRE HEADER				*****
		MOVE.W	(A1)+,D3	GET NUMBER OF BYTES IN PARAMETER BLOCK			*****
		MOVE.W	D3,(A0)		STORE SIZE OF DCB IN RAM				*****
		LEA	2(A0,D3.W),A0	A0 NOW POINTS TO END OF DCB IN RAM			*****
		LEA	4(A0),A3	A3 POINTS TO ADDRESS OF NEXT DCB IN RAM			*****
		MOVE.L	A3,(A0)		STORE POINTER TO NEXT DCB IN THIS ONE			*****
		LEA	(A3),A0		A0 NOW POINTS TO NEXT DCB IN RAM			*****
		DBRA	D0,SET_DCB1	REPEAT FOR ALL DCBs					*****
		LEA	-4(A3),A3	A3 POINTS TO LAST DCB POINTER				*****
		CLR.L	(A3)		LAST POINTER IS ZEROED FOR NULL TERMINATION		*****
		MOVE.L	#DCB1,CONiVEC(A6)	SET VECTOR TO CONSOLE INPUT DCB			*****
		MOVE.L	#DCB2,CONoVEC(A6)	SET VECTOR TO CONSOLE OUTPUT DCB		*****
		MOVEM.L	(A7)+,A0-A3/D0-D3							*****
		RTS										*****
												*****
DCB_LST		EQU	*									*****
DCB1		DC.B	'CON_IN  ' ;	DEVICE NAME						*****
		DC.L	CON_IN,MFPBAS 	ADDRESS OF DRIVER ROUTINE, DEVICE			*****
		DC.W	2		NUMBER OF PARAMETER WORDS				*****
DCB2		DC.B	'CON_OUT ' ;	DEVICE NAME						*****
		DC.L	CON_OUT,MFPBAS	ADDRESS OF DRIVER ROUTINE, DEVICE			*****
		DC.W	2		NUMBER OF PARAMETER WORDS				*****
DCB3		DC.B	'BUF_IN  ' ;	DEVICE NAME						*****
		DC.L	BUFF_IN,BUFFER	ADDRESS OF DRIVER ROUTINE, DEVICE			*****
		DC.W	2		NUMBER OF PARAMETER WORDS				*****
DCB4		DC.B	'BUF_OUT ' ;	DEVICE NAME						*****
		DC.L	BUFF_OUT,BUFFER	ADDRESS OF DRIVER ROUTINE, DEVICE			*****
		DC.W	2		NUMBER OF PARAMETER WORDS				*****


****************************************							*****
*  MC68901 INITIALIZATION									*****
												*****
MFPINIT		EQU	*		MC68901 INITIALIZATION ROUTINE				*****
		CLR.L	D0		CLEAR D0						*****
		SUBQ	#1,D0		THEN TURN INTO ALL 1's					*****
		MOVE.B	D0,MFPDDR	ALL MFP I/O INITIALIZED TO OUTPUT			*****
		ADDQ	#2,D0		NOW TURN D0 INTO 1					*****
		MOVE.B	#$0C,MFPTDDR	TIMER D 0x0C for 19.2KHz				*****
		MOVE.B	#$01,MFPTCDCR	SELECT DIVIDE BY 4 IN D CONTROL REGISTER		*****
		MOVE.B	#$08,MFPUCR	SELECT FUNDAMENTAL CLOCK, 8-BIT				*****
*					NO PARITY IN USART CONTROL REGISTER			*****
												*****
*		INITIALIZE MFP VECTOR AND HANDLER						*****
		MOVE.L	#MFPVCT,D0	GET VECTOR						*****
		MOVE.B	D0,MFPVR	LOAD INTO MFP						*****
		ASL.L	#2,D0		NOW SHIFT LEFT 2					*****
		ADDI.L  #RAMBAS,D0								*****
		MOVE.L	D0,A0		PUT INTO ADDRESS REGISTER				*****
		MOVE.L	#MFPEXC,(A0)	AND INIT APPROPRIATE VECTOR				*****
												*****
*		START TX/RX CLOCKS								*****
		MOVE.B	#1,MFPRSR	START RECEIVER CLOCK					*****
		MOVE.B	#5,MFPTSR	START TRANSMIT CLOCK				     ***********
		BSET.B	#7,MFPGPDR	RAISE RTS (INHIBIT RX)				      *********
											       *******
		RTS			DONE!  RETURN FROM ROUTINE				*****	
												 ***
												  *

*****************************************************************************************************
*****************************************************************************************************
* EXCEPTION HANDLERS										*****
												*****
****************************************							*****
*   Generic Exception Handler									*****
												*****
EXCHND		EQU	*		GENERIC EXCEPTION HANDLER				*****
		RTE										*****
ER_ILOP	EQU      *                Illegal instruction exception
        MOVE.L  A4,-(A7)          Save A4
        LEA.L   MES10,A4          Point to heading
        BSR     HEADING           Print it
        MOVE.L  (A7)+,A4          Restore A4
        BSR.S   GROUP2            Save registers in display frame
        BSR     EX_DIS            Display registers saved in frame
        BRA     WARM              Abort from illegal instruction
*
ER_BUS	EQU     *                 Bus error (group 1) exception
        MOVE.L  A4,-(A7)          Save A4
        LEA.L   MES8,A4           Point to heading
        BSR     HEADING           Print it
        MOVE.L  (A7)+,A4          Restore A4
        BRA.S   GROUP1            Deal with group 1 exception
*
ER_ADDR	EQU     *                 Address error (group 1) exception
        MOVE.L  A4,-(A7)          Save A4
        LEA.L   MES9,A4           Point to heading
        BSR     HEADING           Print it
        MOVE.L  (A7)+,A4          Restore A4
        BRA.S   GROUP1            Deal with group 1 exception

BRKPT   EQU     *                   Deal with breakpoint
        MOVEM.L D0-D7/A0-A6,-(A7)   Save all registers
        BSR     BR_CLR              Clear breakpoints in code
        MOVEM.L (A7)+,D0-D7/A0-A6   Restore registers
        BSR.S   GROUP2            Treat as group 2 exception
        LEA.L   MES11,A4      Point to heading
        BSR     HEADING           Print it
        BSR     EX_DIS            Display saved registers
        BRA     WARM              Return to monitor

*       GROUP1 is called by address and bus error exceptions
*       These are "turned into group 2" exceptions (eg TRAP)
*       by modifying the stack frame saved by a group 1 exception
*
GROUP1  MOVEM.L D0/A0,-(A7)       Save working registers
        MOVE.L  18(A7),A0         Get PC from group 1 stack frame
        MOVE.W  14(A7),D0         Get instruction from stack frame
        CMP.W   -(A0),D0          Now backtrack to find the "correct PC"
        BEQ.S   GROUP1A           by matching the op-code on the stack
        CMP.W   -(A0),D0          with the code in the region of the
        BEQ.S   GROUP1A           PC on the stack
        CMP.W   -(A0),D0
        BEQ.S   GROUP1A
        CMP.W   -(A0),D0
        BEQ.S   GROUP1A
        SUBQ.L  #2,A0
GROUP1A MOVE.L  A0,18(A7)          Restore modified PC to stack frame
        MOVEM.L (A7)+,D0/A0        Restore working registers
        LEA.L   8(A7),A7           Adjust stack pointer to group 1 type
        BSR.S   GROUP2             Now treat as group 1 exception
        BSR     EX_DIS             Display contents of exception frame
        BRA     WARM               Exit to monitor - no RTE from group 2

GROUP2  EQU     *                 Deal with group 2 exceptions
        MOVEM.L A0-A7/D0-D7,-(A7) Save all registers on the stack
        MOVE.W  #14,D0            Transfer D0 - D7, A0 - A6 from
        LEA.L   TSK_T(A6),A0      the stack to the display frame
GROUP2A MOVE.L  (A7)+,(A0)+       Move a register from stack to frame
        DBRA    D0,GROUP2A        and repeat until D0-D7/A0-A6 moved
        MOVE.L  USP,A2            Get the user stack pointer and put it
        MOVE.L  A2,(A0)+          in the A7 position in the frame
        MOVE.L  (A7)+,D0          Now transfer the SSP to the frame,
        SUB.L   #10,D0            remembering to account for the
        MOVE.L  D0,(A0)+          data pushed on the stack to this point
        MOVE.L  (A7)+,A1          Copy TOS (return address) to A1
        MOVE.W  (A7)+,(A0)+       Move SR to display frame
        MOVE.L  (A7)+,D0          Get PC in D0
        SUBQ.L  #2,D0             Move back to current instruction
        MOVE.L  D0,(A0)+          Put adjusted PC in display frame
        JMP     (A1)              Return from subroutine

												*****
****************************************							*****
*   MFP Exception Handler									*****
											     ***********
MFPEXC		EQU	*								      *********
		RTE									       *******
												*****
												 *** 
												  *

*****************************************************************************************************
*****************************************************************************************************
* STRINGS AND FIXED PARAMETERS									*****
                section .rodata									*****
                                                                                                *****
msgPOR		DC.B	'<RESET>',CR,LF,0							*****
msgLORAMck	DC.B	'Checking low memory...            ',0					*****
msgOK		DC.B	'OK',CR,LF,0								*****
msgEXTABinit	DC.B	'Initializing Exception Table...   ',0					*****
msgDCBinit	DC.B	'Creating Device Control Blocks... ',0					*****
msgColonSpc	DC.B	': ',0									*****
												*****
BANNER		DC.B	'RHOMBUS Monitor version 0.2017.07.12.0',0,0				*****
CRLF		DC.B	CR,LF,0									*****
PROMPT		DC.B	CR,LF,'>',0								*****
EXPROMPT	DC.B	CR,LF,'EX>',0								*****
HEADER		DC.B	CR,LF,'S','1',0,0							*****
TAIL		DC.B	'S9  ',0,0								*****
MES1		DC.B	' SR  =  ',0
MES2		DC.B	' PC  =  ',0
MES2A		DC.B	' SS  =  ',0
MES3		DC.B	'  Data reg       Address reg',0,0
MES4		DC.B	'        ',0,0
MES8		DC.B	'Bus error   ',0,0
MES9		DC.B	'Address error   ',0,0
MES10		DC.B	'Illegal instruction ',0,0
MES11		DC.B	'Breakpoint  ',0,0
MES12		DC.B	'Trace   ',0
REGNAME		DC.B	'D0D1D2D3D4D5D6D7'
		DC.B	'A0A1A2A3A4A5A6A7'
		DC.B	'SSSR'
		DC.B	'PC  ',0
ERMES1		DC.B	'Non-valid hexadecimal input  ',0
ERMES2		DC.B	'Invalid command  ',0
ERMES3		DC.B	'Loading error',0
ERMES4		DC.B	'Table full  ',0,0
ERMES5		DC.B	'Breakpoint not active   ',0,0
ERMES6		DC.B	'Uninitialized exception ',0,0
ERMES7		DC.B	' Range error',0

COMTAB		DC.B	8,3		MEMORY <address> shows contents of			*****
		DC.B	'MEMORY  ' ;	<address> and allows them to be changed			*****
		DC.L	MEMORY-COMTAB								*****
		DC.B	8,2		EXAMINE <address> shows memory contents			*****
		DC.B	'EXAMINE ' ;	in a more readable form, does not allow modifications	*****
		DC.L	EXAMINE-COMTAB								*****
		DC.B	4,2		DISP displays the contents of the			*****
		DC.B	'DISP'	;	pseudo registers in TSK_T				*****
		DC.L	EX_DIS-COMTAB								*****
		DC.B	4,3									*****
		DC.B	'REG '	;	REG <register> <value> loads <value> into <register>	*****
		DC.L	REG_MOD-COMTAB	at TSK_T used to preload register for GO or GB		*****
		DC.B	4,2		GO <address> starts program execution
		DC.B	'GO  '	;	at <address> and loads regs from TSK_T
		DC.L	GO-COMTAB
		DC.B	4,2									*****
		DC.B	'GB  '	;	GB <address> sets breakpoints and then calls GO		*****
		DC.L	GB-COMTAB								*****
                DC.B	4,4		JUMP <address> causes execution to
		DC.B	'JUMP'	;	begin at <address>
		DC.L	JUMP-COMTAB 
		DC.B	4,2		LOAD <string> loads S1/S2 records
		DC.B	'LOAD'	;	from the host. <string> is sent to host
		DC.L	LOAD-COMTAB
		DC.B	0,0		TERMINATE COMMAND TABLE					*****
****************************************							*****
*   Environment Parameter Equates								*****
												*****
MAXCHR		EQU	64		MAXIMUM LENGTH OF COMMAND LINE				*****
		ORG	$1800
DATA		EQU	$00001800	DATA ORIGIN						*****
LNBUF		DS.B	MAXCHR		COMMAND LINE BUFFER					*****
BUFEND		EQU	LNBUF+MAXCHR-1	END OF COMMAND LINE POINTER				*****
BUFPT		DS.L	1		COMMAND LINE POINTER					*****
PARAMETER	DS.L	1		LAST COMMAND LINE PARAMETER				*****
ECHO		DS.B	1		LOCAL ECHO ON CLEAR					*****
UCASE		DS.B	1		UPPER CASE CONVERSION FLAG				*****
UCOMTAB		DS.L	1		USER COMMAND TABLE POINTER				*****
CONiVEC		DS.L	1		CONSOLE INPUT DCB POINTER				*****
CONoVEC		DS.L	1		CONSOLE OUTPUT DCB POINTER				*****
TSK_T		DS.W	37		FRAME: D0-D7/A0-A6/USB/SSP/SW/PC			*****
BKPTAB		DS.W	24		BREAKPOINT TABLE					*****
FIRST		DS.B	512		DCB AREA						*****
BUFFER		DS.B	256		256 BYTE I/O BUFFER					*****
												*****

		END	START												  

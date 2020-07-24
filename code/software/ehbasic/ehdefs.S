* This lot is in RAM

*       ORG     $0			* start of RAM
 
ram_strt	ds.l	$100			* allow 1K for the stack, this should be plenty
						* for any BASIC program that doesn't do something
						* silly, it could even be much less.
ram_base
LAB_WARM	ds.w	1			* BASIC warm start entry point
Wrmjpv	ds.l	1			* BASIC warm start jump vector

Usrjmp	ds.w	1			* USR function JMP address
Usrjpv	ds.l	1			* USR function JMP vector

* system dependant i/o vectors
* these are in RAM and are set at start-up

V_INPT	ds.w	1			* non halting scan input device entry point
V_INPTv	ds.l	1			* non halting scan input device jump vector

V_OUTP	ds.w	1			* send byte to output device entry point
V_OUTPv	ds.l	1			* send byte to output device jump vector

V_LOAD	ds.w	1			* load BASIC program entry point
V_LOADv	ds.l	1			* load BASIC program jump vector

V_SAVE	ds.w	1			* save BASIC program entry point
V_SAVEv	ds.l	1			* save BASIC program jump vector

V_CTLC	ds.w	1			* save CTRL-C check entry point
V_CTLCv	ds.l	1			* save CTRL-C check jump vector

Itemp		ds.l	1			* temporary integer	(for GOTO etc)

Smeml		ds.l	1			* start of memory		(start of program)

* the program is stored as a series of lines each line having the following format
*
*		ds.l	1			* pointer to the next line or $00000000 if [EOT]
*		ds.l	1			* line number
*		ds.b	n			* program bytes
*		dc.b	$00			* [EOL] marker, there will be a second $00 byte, if
*						* needed, to pad the line to an even number of bytes

Sfncl		ds.l	1			* start of functions	(end of Program)

* the functions are stored as function name, function execute pointer and function
* variable name
*
*		ds.l	1			* name
*		ds.l	1			* execute pointer
*		ds.l	1			* function variable

Svarl		ds.l	1			* start of variables	(end of functions)

* the variables are stored as variable name, variable value
*
*		ds.l	1			* name
*		ds.l	1			* packed float or integer value

Sstrl		ds.l	1			* start of strings	(end of variables)

* the strings are stored as string name, string pointer and string length
*
*		ds.l	1			* name
*		ds.l	1			* string pointer
*		ds.w	1			* string length

Sarryl	ds.l	1			* start of arrays		(end of strings)

* the arrays are stored as array name, array size, array dimensions count, array
* dimensions upper bounds and array elements
*
*		ds.l	1			* name
*		ds.l	1			* size including this header
*		ds.w	1			* dimensions count
*		ds.w	1			* 1st dimension upper bound
*		ds.w	1			* 2nd dimension upper bound
*		...				* ...
*		ds.w	1			* nth dimension upper bound
*
* then (i1+1)*(i2+1)...*(in+1) of either ..
*
*		ds.l	1			* packed float or integer value
*
* .. if float or integer, or ..
*
*		ds.l	1			* string pointer
*		ds.w	1			* string length
*
* .. if string

Earryl	ds.l	1			* end of arrays		(start of free mem)
Sstorl	ds.l	1			* string storage		(moving down)
Ememl		ds.l	1			* end of memory		(upper bound of RAM)
Sutill	ds.l	1			* string utility ptr
Clinel	ds.l	1			* current line		(Basic line number)
Blinel	ds.l	1			* break line		(Basic line number)

Cpntrl	ds.l	1			* continue pointer
Dlinel	ds.l	1			* current DATA line
Dptrl		ds.l	1			* DATA pointer
Rdptrl	ds.l	1			* read pointer
Varname	ds.l	1			* current var name
Cvaral	ds.l	1			* current var address
Lvarpl	ds.l	1			* variable pointer for LET and FOR/NEXT

des_sk_e	ds.l	6			* descriptor stack end address
des_sk					* descriptor stack start address
						* use a4 for the descriptor pointer
		ds.w	1			
Ibuffs	ds.l	$40			* start of input buffer
Ibuffe
						* end of input buffer

FAC1_m	ds.l	1			* FAC1 mantissa1
FAC1_e	ds.w	1			* FAC1 exponent
FAC1_s	EQU	FAC1_e+1		* FAC1 sign (b7)
		ds.w	1			

FAC2_m	ds.l	1			* FAC2 mantissa1
FAC2_e	ds.l	1			* FAC2 exponent
FAC2_s	EQU	FAC2_e+1		* FAC2 sign (b7)
FAC_sc	EQU	FAC2_e+2		* FAC sign comparison, Acc#1 vs #2
flag		EQU	FAC2_e+3		* flag byte for divide routine

PRNlword	ds.l	1			* PRNG seed long word

ut1_pl	ds.l	1			* utility pointer 1

Asptl		ds.l	1			* array size/pointer
Astrtl	ds.l	1			* array start pointer

numexp	EQU	Astrtl		* string to float number exponent count
expcnt	EQU	Astrtl+1		* string to float exponent count

expneg	EQU	Astrtl+3		* string to float eval exponent -ve flag

func_l	ds.l	1			* function pointer


						* these two need to be a word aligned pair !
Defdim	ds.w	1			* default DIM flag
cosout	EQU	Defdim		* flag which CORDIC output (re-use byte)
Dtypef	EQU	Defdim+1		* data type flag, $80=string, $40=integer, $00=float


Binss		ds.l	4			* number to bin string start (32 chrs)

Decss		ds.l	1			* number to decimal string start (16 chrs)
		ds.w	1			*
Usdss		ds.w	1			* unsigned decimal string start (10 chrs)

Hexss		ds.l	2			* number to hex string start (8 chrs)

BHsend	ds.w	1			* bin/decimal/hex string end


prstk		ds.b	1			* stacked function index

tpower	ds.b	1			* remember CORDIC power

Asrch		ds.b	1			* scan-between-quotes flag, alt search character

Dimcnt	ds.b	1			* # of dimensions

Breakf	ds.b	1			* break flag, $00=END else=break
Oquote	ds.b	1			* open quote flag (Flag: DATA; LIST; memory)
Gclctd	ds.b	1			* garbage collected flag
Sufnxf	ds.b	1			* subscript/FNX flag, 1xxx xxx = FN(0xxx xxx)
Imode		ds.b	1			* input mode flag, $00=INPUT, $98=READ

Cflag		ds.b	1			* comparison evaluation flag

TabSiz	ds.b	1			* TAB step size

comp_f	ds.b	1			* compare function flag, bits 0,1 and 2 used
						* bit 2 set if >
						* bit 1 set if =
						* bit 0 set if <

Nullct	ds.b	1			* nulls output after each line
TPos		ds.b	1			* BASIC terminal position byte
TWidth	ds.b	1			* BASIC terminal width byte
Iclim		ds.b	1			* input column limit
ccflag	ds.b	1			* CTRL-C check flag
ccbyte	ds.b	1			* CTRL-C last received byte
ccnull	ds.b	1			* CTRL-C last received byte 'life' timer

* these variables for simulator load/save routines

file_byte	ds.b	1			* load/save data byte
file_id	ds.l	1			* load/save file ID

		even			        * dummy even value and zero pad byte

prg_strt

* Use these two lines when running from ROM
*ram_addr	EQU	$02000		* RAM start address
*ram_size	EQU	$06000		* RAM size

* Use these two lines when running from RAM
ram_addr	EQU	$01000		* RAM start address
ram_size	EQU	$1F000		* RAM size

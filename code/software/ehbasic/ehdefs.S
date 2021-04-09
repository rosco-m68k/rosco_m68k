* This lot is in RAM

*       ORG     $0			* start of RAM

ram_strt	equ	0
					* for any BASIC program that doesn't do something
					* silly, it could even be much less.
ram_base	equ	$0400
LAB_WARM	equ	$0400		* BASIC warm start entry point
Wrmjpv		equ	$0402		* BASIC warm start jump vector

Usrjmp		equ	$0406		* USR function JMP address
Usrjpv		equ	$0408

* system dependant i/o vectors
* these are in RAM and are set at start-up

V_INPT		equ	$040c		* non halting scan input device entry point
V_INPTv		equ	$040e		* non halting scan input device jump vector

V_OUTP		equ	$0412		* send byte to output device entry point
V_OUTPv		equ	$0414		* send byte to output device jump vector

V_LOAD		equ	$0418		* load BASIC program entry point
V_LOADv		equ	$041a		* load BASIC program jump vector

V_SAVE		equ	$041e		* save BASIC program entry point
V_SAVEv		equ	$0420		* save BASIC program jump vector

V_CTLC		equ	$0424		* save CTRL-C check entry point
V_CTLCv		equ	$0426		* save CTRL-C check jump vector

Itemp		equ	$042a		* temporary integer	(for GOTO etc)

Smeml		equ	$042e		* start of memory		(start of program)

* the program is stored as a series of lines each line having the following format
*
*		ds.l	1			* pointer to the next line or $00000000 if [EOT]
*		ds.l	1			* line number
*		ds.b	n			* program bytes
*		dc.b	$00			* [EOL] marker, there will be a second $00 byte, if
*						* needed, to pad the line to an even number of bytes

Sfncl		equ	$0432			* start of functions	(end of Program)

* the functions are stored as function name, function execute pointer and function
* variable name
*
*		ds.l	1			* name
*		ds.l	1			* execute pointer
*		ds.l	1			* function variable

Svarl		equ	$0436			* start of variables	(end of functions)

* the variables are stored as variable name, variable value
*
*		ds.l	1			* name
*		ds.l	1			* packed float or integer value

Sstrl		equ	$043a			* start of strings	(end of variables)

* the strings are stored as string name, string pointer and string length
*
*		ds.l	1			* name
*		ds.l	1			* string pointer
*		ds.w	1			* string length

Sarryl		equ	$043e			* start of arrays		(end of strings)

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

Earryl		equ	$0442		* end of arrays		(start of free mem)
Sstorl		equ	$0446		* string storage	(moving down)
Ememl		equ	$044a		* end of memory		(upper bound of RAM)
Sutill		equ	$044e		* string utility ptr
Clinel		equ	$0452		* current line		(Basic line number)
Blinel		equ	$0456		* break line		(Basic line number)

Cpntrl		equ	$045a		* continue pointer
Dlinel		equ	$045e		* current DATA line
Dptrl		equ	$0462		* DATA pointer
Rdptrl		equ	$0466		* read pointer
Varname		equ	$046a		* current var name
Cvaral		equ	$046e		* current var address
Lvarpl		equ	$0472		* variable pointer for LET and FOR/NEXT

des_sk_e	equ	$0476		* descriptor stack end address
des_sk		equ	$048e		* descriptor stack start address
					* use a4 for the descriptor pointer
			
Ibuffs		equ	$0490		* start of input buffer
Ibuffe		equ	$0590
					* end of input buffer

FAC1_m		equ	$0590		* FAC1 mantissa1
FAC1_e		equ	$0594		* FAC1 exponent
FAC1_s		equ	FAC1_e+1	* FAC1 sign (b7)		

FAC2_m		equ	$0598		* FAC2 mantissa1
FAC2_e		equ	$059c		* FAC2 exponent
FAC2_s		equ	FAC2_e+1	* FAC2 sign (b7)
FAC_sc		equ	FAC2_e+2	* FAC sign comparison, Acc#1 vs #2
flag		equ	FAC2_e+3	* flag byte for divide routine

PRNlword	equ	$05a0		* PRNG seed long word

ut1_pl		equ	$05a4		* utility pointer 1

Asptl		equ	$05a8		* array size/pointer
Astrtl		equ	$05ac		* array start pointer

numexp		equ	Astrtl		* string to float number exponent count
expcnt		equ	Astrtl+1	* string to float exponent count

expneg		equ	Astrtl+3	* string to float eval exponent -ve flag

func_l		equ	$05b0		* function pointer


					* these two need to be a word aligned pair !
Defdim		equ	$05b4		* default DIM flag
cosout		equ	Defdim		* flag which CORDIC output (re-use byte)
Dtypef		equ	Defdim+1	* data type flag, $80=string, $40=integer, $00=float


Binss		equ	$05b6		* number to bin string start (32 chrs)

Decss		equ	$05c6		* number to decimal string start (16 chrs)
					*
Usdss		equ	$05cc		* unsigned decimal string start (10 chrs)

Hexss		equ	$05ce		* number to hex string start (8 chrs)

BHsend		equ	$05d6		* bin/decimal/hex string end


prstk		equ	$05d8		* stacked function index

tpower		equ	$05d9		* remember CORDIC power

Asrch		equ	$05da		* scan-between-quotes flag, alt search character

Dimcnt		equ	$05db		* # of dimensions

Breakf		equ	$05dc		* break flag, $00=END else=break
Oquote		equ	$05dd		* open quote flag (Flag: DATA; LIST; memory)
Gclctd		equ	$05de		* garbage collected flag
Sufnxf		equ	$05df		* subscript/FNX flag, 1xxx xxx = FN(0xxx xxx)
Imode		equ	$05e0		* input mode flag, $00=INPUT, $98=READ

Cflag		equ	$05e1		* comparison evaluation flag

TabSiz		equ	$05e2		* TAB step size

comp_f		equ	$05e3		* compare function flag, bits 0,1 and 2 used
						* bit 2 set if >
						* bit 1 set if =
						* bit 0 set if <

Nullct		equ	$05e4		* nulls output after each line
TPos		equ	$05e5		* BASIC terminal position byte
TWidth		equ	$05e6		* BASIC terminal width byte
Iclim		equ	$05e7		* input column limit
ccflag		equ	$05e8		* CTRL-C check flag
ccbyte		equ	$05e9		* CTRL-C last received byte
ccnull		equ	$05ea		* CTRL-C last received byte 'life' timer

* these variables for simulator load/save routines

file_byte	equ	$05eb		* load/save data byte
file_id		equ	$05ec		* load/save file ID

prg_strt	equ	$05f0		* start of BASIC program

* Use these two lines when running from ROM
*ram_addr	EQU	$02000		* RAM start address
*ram_size	EQU	$06000		* RAM size

* Use these two lines when running from RAM
ram_addr	EQU	$01000		* RAM start address
ram_size	EQU	$1F000		* RAM size

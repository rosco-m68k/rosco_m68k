# rosco_m68k Firmware - Memory & Interfaces
## Firmware revision 1.1

This document describes the interfaces provided for programmers,
hardware integrators and those expanding the rosco_m68k, as it
applies to firmware revision 1.1. 

The information contained herein is accurate and complete as far
as possible, and will be kept updated as firmware 1.1 is developed.

# Contents

* 1. TRAP Interfaces for User Code
  * 1.1. Basic IO routines (TRAP 14)
    * 1.1.1 Example Usage
    * 1.1.2 Functions
      * 1.1.2.1 PRINT (Function #0)
      * 1.1.2.2 PRINTLN (Function #1)
      * 1.1.2.3 SENDCHAR (Function #2)
      * 1.1.2.4 RECVCHAR (Function #3)
  * 1.2. Easy68k compatibility layer (TRAP 15)
    * 1.2.1 Example Usage
    * 1.2.2 Functions
      * 1.2.2.1 PRINTLN_LEN (Function #0)
      * 1.2.2.2 PRINT_LEN (Function #1)
      * 1.2.2.3 READSTR (Function #2)
      * 1.2.2.4 DISPLAYNUM_SIGNED (Function #3)
      * 1.2.2.5 READNUM (Function #4)
      * 1.2.2.6 READCHAR (Function #5)
      * 1.2.2.7 SENDCHAR (Function #6)
      * 1.2.2.8 CHECKINPUT (Function #7)
      * 1.2.2.9 GETUPTICKS (Function #8)
      * 1.2.2.10 TERMINATE (Function #9)
      * 1.2.2.11 MOVEXY (Function #11)
      * 1.2.2.12 SETECHO (Function #12)
      * 1.2.2.13 PRINTLN_SZ (Function #13)
      * 1.2.2.14 PRINT_SZ (Function #14)
      * 1.2.2.15 PRINT_UNSIGNED (Function #15)
      * 1.2.2.16 SETDISPLAY (Function #16)
      * 1.2.2.17 PRINTSZ_NUM (Function #17)
      * 1.2.2.18 PRINTSZ_NUM (Function #18)
      * 1.2.2.19 PRINTSZ_NUM (Function #20)
* 2. System Data Area memory map
  * 2.1. Exception vectors
  * 2.2. Basic System Data Block (SDB)
  * 2.3. Extension Function Pointer Table (EFPT)
  * 2.4. Video IO Data Area (VDA)

# 1. TRAP Interfaces for User Code

The firmware provides a set of basic IO routines intended for use
from user code. Because some of these routines may require the CPU
to be in Supervisor mode, they are accessed via the M68k TRAP
instruction. Execution of this instruction causes the CPU to jump
to an exception vector (initialized by the firmware) as if an
exception were being processed. Context is stored on the stack
and Supervisor mode is entered automatically.

Currently, two TRAPs are used by the firmware:

* TRAP 14 provides rosco_m68k's native basic input/output routines
* TRAP 15 provides basic IO routines that are broadly Easy68k-compatible(*)

All other TRAP vectors are unused at boot-time (and initialized to no-op
handlers). Extension code, drivers and user code are free to re-use
these vectors as they see fit.

The standard TRAP handlers use various registers as arguments, and
may also use one or more registers to return values to the 
calling code. These registers are documented in the following 
sections. In all cases, all registers other than those stated
in this documentation are preserved.

**Note** that the standard firmware TRAP handlers rely on the 
integrity of the System Data Area in memory. If this area is
reused or corrupted, these routines may not function properly.

(*) Note that the Easy68k layer may optionally be omitted from the 
firmware build. In such cases, the functions offered on TRAP 15 will
not be available, and that TRAP vector may be reused.

## 1.1. Basic IO routines (TRAP 14)

TRAP 14 provides access to the basic IO functionality provided by
the firmware.

Register D1.L is expected to contain the function code. Other arguments
depend on the specific function, and are documented below.

In all cases, registers used as aguments (including D1.L) are **not** 
guaranteed to be preserved. All other registers are preserved.

Function codes outside the range documented here are considered
reserved for future expansion, and should not be used by integrators
or other code. The exception to this is where the user program 
is intended to take complete control of the system, in which case
the TRAP handlers, and the SDA that underpins them, may be entirely
replaced in the scope of that program.

### 1.1.1 Example Usage

An example of calling function 1 (PRINTLN) of TRAP 14 is:

```
DO_PRINTLN:
    move.l  #1,D1
    lea.l   MYSTRING,A0
    trap    #14

; ... later

MYSTRING    dc.b    "Hello, World!", 0
```

### 1.1.2 Functions

#### 1.1.2.1 PRINT (Function #0)

**Arguments**

* `D1.L` - 0 (Function code)
* `A0`   - Pointer to null-terminated string to print

**Modifies**

* `D1.L` - May be modified arbitrarily
* `A0`   - Will point to the memory location following the null terminator

**Description**

Print the null-terminated string pointed to by `A0` to the system's
*default console*. 

Where the default console is a serial terminal, this routine may block until
there is space in the UART's transmit buffer for the character - as such, 
it is not suitable for use in time- or latency-critical code (e.g. interrupt 
handlers).

The default console is initialized at boot-time by the firmware, and 
may be the V9958 console (where available), or the *default serial UART*.
For details on the default UART, see the `SENDCHAR` function.

System integrators and third-party hardware developers may also override
the default console (for example to output to third-party video 
hardware). See section 2.3 for details.

#### 1.1.2.2 PRINTLN (Function #1)

**Arguments**

* `D1.L` - 1 (Function code)
* `A0`   - Pointer to null-terminated string to print

**Modifies**

* `D1.L` - May be modified arbitrarily
* `A0`   - Will point to the memory location following the null terminator

**Description**

Print the null-terminated string pointed to by `A0` to the system's
*default console* followed by a CR/LF sequence.

Where the default console is a serial terminal, this routine may block until
there is space in the UART's transmit buffer for the character - as such, 
it is not suitable for use in time- or latency-critical code (e.g. interrupt 
handlers).

The default console is initialized at boot-time by the firmware, and 
may be the V9958 console (where available), or the *default serial UART*.
For details on the default UART, see the `SENDCHAR` function.

System integrators and third-party hardware developers may also override
the default console (for example to output to third-party video 
hardware). See section 2.3 for details.

#### 1.1.2.3 SENDCHAR (Function #2)

**Arguments**

* `D1.L` - 2 (Function code)
* `D0.B` - Character to send

**Modifies**

Nothing

**Description**

Synchronously send the character contained in `D0.B` via the system's
*default UART*. This routine may block until there is space in the 
UART's transmit buffer for the character - as such, it is not suitable
for use in time- or latency-critical code (e.g. interrupt handlers).

The default UART is initialized at boot-time by the firmware, and
will generally be the "best" serial UART available (with the 
fallback being the MC68901 UART that is expected to be always installed).

System integrators and third-party hardware developers may also override
the default UART (for example to utilise third-party hardware). 
See section 2.3 for details.

#### 1.1.2.4 SENDCHAR (Function #3)

**Arguments**

* `D1.L` - 2 (Function code)

**Modifies**

* `D0.B` - Returns the received character

**Description**

Synchronously receive a character via the system's *default UART*,
and return it in `D0.B`. If no character is immediately available, this
routine will block until one becomes available. As such, it is not suitable
for use in time- or latency-critical code (e.g. interrupt handlers).

The default UART is initialized at boot-time by the firmware, and
will generally be the "best" serial UART available (with the 
fallback being the MC68901 UART that is expected to be always installed).

System integrators and third-party hardware developers may also override
the default UART (for example to utilise third-party hardware). 
See section 2.3 for details.


## 1.2. Easy68k compatibility layer (TRAP 15)


TRAP 15 provides an (optional, included by default) Easy68k-compatible
IO interface. The aim is to allow many common Easy68k programs to be 
run on the rosco_m68k without modification.

Currently only a subset of the Easy68K tasks are implemented. Output 
will always go to the **default console** (See section 1.1.2.1) and input
will be via the **default UART** (See section 1.1.2.3). Depending on
capabilities of the input and output devices, some functions may not
be available in all contexts (for example, cursor movement and color
setting will not be available where output is via UART).

These functions are called by loading the task number into `D0` and setting
up other registers as documented below, and then calling `TRAP #15`.

### 1.2.1 Example Usage

An example of calling function 0 (PRINTLN with length) of TRAP 15 is:

```
DO_EASY68K_PRINTLN_LEN:
    move.l  #0,D0
    move.w  #13,D1
    lea.l   MYSTRING,A1
    trap    #15

; ... later

MYSTRING    dc.b    "Hello, World!"
```

### 1.2.2 Functions

#### 1.2.2.1 PRINTLN_LEN (Function #0)

**Arguments**

* `D0.L` - 0 (Function code)
* `D1.W` - String length (max 255)
* `A1` - Points to the string

**Modifies**

* `D0` - Trashed
* `D1` - Trashed
* `A1` - Points to memory location after the last printed character

**Description**

Print the string at (A1), D1.W bytes long (max 255) with carriage return
and line feed (CR, LF) to the system's *default console*. 

See also: Function 13

#### 1.2.2.2 PRINT_LEN (Function #1)

**Arguments**

* `D0.L` - 1 (Function code)
* `D1.W` - String length (max 255)
* `A1` - Points to the string

**Modifies**

* `D0` - Trashed
* `D1` - Trashed
* `A1` - Points to memory location after the last printed character

**Description**

Print the string at (A1), D1.W bytes long (max 255) **without** carriage return
and line feed (CR, LF) to the system's *default console*. 

See also: Function 14

#### 1.2.2.3 READSTR (Function #2)

**Arguments**

* `D0.L` - 2 (Function code)
* `A0` - Pointer to buffer in which to store string

**Modifies**

* `D0` - Trashed
* `D1.W` - Returns length of read string (Max 80)
* `D2` - Trashed
* `(A1)` - Returns the string

**Description**

Read string from keyboard and store at (A1), NULL terminated, length retuned in D1.W (max 80). 

#### 1.2.2.4 DISPLAYNUM_SIGNED (Function #3)

**Arguments**

* `D0.L` - 3 (Function code)
* `D1.L` - Number to display

**Modifies**

* `D0` - Trashed
* `D1` - Possibly trashed

**Description**

Print signed number in D1.L in decimal (in smallest field) to the system's
*default console*.

See also: Functions 15 & 20

#### 1.2.2.5 READNUM (Function #4)

**Arguments**

* `D0.L` - 4 (Function code)

**Modifies**

* `D0` - Trashed
* `D1.L` - Returns the read number

**Description**

Read a number from the keyboard into D1.L.

See also: Functions 15 & 20

#### 1.2.2.6 READCHAR (Function #5)

**Arguments**

* `D0.L` - 5 (Function code)

**Modifies**

* `D0` - Trashed
* `D1.B` - The read character.

**Description**

Read single character from the keyboard into D1.B.

**Note** Unlike Easy68k, this will block until input is available.

#### 1.2.2.7 SENDCHAR (Function #6)

**Arguments**

* `D0.L` - 6 (Function code)
* `D1.B` - Character to display

**Modifies**

* `D0` - Trashed
* `D1` - Trashed

**Description**

Display single character in D1.B.

#### 1.2.2.8 CHECKINPUT (Function #7)

**Arguments**

* `D0.L` - 7 (Function code)

**Modifies**

* `D0` - Trashed
* `D1.B` - 1 if input pending, 0 otherwise

**Description**

Set D1.B to 1 if keyboard input is pending, otherwise set to 0. 
Use Function 5 to read pending key.

**Notes**

**This function is to be avoided if possible**.

Using this function doesn't make a lot of sense in the current rosco_m68k 
environment, because all input is via the UART. This means that, while this 
function _is_ implemented, its meaning is subtly different from the Easy68K
equivalent - here true result means there is serial data waiting, not 
specifically a user keypress.

That's not the worst of it, however - if the MC68901 UART is currently the
system's *default UART*, **using this task may actually be harmful**.
It may silently clear any errors the UART is signalling. This is 
because it works by reading the Buffer Full indicator bit in the receiver
status register, which has the effect of _also_ clearing the error flags
(e.g. overrun) in that same register. Normally, these would be checked 
during a receive, but this task doesn't check them _at all_ and so could 
lead to errors being ignored / discarded.

So, if you must use this task, keep all this in mind! 

See also: Function 5                       

#### 1.2.2.9 GETUPTICKS (Function #8)

**Arguments**

* `D0.L` - 8 (Function code)

**Modifies**

* `D0` - Trashed
* `D1.L` - Current number of upticks

**Description**

Return upticks (time in hundredths of a second since boot) in D1.L.

**Notes**

Easy68K defines this function as returning the count of "hundredths of a
second since midnight", but since the rosco_m68k doesn't have a real-time 
clock this just returns the system tick counter from the system data 
block (SDB), which is updated by the system tick handler (driven by a 
programmable interrupt which may be disabled).

Unfortunately this counter is only word-sized, and will roll over every
655.36 seconds (or 10.92 minutes if you prefer). It also isn't updated at
exactly 100HZ, so all-in-all this isn't really going to return "hundredths 
of a second since boot" unless you aren't particularly strict with your 
definition of "hundredths" and the computer was started less than ~11 minutes ago.

If you do need any kind of precision timing, you'll have to design some sort
of expansion that connects to the expansion bus :) 

#### 1.2.2.10 TERMINATE (Function #9)

**Arguments**

* `D0.L` - 9 (Function code)

**Modifies**

Nothing

**Description**

Terminate the program (Disables interrupts and halts the CPU).

This will never return - the only way back is through wetware
intervention.

#### 1.2.2.11 MOVEXY (Function #11)

**Arguments**

* `D0.L` - 11 (Function code)
* `D1.W` - Encoded position (see description)

**Modifies**

* `D0` - Trashed
* `D1` - Trashed
* `D2` - Trashed
* `A0` - Trashed

**Description**

Position the cursor at ROW, COL. 

Support is not mandatory for any given console. E.g. requires ANSI support
on the receiving terminal where the default console is a UART.

* The high byte of D1.W holds the COL number (0-79),
* The low byte holds the ROW number (0-31).

0,0 is top left 79,31 is the bottom right (depending on terminal size).
Out of range coordinates are usually ignored (depends on terminal).

**Clear Screen : Set D1.W to $FF00**.

#### 1.2.2.12 SETECHO (Function #12)

**Arguments**

* `D0.L` - 12 (Function code)
* `D1.B` - 0 to disable, 1 to enable

**Modifies**

* `D0` - Trashed
* `D1` - Trashed

**Description**

Keyboard Echo.

* D1.B = 0 to turn off keyboard echo.
* D1.B = non zero to enable it (default).

Echo is restored on 'Reset'.

#### 1.2.2.13 PRINTLN_SZ (Function #13)

**Arguments**

* `D0.L` - 13 (Function code)
* `A1` - Points to the string

**Modifies**

* `D0` - Trashed
* `D1` - Trashed
* `A1` - Points to memory location after the last printed character

**Description**

Print the NULL-terminated string at (A1) with carriage return
and line feed (CR, LF) to the system's *default console*. 

See also: Function 0

#### 1.2.2.14 PRINT_SZ (Function #14)

**Arguments**

* `D0.L` - 14 (Function code)
* `A1` - Points to the string

**Modifies**

* `D0` - Trashed
* `D1` - Trashed
* `A1` - Points to memory location after the last printed character

**Description**

Print the NULL-terminated string at (A1) **without** carriage return
and line feed (CR, LF) to the system's *default console*. 

See also: Function 1

#### 1.2.2.15 PRINT_UNSIGNED (Function #15)

**Arguments**

* `D0.L` - 15 (Function code)
* `D1.L` - Number to print
* `D2.B` - Base (2 through 36)

**Modifies**

* `D0` - Trashed
* `D1` - Trashed
* `D2` - Trashed

**Description**

Display the unsigned number in D1.L converted to number base (2 
through 36) contained in D2.B.

For example, to display D1.L in base16 put 16 in D2.B

Values of D2.B outside the range 2 to 36 inclusive are ignored.

#### 1.2.2.16 SETDISPLAY (Function #16)

**Arguments**

* `D0.L` - 16 (Function code)
* `D1.B` - Option to set (see description)

**Modifies**

* `D0` - Trashed
* `D1` - Trashed

**Description**

Adjust display properties

* D1.B = 0 to turn off the display of the input prompt.
* D1.B = 1 to turn on the display of the input prompt. (default)
* D1.B = 2 do not display a line feed when Enter pressed during Trap task #2 input
* D1.B = 3 display a line feed when Enter key pressed during Trap task #2 input (default)

Other values of D1 reserved for future use.

Input prompt display is enabled by default and by 'Reset'.

#### 1.2.2.17 PRINTSZ_NUM (Function #17)

**Arguments**

* `D0.L` - 17 (Function code)
* `D1.L` - Number to display
* `A1` - Pointer to string

**Modifies**

* `D0` - Trashed
* `D1` - Trashed
* `A1` - Trashed

**Description**

Combination of functions 14 & 3.

* Display the NULL terminated string at (A1) without CR, LF then
* Display the number in D1.L, in base 10

#### 1.2.2.18 PRINTSZ_NUM (Function #18)

**Arguments**

* `D0.L` - 18 (Function code)
* `A1` - Pointer to string

**Modifies**

* `D0` - Trashed
* `D1.L` - Returns the resulting number
* `D2` - Trashed
* `A1` - Trashed

**Description**

Combination of functions 14 & 4.

* Display the NULL terminated string at (A1) without CR, LF then
* Read a number from the keyboard into D1.L.

#### 1.2.2.19 PRINTSZ_NUM (Function #20)

**Arguments**

* `D0.L` - 20 (Function code)
* `D1.L` - Number to display
* `D2.B` - Field width

**Modifies**

* `D0` - Trashed
* `D1` - Trashed
* `A1` - Trashed

**Description**

Display signed number in D1.L in decimal in field D2.B columns wide.

#2. System Data Area memory map

As standard, the first 4KB of RAM is reserved for system use. This section
details the layout of this memory area.

It is worth noting that if memory is in high demand and the program
being run intends to take full control of the system (i.e. not make
use of any of the firmware TRAP routines or default exception
handlers) then some of this are may be reused. As this is advanced
usage, it is assumed that you know what you need to keep in 
order for the basic machine to function.

All addresses listed in this section are physical addresses. If you
are programming for a system that has an MMU, you may need
to take virtual addressing into account and translate accordingly.

## 2.1. Exception vectors

**Start Address**: 0x0
**End Address**: 0x3FF
**Size**: 0x400 (1024 bytes, 1KB)

This area contains the exception vectors for use by the CPU. 
See the MC68010 manual for the layout of this area.

In order to use custom exception handlers, you will want to
replace the appropriate vector with the address of your 
handler function. Writing exception handlers is beyond the
scope of this document.

It should be noted that this can be moved if a 68010 or higher
is in use. To achieve this, place the starting address of the
exception table in the VBR (Vector Base Register).

## 2.2. Basic System Data Block (SDB)

**Start Address**: 0x400
**End Address**: 0x41F
**Size**: 0x20 (32 bytes, 8 longwords)

This area contains the basic system data block, which is reserved
by the system for variable storage and data used by the standard
exception handlers and TRAP routines.

| Address | Size | Description                                               |
|---------|------|-----------------------------------------------------------|
| 0x400   | 4    | SDB Magic (0xB105D47A)                                    |
| 0x404   | 4    | Status code (set by exception handlers)                   |
| 0x408   | 2    | Internal counter used by timer tick handler               |
| 0x40A   | 2    | Reserved                                                  |
| 0x40C   | 4    | Upticks counter, updated by timer tick handler            |
| 0x410   | 1    | Easy68k 'echo on' flag                                    |
| 0x411   | 1    | Easy68k 'prompt on' flag                                  |
| 0x412   | 1    | Easy68k 'LF display' flag                                 |
| 0x413   | 1    | Easy68k Reserved                                          |
| 0x414   | 12   | System Reserved                                           |

For initialisation and usage, see `bootstrap.S` and the Easy68k `syscalls_asm.S`.

## 2.3. Extension Function Pointer Table (EFPT)

**Start Address**: 0x420
**End Address**: 0x4FF
**Size**: 0xE0 (224 bytes, 56 pointers)

This area contains pointers to functions which are called by the
firmware and TRAP handlers to achieve various things. 

The purpose of this pointer table is to allow these functions
to be replaced by driver software. For example, the V9958 driver
replaces some of these functions in order to redirect output 
to the video console.

Driver writers can replace functions here in order to hook into
the firmware. The general rules are:

* The pointers can point anywhere, but the function that is pointed to **must** remain at that address!
* On entry to the function, the CPU will be in supervisor mode
* On entry to the function, the SP will reference the supervisor stack

Not all of these functions will be used by the firmware - some are 
designated as for program use (for example, a kernel may use them
to provide its own hooks).

User code **must not** call these functions directly - they 
must be accessed through the public TRAP functions!

| Address | Function                                                         |
|---------|------------------------------------------------------------------|
| 0x420   | FW_PRINT - Print SZ to the default console.                      |
| 0x424   | FW_PRINTLN - Print SZ to the default console, followed by CRLF   |
| 0x428   | FW_PRINTCHAR - Print a character to the default console          |
| 0x42C   | FW_HALT - Disable interrupts and halt                            |
| 0x430   | FW_SENDCHAR - Send a character via the default UART              |
| 0x434   | FW_RECVCHAR - Receive a character via the default UART           |
| 0x438   | FW_CLRSCR - Clear the default console (where supported)          |
| 0x43C   | FW_MOVEXY - Move cursor to (X,Y) (see note 1)                    |

**Note 1**: FW_GOTOXY takes the coordinates to move to from D1.W. The high
byte is the X coordinate (Column) and the low byte is the Y coordinate (Row).

Arguments, modifies and other information for these functions are the same
as for the TRAP functions they implement. If replacing them, you **must**
adhere to the same interface. The reference implementations can be found in
`bootstrap.S` and `trap14.S`.

**Note** that all of these are allowed to block! 

## 2.4. Video IO Data Area (VDA)

**Start Address**: 0x500
**End Address**: 0xF9F
**Size**: 0xAA0 (2720 bytes)

This area is reserved for use by video subsystems. The specific layout
is dependent on the video subsystem in use.

For example, this area may contain a framebuffer along with
variables and data required by a video driver.

TODO document layout when video is V9958!

## 2.5. Firmware Reserved Area (BSS)

**Start Address**: 0xFA0
**End Address**: 0xFFF
**Size**: 0x60 (96 bytes)

This area is reserved for the firmware's BSS section. The content
and layout of this area may change without notice.

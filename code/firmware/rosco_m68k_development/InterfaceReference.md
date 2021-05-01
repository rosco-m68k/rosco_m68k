# rosco_m68k Firmware - Memory & Interfaces
## Firmware version 2.0

This document describes the interfaces provided for programmers,
hardware integrators and those expanding the rosco_m68k, as it
applies to firmware revision 2.0. 

The information contained herein is accurate and complete as far
as possible, and will be kept updated as firmware 2.0 is developed.

# Contents

* 1. TRAP Interfaces for User Code
  * 1.1. SPI & Block device IO (TRAP 13)
    * 1.1.1 Example Usage
    * 1.1.2 Functions
      * 1.1.2.1 CHECK_SD_SUPPORT (Function #0)
      * 1.1.2.2 SD_INIT (Function #1)
      * 1.1.2.3 SD_READ_BLOCK (Function #2)
      * 1.1.2.4 SD_WRITE_BLOCK (Function #3)
      * 1.1.2.5 SD_READ_REGISTER (Function #4)
      * 1.1.2.6 CHECK_SPI (Function #5)
      * 1.1.2.7 SPI_INIT (Function #6)
      * 1.1.2.8 SPI_ASSERT_CS (Function #7)
      * 1.1.2.9 SPI_DEASSERT_CS (Function #8)
      * 1.1.2.10 SPI_TRANSFER_BYTE (Function #9)
      * 1.1.2.11 SPI_TRANSFER_BUFFER (Function #10)
      * 1.1.2.12 SPI_RECV_BYTE (Function #11)
      * 1.1.2.13 SPI_RECV_BUFFER (Function #12)
      * 1.1.2.14 SPI_SEND_BYTE (Function #13)
      * 1.1.2.15 SPI_SEND_BUFFER (Function #14)
      * 1.1.2.16 CHECK_ATA_SUPPORT (Function #15)
      * 1.1.2.17 ATA_INIT (Function #16)
      * 1.1.2.18 ATA_READ_SECTORS (Function #17)
      * 1.1.2.19 ATA_WRITE_SECTORS (Function #18)
      * 1.1.2.20 ATA_IDENTIFY (Function #19)
  * 1.2. Character device IO routines (TRAP 14)
    * 1.2.1 Example Usage
    * 1.2.2 Functions
      * 1.2.2.1 PRINT (Function #0)
      * 1.2.2.2 PRINTLN (Function #1)
      * 1.2.2.3 SENDCHAR (Function #2)
      * 1.2.2.4 RECVCHAR (Function #3)
      * 1.2.2.5 PRINTCHAR (Function #4)
      * 1.2.2.6 SETCURSOR (Function #5)
      * 1.2.2.9 CHECKCHAR (Function #6)
  * 1.3. Easy68k compatibility layer (TRAP 15)
    * 1.3.1 Example Usage
    * 1.3.2 Functions
      * 1.3.2.1 PRINTLN_LEN (Function #0)
      * 1.3.2.2 PRINT_LEN (Function #1)
      * 1.3.2.3 READSTR (Function #2)
      * 1.3.2.4 DISPLAYNUM_SIGNED (Function #3)
      * 1.3.2.5 READNUM (Function #4)
      * 1.3.2.6 READCHAR (Function #5)
      * 1.3.2.7 SENDCHAR (Function #6)
      * 1.3.2.8 CHECKINPUT (Function #7)
      * 1.3.2.9 GETUPTICKS (Function #8)
      * 1.3.2.10 TERMINATE (Function #9)
      * 1.3.2.11 MOVEXY (Function #11)
      * 1.3.2.12 SETECHO (Function #12)
      * 1.3.2.13 PRINTLN_SZ (Function #13)
      * 1.3.2.14 PRINT_SZ (Function #14)
      * 1.3.2.15 PRINT_UNSIGNED (Function #15)
      * 1.3.2.16 SETDISPLAY (Function #16)
      * 1.3.2.17 PRINTSZ_NUM (Function #17)
      * 1.3.2.18 PRINTSZ_READ_NUM (Function #18)
      * 1.3.2.19 PRINTNUM_SIGNED_WIDTH (Function #20)
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

Currently, three TRAPs are used by the firmware:

* TRAP 13 provides rosco_m68k's native block device IO routines (SD)
* TRAP 14 provides rosco_m68k's native serial device IO routines (UART/Console)
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

## 1.1. Block device IO (TRAP 13)

TRAP 13 provides access to the block-device IO functionality
provided by the firmware. At present, this means SD cards.

Register D0.L is expected to contain the function code (note that
this is different to the TRAP 14 handler!). Other arguments
depend on the specific function, and are documented below.

In all cases, registers used as aguments (including D0.L) are **not** 
guaranteed to be preserved. All other registers are preserved.

Function codes outside the range documented here are considered
reserved for future expansion, and should not be used by integrators
or other code. The exception to this is where the user program 
is intended to take complete control of the system, in which case
the TRAP handlers, and the SDA that underpins them, may be entirely
replaced in the scope of that program.

### 1.1.1 Example Usage

An example of using function 2 (SD_READ_BLOCK) of TRAP 13 is:

```
SD_read_block::
    movem.l A0-A2/D1,-(A7)
    move.l  (20,A7),A1
    move.l  (24,A7),D1
    move.l  (28,A7),A2
    move.l  #2,D0
    trap    #13
    movem.l (A7)+,A0-A2/D1
    rts
```

With GCC as the compiler, this could be called directly from C, 
with the prototype: 


```
bool SD_read_block(SDCard *sd, uint32_t block, void *buf);
```
 
### 1.1.2 Functions

#### 1.1.2.1 CHECK_SD_SUPPORT (Function #0)

**Arguments**

* D0.L - 0 (Function code)

**Modifies**

* `D0.L` - Return value

**Description**

Determine whether SD Card support is present in the Firmware.

Where SD Card support is available, this will return the magic
number $1234FEDC in D0.L. 

Any other value indicates that support is not available. In this
case, none of the SD Card routines should be used.

With Firmware 2.0, SD support is always available. However, this
routine is retained to allow easy backward-compatibility.

#### 1.1.2.2 SD_INIT (Function #1)

**Arguments**

* `D0.L` - 1 (Function code)
* `A1`   - Pointer to an SDCard struct

**Modifies**

* `D0.L` - Return value
* `A0`   - Modified arbitrarily
* `A1`   - May be modified arbitrarily

**Description**

Attempt to initialize the SD Card. 

The memory pointed to by A1 will be a SDCard structure - see
sdfat.h in the standard libraries for details.

The return value in D0.L will be one of the SDInitStatus
codes - `SD_INIT_OK` (ordinal 0) indicates success, while failure 
is indicated by any other value. Again, see sdfat.h for details.

#### 1.1.2.3 SD_READ_BLOCK (Function #2)

**Arguments**

* `D0.L` - 1 (Function code)
* `D1.L` - Block number to read
* `A1`   - Pointer to an initialized SDCard struct
* `A2`   - Pointer to a 512-byte buffer

**Modifies**

* `D0.L` - Return value
* `D1.L` - May be modified arbitrarily
* `A0`   - Modified arbitrarily
* `A1`   - May be modified arbitrarily
* `A2`   - May be modified arbitrarily

**Description**

Read a 512-byte block from the SD Card into the buffer
pointed to by A2.

Returns 0 in D0.L to indicate failure, any other value
indicates success.

#### 1.1.2.4 SD_WRITE_BLOCK (Function #3)

**Arguments**

* `D0.L` - 1 (Function code)
* `D1.L` - Block number to write
* `A1`   - Pointer to an initialized SDCard struct
* `A2`   - Pointer to a 512-byte buffer

**Modifies**

* `D0.L` - Return value
* `D1.L` - May be modified arbitrarily
* `A0`   - Modified arbitrarily
* `A1`   - May be modified arbitrarily
* `A2`   - May be modified arbitrarily

**Description**

Write a 512-byte block from the buffer pointed to by A2 to
the SD Card..

Returns 0 in D0.L to indicate failure, any other value
indicates success.

#### 1.1.2.5 SD_READ_REGISTER (Function #4)

**Arguments**

* `D0.L` - 1 (Function code)
* `D1.L` - Register number to read (translates directly to a CMD)
* `A1`   - Pointer to an initialized SDCard struct
* `A2`   - Pointer to a 16-byte buffer

**Modifies**

* `D0.L` - Return value
* `D1.L` - May be modified arbitrarily
* `A0`   - Modified arbitrarily
* `A1`   - May be modified arbitrarily
* `A2`   - May be modified arbitrarily

**Description**

Read an SD Card register block from the SD Card into the buffer
pointed to by A2.

Returns 0 in D0.L to indicate failure, any other value
indicates success.

#### 1.1.2.6 CHECK_SPI (Function #5)

**Arguments**

* `D0.L` - 5 (Function code)

**Modifies**

* `D0.L` - Return value

**Description**

Determine whether SPI support is present in the Firmware.

Where SPI Card support is available, this will return the magic
number $1234FEDC in D0.L. 

Any other value indicates that support is not available. In this
case, none of the SPI routines should be used.

With Firmware 2.0, SD support is always available. However, this
routine is retained to allow easy backward-compatibility.

#### 1.1.2.7 SPI_INIT (Function #6)

**Arguments**

* `D0.L` - 6 (Function code)

**Modifies**

* `D0.L` - Result (0 = OK, otherwise failed)
* `A0`   - Modified arbitrarily

**Description**

Initialize the SPI interface. This sets the SPI pins to the 
appropriate modes (input vs output).

#### 1.1.2.8 SPI_ASSERT_CS (Function #7)

**Arguments**

* `D0.L` - 7 (Function code)
* `D1.L` - Device number (0 or 1)

**Modifies**

* `D0.L` - Result (0 = failed, otherwise OK)
* `A0`   - Modified arbitrarily

**Description**

Assert the appropriate CS line. CS 0 is GPIO 1, CS 1 is GPIO 5.
Note that asserting one line *does not* automatically deassert 
the other!

#### 1.1.2.9 SPI_DEASSERT_CS (Function #8)

**Arguments**

* `D0.L` - 8 (Function code)
* `D1.L` - Device number (0 or 1)

**Modifies**

* `D0.L` - Result (0 = failed, otherwise OK)
* `A0`   - Modified arbitrarily

**Description**

Deassert the appropriate CS line. CS 0 is GPIO 1, CS 1 is GPIO 5.

#### 1.1.2.10 SPI_TRANSFER_BYTE (Function #9)

**Arguments**

* `D0.L` - 9 (Function code)
* `D1.L` - Byte to send

**Modifies**

* `D0.L` -  Byte received
* `A0`   - Modified arbitrarily

**Description**

Send and receive a byte (exchange) via SPI.

#### 1.1.2.11 SPI_TRANSFER_BUFFER (Function #10)

**Arguments**

* `D0.L` - 10 (Function code)
* `A1.L` - Pointer to buffer
* `D1.L` - Number of bytes

**Modifies**

* `D0.L` - Count exchanged
* `A0`   - Modified arbitrarily
* `A1`   - Possibly modified

**Description**

Transfer count (`D1.L`) bytes from the given buffer, exchanging them 
with bytes received at the same time (and returned in the buffer).

Note that the buffer pointer may be modified, so keep a copy locally.

#### 1.1.2.12 SPI_RECV_BYTE (Function #11)

**Arguments**

* `D0.L` - 11 (Function code)

**Modifies**

* `D0.L` - Byte received
* `A0`   - Modified arbitrarily

**Description**

Send and receive a byte (exchange) via SPI.

#### 1.1.2.13 SPI_RECV_BUFFER (Function #12)

**Arguments**

* `D0.L` - 12 (Function code)
* `A1.L` - Pointer to buffer
* `D1.L` - Number of bytes

**Modifies**

* `D0.L` - Count received
* `A0`   - Modified arbitrarily
* `A1`   - Possibly modified

**Description**

Receive count (`D1.L`) bytes into the given buffer.
Note that the buffer pointer may be modified, so keep a copy locally.

#### 1.1.2.14 SPI_SEND_BYTE (Function #13)

**Arguments**

* `D0.L` - 13 (Function code)
* `D1.L` - Byte to send

**Modifies**

* `A0`   - Modified arbitrarily
* `D1.L` - Possibly trashed

**Description**

Send and receive a byte (exchange) via SPI.

#### 1.1.2.15 SPI_SEND_BUFFER (Function #14)

**Arguments**

* `D0.L` - 14 (Function code)
* `A1.L` - Pointer to buffer
* `D1.L` - Number of bytes

**Modifies**

* `D0.L` - Count received
* `A0`   - Modified arbitrarily
* `A1`   - Possibly modified

**Description**

Send count (`D1.L`) bytes from the given buffer.
Note that the buffer pointer may be modified, so keep a copy locally.

#### 1.1.2.16 CHECK_ATA_SUPPORT (Function #15)

**Arguments**

* `D0.L` - 15 (Function code)

**Modifies**

* `D0.L` - Return value

**Description**

Determine whether ATA support is present in the Firmware.

Where ATA support is available, this will return the magic
number $1234FEDC in D0.L. 

Any other value indicates that support is not available. In this
case, none of the ATA routines should be used.

With Firmware 2.0, ATA support is always available. However, this
routine is retained to allow easy backward-compatibility.

#### 1.1.2.17 ATA_INIT (Function #16)

**Arguments**

* `D0.L` - 16 (Function code)
* `D1.L` - 0 (ATA Master) or 1 (ATA slave)
* `A1`   - Pointer to an ATADevice struct

**Modifies**

* `D0.L` - Return value
* `D1.L` - May be modified arbitrarily
* `A0`   - Modified arbitrarily
* `A1`   - May be modified arbitrarily

**Description**

Attempt to initialize an ATA device. 

The memory pointed to by A1 will be a ATADevice structure - see
ata.h in the standard libraries for details.

The return value in D0.L will be one of the ATAInitStatus
codes - `ATA_INIT_OK` (ordinal 0) indicates success, while failure 
is indicated by any other value. Again, see ata.h for details.

#### 1.1.2.18 ATA_READ_SECTORS (Function #17)

**Arguments**

* `D0.L` - 17 (Function code)
* `D1.L` - LBA sector number to read
* `D2.L` - Number of sectors to read
* `A1`   - Pointer to an initialized ATADevice struct
* `A2`   - Pointer to a (512 * D2.L)-byte buffer

**Modifies**

* `D0.L` - Return value
* `D1.L` - May be modified arbitrarily
* `A0`   - Modified arbitrarily
* `A1`   - May be modified arbitrarily
* `A2`   - May be modified arbitrarily

**Description**

Read the number of 512-byte sectors (indicated by `D2.L`) from the 
ATA device into the buffer pointed to by `A2`.

Returns the actual number of sectors read in `D0.L`.

#### 1.1.2.19 ATA_WRITE_SECTORS (Function #18)

**Arguments**

* `D0.L` - 18 (Function code)
* `D1.L` - LBA sector number to write
* `D2.L` - Number of sectors to write
* `A1`   - Pointer to an initialized ATADevice struct
* `A2`   - Pointer to a (512 * D2.L)-byte buffer

**Modifies**

* `D0.L` - Return value
* `D1.L` - May be modified arbitrarily
* `A0`   - Modified arbitrarily
* `A1`   - May be modified arbitrarily
* `A2`   - May be modified arbitrarily

**Description**

Write the number of 512-byte sectors (indicated by `D2.L`) from the 
buffer pointed to by `A2` to the ATA device, starting at the LBA sector
indicated by `D1.L`.

Returns the actual number of sectors written in `D0.L`.

#### 1.1.2.20 ATA_IDENTIFY (Function #19)

**Arguments**

* `D0.L` - 19 (Function code)
* `A1`   - Pointer to an initialized ATADevice struct
* `A2`   - Pointer to a 512-byte buffer

**Modifies**

* `D0.L` - Return value (0 = failed, 1 = success)
* `D1.L` - May be modified arbitrarily
* `A0`   - Modified arbitrarily
* `A1`   - May be modified arbitrarily
* `A2`   - May be modified arbitrarily

**Description**

Issue an ATA `IDENTIFY` command to the specified `ATADevice`, and return
the results in the supplied buffer.

Returns 1 in `D0.L` if successful, 0 otherwise.

## 1.2. Basic IO routines (TRAP 14)

TRAP 14 provides access to the character-based IO functionality 
provided by the firmware. This includes the default UART and
console.

Register D1.L is expected to contain the function code. Other arguments
depend on the specific function, and are documented below.

In all cases, registers used as aguments (**excluding** D1.L, which 
will be preserved unless explicitly documented as used for a return
value) are **not** guaranteed to be preserved. All 
other registers are preserved.

Function codes outside the range documented here are considered
reserved for future expansion, and should not be used by integrators
or other code. The exception to this is where the user program 
is intended to take complete control of the system, in which case
the TRAP handlers, and the SDA that underpins them, may be entirely
replaced in the scope of that program.

### 1.2.1 Example Usage

An example of calling function 1 (PRINTLN) of TRAP 14 is:

```
DO_PRINTLN:
    move.l  #1,D1
    lea.l   MYSTRING,A0
    trap    #14

; ... later

MYSTRING    dc.b    "Hello, World!", 0
```

### 1.2.2 Functions

#### 1.2.2.1 PRINT (Function #0)

**Arguments**

* `D1.L` - 0 (Function code)
* `A0`   - Pointer to null-terminated string to print

**Modifies**

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

#### 1.2.2.2 PRINTLN (Function #1)

**Arguments**

* `D1.L` - 1 (Function code)
* `A0`   - Pointer to null-terminated string to print

**Modifies**

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

#### 1.2.2.3 SENDCHAR (Function #2)

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

#### 1.2.2.4 RECVCHAR (Function #3)

**Arguments**

* `D1.L` - 3 (Function code)

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

#### 1.2.2.5 PRINTCHAR (Function #4)

**Arguments**

* `D1.L` - 4 (Function code)
* `D0.B` - Character to print

**Modifies**

Nothing

**Description**

Print the character in `D0.B` to by `A0` to the system's *default console*.

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

#### 1.2.2.6 SETCURSOR (Function #5)

**Arguments**

* `D1.L` - 5 (Function code)
* `D0.B` - 0 to hide cursor, non-zero to show

**Modifies**

Nothing

**Description**

Show or hide the cursor on the *default console*. Where this is not possible]
(e.g. where the default console is a serial terminal) this routine does
nothing.

The default console is initialized at boot-time by the firmware, and 
may be the V9958 console (where available), or the *default serial UART*.
For details on the default UART, see the `SENDCHAR` function.

System integrators and third-party hardware developers may also override
the default console (for example to output to third-party video 
hardware). See section 2.3 for details.

#### 1.2.2.7 CHECKCHAR (Function #6)

**Arguments**

* `D1.L` - 6 (Function code)

**Modifies**

* `D0.B` - 0 if no character waiting, nonzero otherwise

**Description**

Determine whether the system's *default UART* has a character waiting to
be received, returning non-zero in `D0.B` if so, zero otherwise. 

This can be used to determine whether a call to `RECVCHAR` will block.
Note that this function may clear error flags and other status information.

The default UART is initialized at boot-time by the firmware, and
will generally be the "best" serial UART available (with the 
fallback being the MC68901 UART that is expected to be always installed).

System integrators and third-party hardware developers may also override
the default UART (for example to utilise third-party hardware). 
See section 2.3 for details.

## 1.3. Easy68k compatibility layer (TRAP 15)


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

### 1.3.1 Example Usage

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

### 1.3.2 Functions

#### 1.3.2.1 PRINTLN_LEN (Function #0)

**Arguments**

* `D0.L` - 0 (Function code)
* `D1.W` - String length (max 255)
* `A1` - Points to the string

**Modifies**

* `D1` - Trashed
* `A1` - Points to memory location after the last printed character

**Description**

Print the string at (A1), D1.W bytes long (max 255) with carriage return
and line feed (CR, LF) to the system's *default console*. 

See also: Function 13

#### 1.3.2.2 PRINT_LEN (Function #1)

**Arguments**

* `D0.L` - 1 (Function code)
* `D1.W` - String length (max 255)
* `A1` - Points to the string

**Modifies**

* `D1` - Trashed
* `A1` - Points to memory location after the last printed character

**Description**

Print the string at (A1), D1.W bytes long (max 255) **without** carriage return
and line feed (CR, LF) to the system's *default console*. 

See also: Function 14

#### 1.3.2.3 READSTR (Function #2)

**Arguments**

* `D0.L` - 2 (Function code)
* `A0` - Pointer to buffer in which to store string

**Modifies**

* `D1.W` - Returns length of read string (Max 80)
* `(A1)` - Returns the string

**Description**

Read string from keyboard and store at (A1), NULL terminated, length retuned in D1.W (max 80). 

#### 1.3.2.4 DISPLAYNUM_SIGNED (Function #3)

**Arguments**

* `D0.L` - 3 (Function code)
* `D1.L` - Number to display

**Modifies**

* `D1` - Possibly trashed

**Description**

Print signed number in D1.L in decimal (in smallest field) to the system's
*default console*.

See also: Functions 15 & 20

#### 1.3.2.5 READNUM (Function #4)

**Arguments**

* `D0.L` - 4 (Function code)

**Modifies**

* `D1.L` - Returns the read number

**Description**

Read a number from the keyboard into D1.L.

See also: Functions 15 & 20

#### 1.3.2.6 READCHAR (Function #5)

**Arguments**

* `D0.L` - 5 (Function code)

**Modifies**

* `D1.B` - The read character.

**Description**

Read single character from the keyboard into D1.B.

**Note** Unlike Easy68k, this will block until input is available.

#### 1.3.2.7 SENDCHAR (Function #6)

**Arguments**

* `D0.L` - 6 (Function code)
* `D1.B` - Character to display

**Modifies**

* `D1` - Trashed

**Description**

Display single character in D1.B.

#### 1.3.2.8 CHECKINPUT (Function #7)

**Arguments**

* `D0.L` - 7 (Function code)

**Modifies**

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

#### 1.3.2.9 GETUPTICKS (Function #8)

**Arguments**

* `D0.L` - 8 (Function code)

**Modifies**

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

#### 1.3.2.10 TERMINATE (Function #9)

**Arguments**

* `D0.L` - 9 (Function code)

**Modifies**

Nothing

**Description**

Terminate the program (Disables interrupts and halts the CPU).

This will never return - the only way back is through wetware
intervention.

#### 1.3.2.11 MOVEXY (Function #11)

**Arguments**

* `D0.L` - 11 (Function code)
* `D1.W` - Encoded position (see description)

**Modifies**

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

#### 1.3.2.12 SETECHO (Function #12)

**Arguments**

* `D0.L` - 12 (Function code)
* `D1.B` - 0 to disable, 1 to enable

**Modifies**

* `D1` - Trashed

**Description**

Keyboard Echo.

* D1.B = 0 to turn off keyboard echo.
* D1.B = non zero to enable it (default).

Echo is restored on 'Reset'.

#### 1.3.2.13 PRINTLN_SZ (Function #13)

**Arguments**

* `D0.L` - 13 (Function code)
* `A1` - Points to the string

**Modifies**

* `D1` - Trashed
* `A1` - Points to memory location after the last printed character

**Description**

Print the NULL-terminated string at (A1) with carriage return
and line feed (CR, LF) to the system's *default console*. 

See also: Function 0

#### 1.3.2.14 PRINT_SZ (Function #14)

**Arguments**

* `D0.L` - 14 (Function code)
* `A1` - Points to the string

**Modifies**

* `D1` - Trashed
* `A1` - Points to memory location after the last printed character

**Description**

Print the NULL-terminated string at (A1) **without** carriage return
and line feed (CR, LF) to the system's *default console*. 

See also: Function 1

#### 1.3.2.15 PRINT_UNSIGNED (Function #15)

**Arguments**

* `D0.L` - 15 (Function code)
* `D1.L` - Number to print
* `D2.B` - Base (2 through 36)

**Modifies**

* `D1` - Trashed
* `D2` - Trashed

**Description**

Display the unsigned number in D1.L converted to number base (2 
through 36) contained in D2.B.

For example, to display D1.L in base16 put 16 in D2.B

Values of D2.B outside the range 2 to 36 inclusive are ignored.

#### 1.3.2.16 SETDISPLAY (Function #16)

**Arguments**

* `D0.L` - 16 (Function code)
* `D1.B` - Option to set (see description)

**Modifies**

* `D1` - Trashed

**Description**

Adjust display properties

* D1.B = 0 to turn off the display of the input prompt.
* D1.B = 1 to turn on the display of the input prompt. (default)
* D1.B = 2 do not display a line feed when Enter pressed during Trap task #2 input
* D1.B = 3 display a line feed when Enter key pressed during Trap task #2 input (default)

Other values of D1 reserved for future use.

Input prompt display is enabled by default and by 'Reset'.

#### 1.3.2.17 PRINTSZ_NUM (Function #17)

**Arguments**

* `D0.L` - 17 (Function code)
* `D1.L` - Number to display
* `A1` - Pointer to string

**Modifies**

* `D1` - Trashed
* `A1` - Trashed

**Description**

Combination of functions 14 & 3.

* Display the NULL terminated string at (A1) without CR, LF then
* Display the number in D1.L, in base 10

#### 1.3.2.18 PRINTSZ_READ_NUM (Function #18)

**Arguments**

* `D0.L` - 18 (Function code)
* `A1` - Pointer to string

**Modifies**

* `D1.L` - Returns the resulting number
* `A1` - Trashed

**Description**

Combination of functions 14 & 4.

* Display the NULL terminated string at (A1) without CR, LF then
* Read a number from the keyboard into D1.L.

#### 1.3.2.19 PRINTNUM_SIGNED_WIDTH (Function #20)

**Arguments**

* `D0.L` - 20 (Function code)
* `D1.L` - Number to display
* `D2.B` - Field width

**Modifies**

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
| 0x40A   | 2    | System flags (see below)                                  |
| 0x40C   | 4    | Upticks counter, updated by timer tick handler            |
| 0x410   | 1    | Easy68k 'echo on' flag                                    |
| 0x411   | 1    | Easy68k 'prompt on' flag                                  |
| 0x412   | 1    | Easy68k 'LF display' flag                                 |
| 0x413   | 1    | Easy68k Reserved                                          |
| 0x414   | 4    | Size of the first block of contiguious memory             |
| 0x418   | 4    | Default UART base address                                 |
| 0x41C   | 4    | System Reserved                                           |

For initialisation and usage, see `bootstrap.S` and the Easy68k `syscalls_asm.S`.

### System flags word (0x40A)

This word contains various flags that control system behaviour. The main use
at the moment is to prevent the system from using certain GPIOs (e.g. the
LEDs).

| Bit | Description                                       |
|-----|---------------------------------------------------|
|  15 | Allow system use of CTS (MFP GPIP7)               |
|  14 | Reserved - MUST BE 1 FOR SPI/SD SUPPORT!          |
|  13 | Reserved - MUST BE 1 FOR SPI/SD SUPPORT!          |
|  12 | Reserved - MUST BE 1 FOR SPI/SD SUPPORT!          |
|  11 | Reserved - MUST BE 1 FOR SPI/SD SUPPORT!          |
|  10 | Reserved - MUST BE 1 FOR SPI/SD SUPPORT!          |
|   9 | Allow system use of LED1 (MFP GPIP1)              |
|   8 | Allow system use of LED0 (MFP GPIP0)              |
| 0-7 | Reserved                                          |

The default value for the flags word is $FFXX (XX being reserved bits which can
have any value). This allows the system to take control of the two LEDs I0 and I1,
and the CTS line and allows the firmware SD/SPI interface to function normally.

User code may clear any of the non-reserved bits to take full control of the appropriate
lines. 

**Note** that, in systems where the firmware SPI/SD interfaces are being used,
setting bits 10-14 to zero will result in undefined behaviour and possible data loss.

**Note** that, in the case of total system crash, these bits will not be honored
and the system will revert to blinking the red LED as normal in a crash situation.

**Note** also that clearing these bits has no effect on the actual state of the GPIP lines.
User code should set the lines to a known state after setting this word.

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

| Address | Function                                                                                          |
|---------|---------------------------------------------------------------------------------------------------|
| 0x420   | FW_PRINT - Print SZ to the default console.                                                       |
| 0x424   | FW_PRINTLN - Print SZ to the default console, followed by CRLF                                    |
| 0x428   | FW_PRINTCHAR - Print a character to the default console                                           |
| 0x42C   | FW_HALT - Disable interrupts and halt                                                             |
| 0x430   | FW_SENDCHAR - Send a character via the default UART                                               | 
| 0x434   | FW_RECVCHAR - Receive a character via the default UART                                            |
| 0x438   | FW_CLRSCR - Clear the default console (where supported)                                           |
| 0x43C   | FW_MOVEXY - Move cursor to (X,Y) (see note 1)                                                     |
| 0x440   | FW_SETCURSOR - Show (D0.B > 0) or hide (D0.B == 0) the cursor                                     |
| 0x444   | RESERVED                                                                                          |
| 0x448   | FW_PROGRAM_LOADER - The firmware uses this to invoke the program loader (defaults to SD/Kermit)   |
| 0x44C   | FW_SD_INIT - Initialize SD Card                                                                   |
| 0x450   | FW_SD_READ - Read from SD Card                                                                    |
| 0x454   | FW_SD_WRITE - Write to SD Card                                                                    |
| 0x458   | FW_SD_REG - Read SD Card register                                                                 |
| 0x45C   | FW_SPI_INIT - Intialize SPI subsystem                                                             |
| 0x460   | FW_SPI_ASSERT_CS - Assert SPI chip select 0 or 1                                                  |
| 0x464   | FW_SPI_DEASSERT_CS - Deassert SPI chip select 0 or 1                                              |
| 0x468   | FW_SPI_TRANSFER_BYTE - Transfer (exchange) a byte                                                 |
| 0x46C   | FW_SPI_TRANSFER_BUFFER - Transfer (exchange) N bytes to/from a buffer                             |
| 0x470   | FW_SPI_RECV_BYTE - Receive a byte                                                                 |
| 0x474   | FW_SPI_RECV_BUFFER - Receive N bytes into a buffer                                                |
| 0x478   | FW_SPI_SEND_BYTE - Send a byte                                                                    |
| 0x47C   | FW_SPI_SEND_BUFFER - Send N bytes from a buffer                                                   |
| 0x480   | FW_ATA_INIT - Initialize ATA PIO device                                                           |
| 0x484   | FW_ATA_READ - Read from ATA device                                                                |
| 0x488   | FW_ATA_WRITE - Write to ATA device                                                                |
| 0x48C   | FW_ATA_IDENT - `IDENTIFY` ATA device                                                               |

**Note 1**: FW_GOTOXY takes the coordinates to move to from D1.W. The high
byte is the X coordinate (Column) and the low byte is the Y coordinate (Row).

**Note 2**: The SD, SPI and ATA routines arguments, modifies and returns are the same as for the TRAPs they 
underlie unless otherwise noted. See section 1 for details.

Arguments, modifies and other information for these functions are the same
as for the TRAP functions they implement. If replacing them, you **must**
adhere to the same interface. The reference implementations can be found in
`bootstrap.S`, `trap14.S` and `sdcard/syscalls_asm.S`.

**Note** that all of these are allowed to block! 

## 2.4. Video IO Data Area (VDA)

**Start Address**: 0x500
**End Address**: 0x117F
**Size**: 0xC80 (3200 bytes)

This area is reserved for use by video subsystems. The specific layout
is dependent on the video subsystem in use.

For example, this area may contain a framebuffer along with
variables and data required by a video driver.

TODO document layout when video is V9958!

## 2.6. Firmware Reserved Area 1 (Internal)

**Start Address**: 0x1180
**End Address**: 0x17FF
**Size**: 0x680 (1664 bytes)

This area is reserved for future Firmware expansion.

## 2.6. Firmware Reserved Area 2 (BSS)

**Start Address**: 0x1800
**End Address**: 0x1FFF
**Size**: 0x800 (2048 bytes)

This area is reserved for the firmware's BSS section. The content
and layout of this area may change without notice.


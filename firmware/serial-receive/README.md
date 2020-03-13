# Serial Loader for rosco_m68k

This firmware implements a simple way to load code into the computer from startup,
enabling quicker iteration (and less dead ROM chips).

The idea with this is to do basic set up of the system (e.g. set up the MFP) and
then wait for the user to initiate a file transfer from their terminal program.

This transfer should upload (in binary) the code that is to be run (perhaps a kernel,
or some other thing).

## Protocols

Currently, two protocols are supported (for varying values of 'supported'):

* Kermit - The standard, embedded Kermit. Should be pretty robust, but may
  be a bit slow (Recommend using `robust` mode on the sender!)
  
* ZMODEM -  A fairly limited subset and not especially robust, but should be
  good enough to get some code uploaded.
 
Note that, at present, Kermit is the only *supported* protocol - the ZMODEM
code is experimental, and known to not work almost all of the time. 

This is mildly annoying as it requires one to install additional software 
to get Kermit support from the command line, or in minicom. On most Unices
you should be able to install from your package manager (try `ckermit` or 
`c-kermit`). On OSX you can install from homebrew (`brew install c-kermit`) 
and ports probably has it too. On Windows YMMV, but if you're successfully
building this on Windows then you've probably already done a lot of work to
get a cross-compiler and so on working, so I'm sure you'll figure it out.
 
## Code

TODO There will eventually be some documentation here on how to write and
build code that is compatible with this loader. For now, these notes
will have to suffice:

* **There is a very simple POC "kernel" at ../poc-kernel** - This shows how to
  e.g. relocate your code (down to $1000) and how to link for that etc.
* Code is loaded at $28000 (somewhat arbitrarily). The loader will jump
  directly to that location after the code is received.
* This means you are limited to ~860KB with the standard memory configuration.
* (It's actually slightly more, but the stack is at the top of RAM!)
* Once your code is loaded, all of RAM is yours.
* Depending how much setup you want to do, you might leave the lowest 1KB 
  alone (exception vectors), other than setting up any vectors your code
  actually wants to handle.
* If you want to use the standard runtime support stuff (see below), leave the
  bottom 4KB alone (i.e. $1000-$FFFFF are free for your use). 
* The _recommended_ thing to do is to relocate your code after loading,
  so you don't have it stuck in the middle of RAM. This will make your
  life easier later.
* Obviously your link script will need to take this into account!
* On entry to your code, you are free to (and probably should) reset the
  stack, and can trash any registers you wish.
* The loader **does not** expect to be returned to. It _will_ handle
  such a condition gracefully, however (it will print a message and halt
  the machine).

## Runtime Support

This loader provides a couple of routines that can be used for e.g. debugging
output and basic system control. These can be found at TRAP #14. 

To use these, set D1 to the required 'function code' from the list below.
The way further arguments are passed depends on the function being called.

| Function (D1) | Name            | Description                                                           |
|:-------------:|-----------------|-----------------------------------------------------------------------|
|0              | PRINT           | Print a string via UART. A0 should point to a null-terminated string. |
|1              | PRINTLN         | Print a string, followed by CRLF. A0 points to null-terminated string.|

(More will be added in the future)

Calling these traps will usually trash at least D0, and obviously you'll
need to modify D1 for the function code. The println traps also modify A0.
GCC is mostly fine with this, but it's nice to save and restore stuff in
case you use a different compiler that isn't and forget about it, for
example. An example way to call these functions while looking after your
registers might be (taken from the poc-kernel):

```
mcPrint::
    movem.l D0-D1/A0,-(A7)            ; Save regs
    move.l  (16,A7),A0                ; Get C char* from the stack into A0
    move.l  #0,D1                     ; Func code is 0
    trap    #14                       ; TRAP to firmware
    movem.l (A7)+,D0-D1/A0            ; Restore regs
    rts                               ; We're done.
```

As a side-note, the println traps actually leave A0 pointing to the byte
_after_ the null terminator, so you can make use of that if you have a 
bunch of lines in adjacent memory locations if you want to.

(Of course, if you're going to do that, you're much better off having them be
one big string with line endings embedded, and just printing them with 
one TRAP, but it might come in handy for some reason or another...)

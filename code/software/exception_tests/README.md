# C Exception Handling example for rosco_m68k

This project uses the `<machine/exceptions.h>` header from the standard 
library to implement fairly-easy-to-use C exception handlers. 

These use a tiny Assembler stub to call the C handler with the stack 
set up correctly. `__attribute__((interrupt))` is not used, as that 
attribute doesn't affect where GCC looks for arguments on the stack, 
so makes it more difficult to pass in the `CPUExceptionFrame` structure
to the handler.

Instead, the stub does a `JSR` to the handler, which leaves the stack
in an appropriate state for the struct to just be the argument to the
handler.

In this example, the C handler is a bus error handler. Bus error handlers
are required to do some work with the exception frame in order to tell
the CPU what they want to do. Here, all that work is done in C, using
the main `CPUExceptionFrame` struct and the various `define`s from the
`machine/exceptions` header.
 
## What next?

* Have a look at `kmain.c` to see the C handler.
* Have a look at `funcs.asm` to see the (tiny) stub and how it's installed.
* Build and run to see it in action!

## Building

```
make clean all
```

This will build `exceptions.bin`, which can be uploaded to a board that
is running the `serial-receive` firmware, or placed on an SD card
(Firmware 1.3 and up).

If you're feeling adventurous (and have ckermit installed), you
can try:

```
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which
must obviously be connected and waiting for the upload).


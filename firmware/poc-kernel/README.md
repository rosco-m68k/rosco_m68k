# Proof-of-concept "kernel" for serial bootloader

This is an extremely simple proof-of-concept "kernel" that can be
loaded by the serial bootloader (see ../serial-receive).

This code essentially does nothing - it exists mainly to prove the
bootloader works, and also to exemplify how one might build and
link a real kernel to be loaded by the serial loader.

## Building

```
make clean all
```

This will build `kernel.bin`, which can be uploaded to a board that
is running the `serial-receive` firmware.

If you're feeling adventurous (and have ckermit installed), you
can try:

```
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which
must obviously be connected and waiting for the upload).

## Creating your own kernel

If you want to write your own (real) kernel (or other program that
can be loaded by the serial loader) then this code might serve as a
reasonable starting point for that. Using the code here, you get the
following for free:

* Entry point in C - kmain()
* .data and .bss initialized automatically
* Automatic relocation of your code post loading
* Access to the utility functions of the bootloader (e.g. debug output)
* Simple linkage (with the included link script)
* A mostly sane memory layout (with some helper functions - see mem.h)



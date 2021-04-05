# Proof-of-concept "kernel" for serial bootloader

This is an extremely simple proof-of-concept "kernel" that can be
loaded by the serial bootloader (see ../serial-receive).

The code just does a small demonstration / proof of the Easy68K
compatibility code, and then goes into a readline loop.

It can optionally do a linkage check, see "Optional extras", 
below. This just checks that the code has been linked as 
expected.

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

## Optional extras

There are two optional things that can be built into the POC kernel,
a C-compatible library that exposes the Easy68K IO functions, and
a (naive) linkage checker which can be useful when debugging.

### Linkage check

To include the linkage checker (and run it at bootup), include
`LINKCHECK=true` in the `make` command line, e.g:

  `make LINKCHECK=true`

Note that this is very simple, and really just checks that 
the `.data` and `.bss` sections appear to be in the right
places and have been initialized with the correct data. 

This allows you to sanity check that e.g. your code has been
relocated post-loading, for example, and so is here as a
debugging tool.

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



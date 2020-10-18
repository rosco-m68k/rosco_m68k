# Rosco_m68k Standard Libraries

This directory contains the standard libraries that support writing
programs for the rosco_m68k. The libraries are contained in 
subdirectories of the `src` directory.

Specifically:

| Filename            | Description                                    |
|:-------------------:|------------------------------------------------|
| cstdlib             | Bare-minimum C stdlib required for examples    |
| easy68k             | C interface to the Easy68k compatibility layer |
| gpio                | Functions for intefacing with the GPIOs & SPI  |
| machine             | Low-level functions and basic IO               |
| printf              | An implementation of `printf`                  |
| rtlsupport          | Replacement for some GCC math routines         |
| sdfat               | Exposes firmware SD support (where available)  |
| start_serial        | Link scripts and start files for programs      |

**Note 1**: The `printf` lib provides two versions of the library, 
one with support for software floating point, and the other without.
While the floating-point one is obviously more complete, it is larget
than the one without, so if space is a consideration you may want to 
link `-lprintf` instead of `-lprintf-softfloat`.

**Note 2**: When building with the SDFAT library, you will currently 
need to disable the warning about unused functions. To do this, add
`-Wno-unused-function` to your `CFLAGS`.
 
## Documentation

I'm working on documenting the individual libraries, but for now see
the example programs for sample usage, and have a look in the individual
`include` directories (e.g `src/cstdlib/include`) to see what functions
are available for the individual libraries.

## Getting Started

### GNU Toolchain

If you don't yet have a GNU M68k toolchain, you'll need to build one.
See https://github.com/roscopeco/rosco_m68k/blob/master/code/Toolchain.md 
for help with that. 

You'll need to have that toolchain somewhere in your path (`~/opt/cross`
is recommended and assumed by the documentation, though of course you
can place it wherever suits you).

### Building the libraries

These libraries must be built before the example programs can be 
built - this is simple to do:

```
make install
```

This doesn't install anything globally on your system - it just builds
all the libraries and makes them available under `libs/build`, where the
rest of the programs expect to find them.

You'll probably want to use these libraries in your own code too, so it's
always worth building them, even if you're not building the examples.

> **Note** Any problems at this point are likely due to an incomplete or
  incorrectly built toolchain. See 
  https://github.com/roscopeco/rosco_m68k/blob/master/code/Toolchain.md
  for help building a correct toolchain with the expected versions.
  While building with GCC > 7.5.0 should work (please file a bug if you
  find it doesn't!) building with older versions is not supported.

## Usage

## The `serial_start` library

The `serial_start` library is special - it doesn't directly export any 
usable functions for your code. Instead, it provides the standard 
initialisation and startup code for rosco_m68k programs. 

The recommended way to build programs that will be loaded by the
serial bootloader is to link against this library, and additionally
use the link scripts that it provides. By doing this, you don't have
to worry about relocating your code after it's loaded by the bootloader,
or initialising the `.data` and `.bss` sections. The library takes care
of all that for you.

An example of linking correctly with the `serial_start` library and using
the correct linker script might be:

```
export LIBDIR=../libs/build
m68k-elf-gcc -ffreestanding -o kmain.o -c kmain.c
m68k-elf-ld T $LIBDIR/ld/serial/rosco_m68k_program.ld -L $LIBDIR -o myprog.bin main.o -lstart_serial
```

For a more complete example, see the `Makefile` in one of the example
projects.

> **Note** that the `serial_start` library expects the entry point of your
  program to be called `kmain`, not `main`. This helps when porting other
  software to the rosco_m68k, as it means you don't have to change the
  original source, and can do any initialisation you need to before
  calling `main` from your `kmain` function.

> **Note**: For details of the specific environment at program entry when
  using the `serial_start` library, see the README.md in the `serial_start`
  directory.

### Linking against the libraries

As seen in the previous section, linking against the libraries is pretty
simple: just tell `ld` the path to the built libraries (by default this
will be the `build` subdirectory of the `libs` directory) and pass
each library you want to link against with a `-l` argument, e.g. `-lcstdlib`.

> **Note** that, because of the way `ld` works, you **must** pass the `-l`
  link options after all other options, or you're likely to get symbol not
  found errors. Furthermore, the order of the `-l` options matters too - 
  generally, libraries that are depended on by other libraries must come
  **after** the libraries that depend upon them!

Many of the libraries also provide some C headers which, if you're building
a C program, you'll probably want to reference those headers. 

To do this, pass in the `build/include` directory to GCC with the `-I` option,
e.g. `-I../libs/build/include`. By doing this, you ensure that GCC can find
them when you do `#include <someheader.h>` in your code. 


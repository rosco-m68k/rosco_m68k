# Software

This directory contains various different software programs for the 
rosco_m68k. 

Specifically:

| Filename            | Description                                    |
|:-------------------:|------------------------------------------------|
| poc-kernel          | POC "kernel", compatible with `serial-receive` |
| adventure           | A port of Jeff Tranter's 'Adventure' (game).   | 
| gpiodemo            | Stupid-simple GPIO example                     |
| libs                | All shared functions are built as libraries.   |
| memcheck            | A simple memory checker / counter              |
| starter_c           | A blank C project you can start from           |
| starter_asm         | A blank assembler project you can start from   |

## Getting Started

### GNU Toolchain

If you don't yet have a GNU M68k toolchain, you'll need to build one.
See https://github.com/roscopeco/rosco_m68k/blob/master/code/Toolchain.md 
for help with that. 

You'll need to have that toolchain somewhere in your path (`~/opt/cross`
is recommended and assumed by the documentation, though of course you
can place it wherever suits you).

### Shared Libraries

The `libs` directory contains code that the other programs depend on. 
At a minimum, most (if not all) programs depend on the `start_serial`
library, which provides the entry point for programs loaded by the 
serial firmware and takes care of relocating loaded code and running
the `kmain` method.

The libraries must be built before the rest of the programs can be 
built - this is simple:

```
cd libs
make install
```

This doesn't install anything globally on your system - it just builds
all the libraries and makes them available under `libs/build`, where the
rest of the programs expect to find them.

> **Note** Any problems at this point are likely due to an incomplete or
  incorrectly built toolchain. See 
  https://github.com/roscopeco/rosco_m68k/blob/master/code/Toolchain.md
  for help building a correct toolchain with the expected versions.
  While building with GCC > 7.5.0 should work (please file a bug if you
  find it doesn't!) building with older versions is not supported.

## Building the examples

Each of the example programs contains a `Make` build - simply `cd` into
the appropriate directory and type `make all`.

This will build a few different artefacts, chief amongst which will be
the `bin` file, which is a serial-bootloader compatible binary that 
can be uploaded to your rosco_m68k via Kermit.

There is a short `README.md` in each program directory that contains
documentation specific to that program - see those for detailes of the
program and any specific build instructions.

## Building your own projects

> If you're building your own programs outside the directory tree of this
project you might find it more convenient to copy the built libs to
some other directory, e.g. `cp -r libs/build ~/rosco_m68k`.

If you want to get started with building your own code for the rosco_m68k,
an easy way to get started is to copy one of the example projects and 
modify the Makefile to suit your needs. 

There are two starter projects that are design for just this purpose:

* `starter_c` - A basic starter project for C code
* `starter_asm` - A basic starter project for Assembler

Simply pick which suits your needs, copy the whole directory and 
add your code as needed. You'll probably also want to edit the Makefile
to fix paths to the standard libraries and include files depending
on where you copy the directory to.

> Although pretty empty, these starter projects **do** still depend on
  the standard libraries having already been built - see the "Getting
  Started" section for details on that.

When developing your own code, you can of course use any of the standard
libraries. See the README.md in the `libs` directory for details of 
each library and what it provides and how to use them.


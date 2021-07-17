# Software

This directory contains various different software programs for the 
rosco_m68k.

> If you are looking for a template project for your own software (including some specific Makefile recommendations), please see the `starter_projects` directory. 

Specifically:

| Filename            | Description                                    |
|:-------------------:|------------------------------------------------|
| 2dmaze              | A 2d maze demo of libm (thanks to mattuna15)   |
| 68010-test          | A simple program we use to test suspect CPUs   |
| adventure           | A port of Jeff Tranter's 'Adventure' (game).   | 
| bbsd                | Bit-banged SD demo. Obsoleted by firmware      |
| dhrystone           | Dhrystone benchmark (thanks to Xark)           |
| easy68k-demo        | Demo of the easy68k firmware interface         |
| ehbasic             | Lee Davison's ehBASIC (rosco_m68k port)        |
| exception_tests     | Examples of using the exception std libraries  |
| lcd-ili9341         | SPI demo with ILI9341 LCD (thanks to Xark)     |
| libs                | All shared functions are built as libraries.   |
| life                | Conway's Game of Life (thanks to mattuna15)    |
| memcheck            | Memory checker / basic sysinfo tool            |
| sdfat_demo          | Demo code for using firmware SD interface      |
| sdfat_menu          | **Awesome** SD Card bootload menu (thanks Xark)| 
| gpiodemo            | Stupid-simple GPIO example                     |
| vterm               | ANSI terminal emulation (thanks to mattuna15)  |
 
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

You can build all example programs in one go by simple typing `make` 
in this directory. This will build binaries for each example in their
respective directories.

Alternatively, each of the example programs contains a `Make` build - 
simply `cd` into the appropriate directory and type `make all`.

This will build a few different artefacts, chief amongst which will be
the `bin` file, which is a serial-bootloader compatible binary that 
can be uploaded to your rosco_m68k via Kermit.

There is a short `README.md` in each program directory that contains
documentation specific to that program - see those for detailes of the
program and any specific build instructions.

## Building your own projects

There are some template starter projects available in `../starter_projects`,
take a look at the documentation there for how to use them.


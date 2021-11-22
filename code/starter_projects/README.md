# Starter Projects in C and Assembly

This directory contains two template projects you can use to get started
with your own software. There is a template for C, and another for 
Assembly. Both of these starters have the following features:

* A simple working example `kmain` in the chosen language
* A `Makefile` build that takes care of finding the standard libraries and other code
* Some standard `make` targets for building, running etc.

To use the standard build, you should set an environment variable 
`ROSCO_M68K_DIR` to the top-level directory of this project.

You will also need to have build and installed the standard libraries
(see `README.md` in `../software` for instructions if you haven't 
already done that).

| Filename            | Description                                    |
|:-------------------:|------------------------------------------------|
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

## Building the starter projects


Each of the starter projects contains a `Make` build - 
simply `cd` into the appropriate directory and type `make all`.

This will build a few different artefacts, chief amongst which will be
the `bin` file, which is a serial-bootloader compatible binary that 
can be uploaded to your rosco_m68k via Kermit.

## Building your own projects

As mentioned, there are two starter projects:

* `starter_c` - A basic starter project for C code
* `starter_asm` - A basic starter project for Assembler

Simply pick which suits your needs, copy the whole directory and 
add your code as needed. As long as your `ROSCO_M68K_DIR` environment
variable is set, the build should find the standard libraries and
other rosco_m68k code as needed.

> Although pretty empty, these starter projects **do** still depend on
  the standard libraries having already been built - see the "Getting
  Started" section for details on that.

When developing your own code, you can of course use any of the standard
libraries. See the README.md in the `../software/libs` directory for details of 
each library and what it provides and how to use them.


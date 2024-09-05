# rosco_m68k Firmware v2.0
## For all Revision 1.x & Revision 2.x rosco_m68k Classic main boards

This is the official version 2.0 firmware for all rosco_m68k Classic boards.

It provides basic machine initialization, a rich API for use by software,
and a variety of boot loaders to enable flexible loading of code into the
machine at boot time.

Drivers are included here for the MC68901 (Revision 1.x only), MC68681 
(and XR68C681), V9958, Xark's Xosera, MarkM's IDE (ATA) interface, and 
the built-in (bit-banged) SPI and SD Card interfaces, and (where 
appropriate) a firmware interface to enable easy use is also provided 
(see InterfaceReference.md).

## Building

> **Note** To build this, you will require the `m68k-elf-rosco` toolchain.
> This can be installed from source, or via the homebrew tap.

> **Note** This build uses submodules. Ensure you initialize them before 
> you start working with the code:
>
> `git submodule update --init --recursive`
>
> If you don't, you'll get weird errors (at best) or build broken firmware.

The build supports building either 1MB (for Revision 2.x mainboards) or 
64KB ROMs (for Revision 1.x mainboards). Selected options will vary depending
on the ROM size being built. 

Note that, unlike the 1.x firmware series, no support is provided for 16KB ROMs.

To build all options included for revision 2.x boards, just `make`, e.g:

```
make clean all
```

If you wish to build for revision 1.x boards, build with REVISION1X=true, e.g.

```
REVISION1X=true make clean all
```

You can optionally include/exclude various things - see the `Makefile` for 
details.

### Burning

If you are using a TL866II+ programmer, you can burn your ROMs 
directly from the Makefile with:

```
make burn
```

This will automatically set the device to whatever is appropriate for the
ROM size you built (SST39SF040 for R2.x, AT28C256 for R1.x). This can be 
overriden by passing `ROMDEVICE` on the command line, e.g:

```
ROMDEVICE=<SOMEDEVICE> make clean burn
``` 

Where `<SOMEDEVICE>` is a Minipro-recognised device string.

## SD Card 

The SD Card connects to the dedicated SD card connector on the r2 and
r1.2 mainboards. See https://github.com/rosco-m68k/rosco_m68k/blob/develop/SDCardGuide.md
for further details.

SD Cards must be FAT formatted, and will be recognised and scanned 
at boot. If a file named `ROSCODE1.BIN` is found in the root directory,
it will be loaded automatically. 

Binaries built with the `start_serial` standard library (which includes
all example programs) will work from SD card without modification.

## Serial Loader (Kermit)

### Protocols

Currently, only Kermit is supported, and only in the `robust` mode. To support
cautious or fast mode would probably need hardware flow control, for which
most FTDI adapters implement inadequate support.

This is mildly annoying as it requires one to install additional software 
to get Kermit support from the command line, or in minicom. On most Unices
you should be able to install from your package manager (try `ckermit` or 
`c-kermit`). On OSX you can install from homebrew (`brew install c-kermit`) 
and ports probably has it too. On Windows YMMV, but if you're successfully
building this on Windows then you've probably already done a lot of work to
get a cross-compiler and so on working, so I'm sure you'll figure it out.

If you are having problems getting Kermit to work on Linux (especially
Debian or derivatives) you may find that building this patched version
from source helps: https://github.com/rosco-m68k/ckermit

### Kermit Settings

It is **strongly** recommended you use the following settings for your
c-kermit. These should go in your `~/.kermrc` file (or whatever the 
Windows equivalent is):

```
set carrier-watch off ;
set flow xon/xoff ;
robust
```

This instructs c-kermit not to look for a carrier detect signal, to use
software flow-control (because all FTDI chips I've seen get RTS/CTS 
just wrong enough to make them useless without a FIFO on the receiving 
end), and to use the `robust` kermit protocol variant, which is the only 
one I've been able to get to work with the embedded Kermit implementation 
in the bootloader - YMMV of course, feel free to experiment...

You'll need this (at least the carrier detect disable) whether you're
using c-kermit from the command-line or from minicom (or similar).

Of course if your FTDI adapter has a CD pin and you tie this low, you
can skip the carrier-detect setting...
 
## Code

For details of the standard libraries and how to use them to write your
own code, see the examples and the README in the software directory:
https://github.com/rosco-m68k/rosco_m68k/blob/develop/code/software/README.md

You will also find some template projects that get you started with 
either C/C++ or Assembly development at 
https://github.com/rosco-m68k/rosco_m68k/tree/develop/code/starter_projects

The primary reference for the software interfaces provided by the 
firmware can be found here: 
https://github.com/rosco-m68k/rosco_m68k/blob/develop/code/firmware/rosco_m68k_firmware/InterfaceReference.md

* Code is loaded at $40000 (somewhat arbitrarily). The loader will jump
  directly to that location after the code is received.
* This means you are limited to ~860KB with the standard memory configuration.
* (It's actually slightly more, but the stack is at the top of RAM!)
* Once your code is loaded, all of RAM is yours.
* If you use the `heap` standard library, most of this memory will be dedicated
  to your heap, with 32KB being reserved for stack.
* Depending how much setup you want to do, you might leave the lowest 1KB 
  alone (exception vectors), other than setting up any vectors your code
  actually wants to handle.
* If you want to use the standard runtime support stuff (see below), leave the
  bottom 8KB alone (i.e. $2000-$FFFFF are free for your use).

Most of the following things are taken care of automatically if you use the
`start_serial` library (and link using the provided link script). 

The starter projects linked above take care of this for you.
 
* The _recommended_ thing to do is to relocate your code after loading,
  so you don't have it stuck in the middle of RAM. This will make your
  life easier later.
* Obviously your link script will need to take this into account!
* On entry to your code, you are free to (and probably should) reset the
  stack, and can trash any registers you wish. 
* The loader **does not** expect to be returned to. It _will_ handle
  such a condition gracefully, however (it will print a message and halt
  the machine).
  
On entry to the loaded code, the system will be in the following state:

* CPU will be in supervisor mode
* PC will be at $40000
* VBR will point to $0
* Supervisor stack will be at the top of RAM, SSP could be anywhere and can be reset
* Registers will be undefined, and can all be trashed.
* Exception table will be set up (with mostly no-op handlers) from $0 - $3FF 
* Some (very) basic system data will exist between $400-$4FF. You can trash this if you don't need it
  * Some of the default exception handlers **do** write to this area, however!
  * So replace them if you're going to use this area for your own purposes!
* Interrupts (level 2 and above) will be enabled  
* A default exception handler (that will print some debugging information) will
  be installed.
* The system timer will be driving a 100Hz system tick
* System tick will be vectored to CPU vector 0x45, default handler flashes I0.
* DUART/MFP Interrupts other than Timer C will be disabled
* TRAP#13, TRAP#14, TRAP#15 will be hooked by the firmware to provide some basic 
  IO.
* UART TX and RX will be enabled, but their interrupts won't be 
  * you'll either have to enable (and handle) them or use polling
  * If you _do_ enable them, don't use the TRAP#14 IO routines any more or sadness is likely to ensue.

## Runtime Support

See InterfaceReference.md for full details of the runtime interfaces,
TRAPs and memory layout supported by this firmware, including the 
Easy68k compatibility layer.


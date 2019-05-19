# Motorola 68k single-board computer

This repository holds design files, firmware and software for my m68k 
single-board computer, AKA the Rosco_m68k.

You can find the project along with some logs about its development
on Hackaday: https://hackaday.io/project/164305-yet-another-m68k-homebrew

All Software released under the MIT licence. See LICENSE for details.
All Hardware released under the CERN Open Hardware licence.See LICENCE.hardware.txt.

## Current design

Currently, the design for the system is:

* MC68010P10 at 8MHz, /DTACK grounded
* 16KB IO Space (0xF80000 - 0xFEFFFF)
* 16KB ROM (at 0xFC0000)
* 1MB RAM (0x0 - 0xFFFFF)
* TTL-based address decoding

In terms of software:

* Simple code in ROM to do various tests etc.
* Built with GCC and VASM

## Next steps

* Integrate MC68901 MFP
  * This will provide timers, and a UART we can use to hook up a terminal. It also has some GPIOs and does interrupt handling (I already have the IC).
* Graphics - I'm thinking maybe Yamaha V9958 (assuming I can get hold of one)
  * I would have liked to have used a Denise, but that would probably also require a (non-breadboard-friendly) Agnus.
  * The datasheet and manual for the Denise probably aren't as easy to come by or complete, so there'd be more reverse-engineering.
  * And anyway, the Yamaha looks like a nice chip to play with...
* OS - Once the timers are available and I have some I/O capability, I want to build out the OS.
  * Microkernel architecture (Similar in principle to Exec)
  * Preemptive multitasking
  * External storage (probably CF or SD in the first instance, though SD would require level shifting).

## Ideas for future enhancement

### Minimal memory protection

Extend address decoder to disallow access to certain locations based on 68k function pins.
E.g. in user mode:

* Disallow ROM
* Disallow IO
* Disallow xKB at bottom of RAM (ExVecs and kernel heap)

The last one would make null dereferences generate a bus error.


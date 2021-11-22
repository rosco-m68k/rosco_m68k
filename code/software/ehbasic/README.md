# Enhanced Basic for rosco_m68k

This is a port of Lee Davison's Enhanced Basic for 680x0 to the rosco_m68k.

It can be loaded into RAM (by the serial bootloader) where it will currently run
directly from the load address (i.e. it does not relocate low like most of the 
other software does, because of some idiosyncracies in the way its memory is laid
out - this is likely to change in the future). BASIC RAM is kept below this and 
comprises 128K at the moment.

It should also support being built into a ROM, though this is as-yet untested.

Note that EhBASIC, like any good BASIC, is case-sensitive! Commands must be in
uppercase, or you will receive an error message.

References:

1. http://retro.hansotten.nl/home/lee-davison-web-site/
2. http://www.easy68k.com/applications.htm
3. http://sun.hasenbraten.de/vasm/

## Building

### Standard board (Revision 1.x with Firmware 1.3+, or revision 2.x)

Just run `make` to build, with the standard toolchain.

### Standard board (No MC68681 Dual UART expansion, Firmware 1.2 or below)

To work with the with the onboard MC68901, you must pass `FIRMWARE_IO=false`
option to the make command:

`FIRMWARE_IO=false make clean all`

### With MC68681 Dual UART expansion board

To work with the MC68681 expansion on older mainboards (without Firmware
1.3 or above), you must pass `FIRMWARE_IO=false` and `MC68681=true` 
options to the make command:

`FIRMWARE_IO=false MC68681=true make clean all`

------------------------------------------------------------------------

 EhBASIC68

 Enhanced BASIC is a BASIC interpreter for the 68k family microprocessors. It
 is constructed to be quick and powerful and easily ported between 68k systems.
 It requires few resources to run and includes instructions to facilitate easy
 low level handling of hardware devices. It also retains most of the powerful
 high level instructions from similar BASICs.

 EhBASIC is copyright Lee Davison 2002 - 2012 and free for educational or
 personal use only.
 For commercial use please contact me at leeedavison@lgooglemail.com for conditions.

 For more information on EhBASIC68, other versions of EhBASIC and other projects
 please visit my site at ..

  http://mycorner.no-ip.org/index.html

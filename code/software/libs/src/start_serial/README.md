# Rosco_m68k Serial Bootloaded Program Initialiser

This directory contains the standard library that takes care of linking
and loading/initialisation of programs that are loaded by the serial
bootloader.

An example of linking correctly with the `serial_start` library and using
the correct linker script might be:

```bash
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

## Environment at entry

On entry to the `kmain`, the system will be in the following state (some of this
is provided by the firmware: see
https://github.com/roscopeco/rosco_m68k/tree/master/code/firmware/rosco_m68k_v1
for details):

* CPU will be in supervisor mode
* VBR will point to $0
* Exception table will be set up (with mostly no-op handlers) from $0 - $3FF
* Code will be based at $1000, firmware data and SDB will be below this
  * Exception vectors are located at $0 to $3FF
  * If you wish to reuse RAM from $400 to $FFF then some standard libraries can
    no longer be used
  * Some of the default exception handlers do write to this area, so change them
    too!
* Supervisor stack will default to be at top of 1MiB RAM and growing downward
  * override top of RAM using ld option "--defsym=_RAM_SIZE=2M" e.g., for 2MiB.
  * override only stack addresss using ld option e.g., "--defsym=_RAM_SIZE=0x80000"
  * override stack size (default 16KiB) using ld option e.g.,
    "--defsym=_STACK_SIZE=0x1234"
* Interrupts will be enabled
* Bus error, address error and illegal instruction will have default handlers
  (that flash red LED I1 1, 2 or 3 times in a loop)
* MFP Timer C will be driving a 100Hz system tick
* System tick will be vectored to CPU vector 0x45, default handler flashes I0.
* MFP Interrupts other than Timer C will be disabled
* TRAP#14 will be hooked by the firmware to provide some basic IO (see next
  section)
  * This is used by the standard libraries
* TRAP#15 will be hooked by the firmware to provide some basic IO (see next
  section)
  * This is used by Easy68k compatibility layer
* UART TX and RX will be enabled, but their interrupts won't be
  * you'll either have to enable (and handle) them or use polling
  * If you do enable them, don't use the TRAP#14 IO routines any more or sadness
    is likely to ensue.
  * This also means not using the standard libraries for IO!
* CTS (MFP GPIO #7) will be low (i.e. asserted).

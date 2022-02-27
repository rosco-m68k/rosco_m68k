# SST39SF0x0 Firmware Update Utility

This utility allows rosco_m68k models fitted with a FLASH ROM
expansion (and ultimately rosco-pro models) to have their firmware
updated from a single ROM image placed on SD card.

**Note**: This is only compatible with the r2.x rosco_m68k (or r1.x
where the HUGEROM hack is in place, i.e. IC2 is programmed to base ROM
at 0x00e00000 and the flash ROM adapter is fitted).

In order to use this utility, you will need:

* A rosco_m68k ROM image (compiled for HUGEROM, based at 0xe00000).
* Optional: A rosco_m68k-compatible SD card, formatted as FAT

You can either boot this program from the SD card (directly or
via Xark's sdfat_menu) or send it via Kermit.

NOTE: If you are not using an SD card for the ROM image file, then
the ROM image needs to be embedded into the "updateflash.bin" binary.
To do this, when building updateflash set the environment variable
ROM_BIN to the path to the ROM image to embed (and flash when run).

For example (using relative path to v2.1 firmware, which should have been built first):

```shell
  ROM_BIN=../../firmware/rosco_m68k_v2.1/rosco_m68k.rom make clean all
```

When run, this program will look for a file named `rosco_m68k.rom`
in the root directory of the SD card. If found, some (very) minimal
checks will be done, and if these pass it will be programmed into
flash memory.

Notes:

* You **must** make sure the ROM you are flashing is built to run at 0x00e00000
* When using SD card, ROM should be named `rosco_m68k.rom`
* This utility will wait for confirmation before programming (open serial terminal when running).
* It is totally normal for the onboard LEDs to stop flashing during programming

## Building

```shell
make clean all
```

or to embed a ROM image into the updateflash.bin binary (for use without SD card). NOTE: Update
example path shown as needed.

```shell
  ROM_BIN=../../firmware/rosco_m68k_v2.1/rosco_m68k.rom make clean all
```

This will build `updateflash.bin`, which can be uploaded to a board that
is running the standard firmware.

If you're feeling adventurous (and have ckermit installed), you
can try:

```shell
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which
must obviously be connected and waiting for the upload).

This sample uses UTF-8. It's recommended to run minicom with colour
and UTF-8 enabled, for example:

```shell
minicom -D /dev/your-device -c on -R utf-8
```

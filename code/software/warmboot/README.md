# Example of warm boot on rosco_m68k

This is a small example that shows how to reserve rosco memory and add routines that
can persist over a "warm boot" (e.g., when normal C main exits, vs reset button).
It also demonstrates intercepting some firmware EFP vectors.

NOTE: This document is very bare, mostly you need to look at the code. 🙂

## What next

* This is just a proof of concept, it just prints a message before program loading and flashes the red LED while reading characters

## Building

```bash
make clean all
```

This will build `warmboot.bin`, which can be uploaded to a board that
is running the `serial-receive` firmware.

If you're feeling adventurous (and have ckermit installed), you
can try:

```bash
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which
must obviously be connected and waiting for the upload).

This sample uses UTF-8. It's recommended to run minicom with colour
and UTF-8 enabled, for example:

```bash
minicom -D /dev/your-device -c on -R utf-8
```

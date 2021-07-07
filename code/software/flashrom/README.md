# SST39SF0x0 POC direct access lib & example

This is a proof-of-concept of direct access to the SST39SF040 
family of flash ROMs, as used by the r1 HUGEROM hack and the 
rosco-pro.

This is only compatible with the r1.x rosco_m68k where the 
HUGEROM hack is in place (i.e. IC2 is programmed to base ROM
at 0x00e00000) and the flash ROM adapter is fitted.

This demo includes:

* Using the identify commands to display Flash information
* Writing a "configuration area" on the last sector of the flash.

Note that the 040 flash ROMs are required - the write demo will
not work with smaller flash ROMs.

Also note that, since this demo writes to the flash, it will
cause some (very minimal) wear...

## Building

```
make clean all
```

This will build `flashrom.bin`, which can be uploaded to a board that
is running the standard firmware.

If you're feeling adventurous (and have ckermit installed), you
can try:

```
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which
must obviously be connected and waiting for the upload).

This sample uses UTF-8. It's recommended to run minicom with colour
and UTF-8 enabled, for example:

```
minicom -D /dev/your-device -c on -R utf-8
```


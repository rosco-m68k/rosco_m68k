# SST39SF0x0 POC direct access lib & example

This is a proof-of-concept of direct access to the SST39SF0x0 
family of flash ROMs, as used by the r1 HUGEROM hack and the 
rosco-pro.

## Building

```
make clean all
```

This will build `myprogram.bin`, which can be uploaded to a board that
is running the `serial-receive` firmware.

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


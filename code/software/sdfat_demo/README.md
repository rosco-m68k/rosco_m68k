# Firmware SD / Standard FAT library demo

This is a demo of the firmware SD Card functionality and the FAT standard 
library. It requires the (currently-development) ROMs with SD support built
in. It works with either the 16KB or 64KB ROMs.
 
## Building

```
make clean all
```

This will build `sdfat_demo.bin`, which can be uploaded to a board that
is running the `serial-receive` firmware (or can be loaded from SD too
if you have the larger ROMs with the SD loader!).

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


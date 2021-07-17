# C Starter Project for rosco_m68k

This is an empty (well, "Hello World") assembler project. You can use it as 
a starting point for your own programs.
 
## What next?

* Edit `kmain.S` to add your own code.
* Add more assembly or C files. Add them to the `$(OBJECTS)` line in `Makefile`
  * Use the `.o` extension instead of `.S` or `.c` in the `Makefile`!
* If you add C files and call them from assembler, you'll need to take
  care of the stack properly. See other examples or the libs for examples.
* Make this README.md your own!

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


# Maze demo

A demo to show some new routines from stdlib (rand()), libm, and vterm.
Once the random maze has finished drawing you can move around the maze using the cursor keys.

## Building

```
make clean all
```

This will build `life.bin`, which can be uploaded to a board that
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
# Tests that your 68010 really *is* a 68010!

This is a simple test program that ensures your 68010 is an actual
68010, and not a rebadged 68000. This was written because I received
some fakes from eBay.

It only does the most basic check at present - it attempts to use
VBR, which is not present on the 68000, so it'll weed out 68000s
that have been re-badged.

Output:

* If you have a real 68010, I0 (the green LED) will flash quickly
* If you have a rebadged (or fake) 68000, I1 will flash in groups of 3

## Building

```
make clean all
```

This will build `68010test.bin`, which can be uploaded to a board that
is running the `serial-receive` firmware.

If you're feeling adventurous (and have ckermit installed), you
can try:

```
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which
must obviously be connected and waiting for the upload).


# Heap library test

Testing the heap library, malloc/free and new/delete.
 
## Building

```
make clean all
```

This will build `malloc-test.bin`, which can be uploaded to a board that
is running the standard firmware.

If building for a HUGEROM machine (r2.x, or r1.x with adapter) you
should build with:

```
ROSCO_M68K_HUGEROM=true make clean all
```

If you're feeling adventurous (and have ckermit installed), you
can try:

```
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which
must obviously be connected and waiting for the upload).


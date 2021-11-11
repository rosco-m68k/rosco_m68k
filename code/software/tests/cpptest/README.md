# C++ and Global Ctor/Dtor test

Testing C++ and GCC attribute (global) constructor / destructor
support in the `start_serial` library.

## Building

```
make clean all
```

This will build `cpptest.bin`, which can be uploaded to a board that
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

This sample uses UTF-8. It's recommended to run minicom with colour
and UTF-8 enabled, for example:

```
minicom -D /dev/your-device -c on -R utf-8
```


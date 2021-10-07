# Memory checked for rosco_m68k

This runs a check of all memory in the address space and builds a memory map
based on what it finds.

All memory locations are tested by writing, and checking that the value that was
written is successfully read back (after writing to another location to avoid
phantom reads).

## Building

```bash
make clean all
```

This will build `memcheck.bin`, which can be uploaded to a board that is
running the `serial-receive` firmware.

If you're feeling adventurous (and have ckermit installed), you can try:

```bash
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which must
obviously be connected and waiting for the upload).

This sample uses UTF-8. It's recommended to run minicom with colour and UTF-8
enabled, for example:

```bash
minicom -D /dev/your-device -c on -R utf-8
```

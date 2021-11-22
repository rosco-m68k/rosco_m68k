# C Game of Life for rosco_m68k

Based on code from this site: <https://rosettacode.org/wiki/Conway%27s_Game_of_Life>


## Building

```bash
make clean all
```

This will build `life.bin`, which can be uploaded to a board that is running the
`serial-receive` firmware.

If you're feeling adventurous (and have ckermit installed), you can try:

```bash
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which must
obviously be connected and waiting for the upload).

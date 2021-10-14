# Very simple GPIO programming example

This is a very simple example of programming the GPIOs.

In order to actually see this do anything, you'll need to hook up a circuit with
some LEDs or something connected to the GPIO lines.

**Note** If you're going to do that, use transistors - the GPIO's can't directly
drive LEDs! See [example-circuit/circuit.pdf](example-circuit/circuit.pdf) for
an example circuit schematic (in KiCad).

## Building

```text
make clean all
```

This will build `kernel.bin`, which can be uploaded to a board that is running
the `serial-receive` firmware.

If you're feeling adventurous (and have ckermit installed), you can try:

```text
SERIAL=/dev/some-serial-device make load
```

which will attempt to send the binary directly to your board (which must
obviously be connected and waiting for the upload).

**NOTE:** This sample uses UTF-8 (for the "💡" glyph). It's recommended to run minicom with colour
and UTF-8 enabled (or you can alter the program).

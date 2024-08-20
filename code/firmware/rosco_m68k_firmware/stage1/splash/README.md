# Splash / Welcome concept

## Copyright (c)2021-2024 Ross Bamford
## Xosera API (c)2021-2024 Xark
## MIT License

### Building

```
XOSERA_DIR=/path/to/xosera_dir make clean all
```

You might also need to have the ROSCO_M68k_DIR environment variable
set, pointing to the top-level rosco dir with built and installed
libraries.

This will build a binary, which can be uploaded to a board that
is running the standard firmware.

### Switching images

Currently this just displays an image. You can switch which
one by passing `IMAGEBASE=welcome` when doing `make`.

Be sure to do `clean all` when doing this to ensure everything
gets built.

Images **must** be 424x240x8 currently.

# libvterm-ctrl

Libvterm-ctrl is a small ANSI C static library to control terminals compatible with ANSI/ISO/VT-100 control sequences.

Its main target platforms are microcontrollers where curses implementations are often not available and/or not desirable to integrate into a project, but output to a terminal over UART (or other means) is still useful.

## Usage

The library must be initialized with the following function.

```void vt_init ();```

Afterwards, simply call any of the functions available in `vterm.h` to use them. Note that terminals are not guarenteed to support all available functions.

Any escape sequences not wrapped in functions by this library can be sent using the `vt_send` or `vt_nsend` functions.

## Compiling

Libvterm-ctrl is compiled as a static library simply add `-lvterm` to your rosco makefile. 

The example program creates a simple command line interface that can be used to test some features of the library.

## License

Copyright 2018 Bryan Haley under the MIT License. 
Modified 2020 For rosco m68k Matt Pearce

See LICENSE.MD for more information.
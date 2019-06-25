# Early test code for the rosco\_m68k

This directory contains some early test programs for the rosco\_m68k that were written at various stages of the build. Most (if not all by the time you read this) will no longer work with the current board design. They are kept here for posterity, as they may be useful to anyone building their own board for testing at various stages during the build.

The files are in Easy68k syntax as they were written prior to switching to the new VASM/GCC toolchain.

There is also a ruby script here that converts the binaries to C arrays, as was required when I was using my (hacked together) EEPROM programmer.

The latest files in here are mfptest and bootstrap, both of which work as of time of writing (June 2019). They will *not* be kept up to date however, so probably don't work now.


[Home](index.md) | [Getting Started](getting-started.md) | [Connecting](connecting.md) | [Running the Examples](running-the-examples.md) | [Toolchain Installation](toolchain-installation.md) | [Building the Software](building-the-software.md) | [Installing the Emulator](installing-the-emulator.md) | [Debugging with MAME](MAME-serial.md) | [Using SD Cards](SDCardGuide.md)

# Installing the Emulator

The rosco_m68k toolchain includes a fully-featured fork of a popular Open Source emulator, with full support for rosco_m68k and a variety of other retro-style single-board computers.

With the emulator, you get full hardware debugging capabilities, and can run rosco_m68k software in a fully emulated virtual machine, right on your modern computer.

Once you've [got the homebrew tap set up](toolchain-installation.md), installation is simple on macOS® and Linux®.

> **Note:** These instructions apply to macOS® and Linux® only. We recommend that Windows® users use Windows® Subsystem for Linux® or a Linux VM for development.

---

## Installing from Homebrew

This is the recommended option - the emulator can be tricky to build, and it can take a while.

Our homebrew tap contains a pre-configured build with binary bottles for various platforms and architectures.

Assuming you already installed Homebrew and the rosco_m68k tap, you can just do:

```sh
brew install mame-sbc
```

Depending on your platform this may take a little while (and if there isn't a pre-built binary available, you'll need your platform build tooling installed).

Once installed, there's an extra step you'll need to do to set up the default configuration:

```sh
mkdir -p ~/.mamesbc && ln -s $(brew --prefix)/share/mame-sbc/ini/mamesbc.ini ~/.mamesbc/mamesbc.ini
```

This will make a rosco_m68k-specific emulator directory under your home directory, and symlink the default configuration file into it.

Once that's done, you can run it with your favourite rosco_m68k binary:

```sh
sbc rosco_classicv2 -debug -quik <path to rosco_m68k repository>/code/software/memcheck/memcheck.bin
```

Type `g` (for "go") in the debug window that will pop up, and that's it! You should be good to go.

For more details on the emulator and some help using the debugger, refer to the official documentation: [MAME Debugger Docs](https://docs.mamedev.org/debugger/index.html)

---

## Installing from Source

Our emulator is a customised fork of a very popular Open Source emulation project.

You can grab the code from GitHub:

```sh
git clone https://github.com/roscopeco/mame.git
cd mame
make -j9
```

This includes the Open Source ROM files for rosco_m68k and various other single-board computers.

---

---

[Home](index.md) | [Getting Started](getting-started.md) | [Connecting](connecting.md) | [Running the Examples](running-the-examples.md) | [Toolchain Installation](toolchain-installation.md) | [Building the Software](building-the-software.md) | [Installing the Emulator](installing-the-emulator.md) | [Debugging with MAME](MAME-serial.md) | [Using SD Cards](SDCardGuide.md)

Copyright © 2020-2024 The Really Old-School Company Limited. Registered in England and Wales No. 12596175
The Really Old-School Company Ltd, 15 Starthe Bank, GB DE75 7AX Tel: 0330 133 2083

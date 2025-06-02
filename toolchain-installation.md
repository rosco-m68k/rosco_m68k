[Home](index.md) | [Getting Started](getting-started.md) | [Connecting](connecting.md) | [Running the Examples](running-the-examples.md) | [Toolchain Installation](toolchain-installation.md) | [Building the Software](building-the-software.md) | [Installing the Emulator](installing-the-emulator.md) | [Debugging with MAME](MAME-serial.md) | [Using SD Cards](SDCardGuide.md)

# Toolchain Installation

## No toolchain? No problem! Get coding in no time with our simple toolchain installation.

Before you can build any software for the rosco_m68k, you'll need a toolchain. Fortunately, the rosco_m68k comes with a full-featured C/C++ toolchain based on [GCC](https://gcc.gnu.org/), with assembly language support from [VASM](http://sun.hasenbraten.de/vasm/).

And thanks to our handy [Homebrew tap](https://github.com/rosco-m68k/homebrew-toolchain), it's easier than ever to get started cross-compiling software for your rosco_m68k!

> **Note:** These instructions apply to macOS® and Linux® only. We recommend that Windows® users use Windows® Subsystem for Linux® or a Linux VM for development.

---

## Step One - Install Homebrew

Homebrew, billed as The Missing Package Manager for macOS (or Linux), makes it really easy to install a complete, locally-built-from-official-sources VASM/GCC/Binutils cross-compiling toolchain, and it's our recommended way to get started with coding for the rosco_m68k.

If you don't already have Homebrew installed, visit [brew.sh](https://brew.sh/) for a one-line install.

In a nutshell, it involves running the following command in a terminal:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

If you're wary about running arbitrary scripts downloaded from the web, take a look at their [alternative installation instructions](https://docs.brew.sh/Installation) for more options.

> **Note:** If you are on Linux, there are additional steps to take at this point. Please follow the Install section in the [Homebrew on Linux](https://docs.brew.sh/Homebrew-on-Linux#install) documentation.

---

## Step Two - Install the Toolchain

Now that you have Homebrew installed, installing the toolchain is a breeze. The best way to do this depends on your platform.

### On macOS®

```sh
brew tap rosco-m68k/toolchain
brew install rosco-m68k-toolchain@13
```

This will automatically download, build and install all the dependencies that you would normally have to build manually. Homebrew will also keep a record of what's installed, enabling you to easily remove everything if you need to later, and allowing you to receive updates when they become available.

If for some reason you want to install our older bare-metal toolchain, you can do that instead with the following commands:

```sh
brew tap rosco-m68k/toolchain
brew install gcc-cross-m68k@13 vasm-all srecord minipro
```

This isn't recommended for most users, but might be useful if you're working with an older board/firmware branch, or if you have special build requirements and don't need our libc.

### On Linux®

Note: These steps specifically target Debian-based distributions (particularly, Ubuntu 20.04 at present). If you are using a different distribution, you may need to replace `apt-get` with e.g. `yum` or `dnf` in these steps.

Firstly, you'll need to install some essential build software, and then install the cross-compiler and VASM assembler (you'll probably be asked for your password at the sudo step):

```sh
sudo apt-get install gcc g++ srecord
brew tap rosco-m68k/toolchain
brew install rosco-m68k-toolchain@13
```

Just like on macOS®, this will automatically download, build and install all the dependencies that you would normally have to build manually. Homebrew will also keep a record of what's installed, enabling you to easily remove everything if you need to later, and allowing you to receive updates when they become available.

If you want to install minipro (optional, for burning your own EEPROMs):

```sh
brew install minipro
```

Once all that's done, you're ready to rock! 🎉

---

---

[Home](index.md) | [Getting Started](getting-started.md) | [Connecting](connecting.md) | [Running the Examples](running-the-examples.md) | [Toolchain Installation](toolchain-installation.md) | [Building the Software](building-the-software.md) | [Installing the Emulator](installing-the-emulator.md) | [Debugging with MAME](MAME-serial.md) | [Using SD Cards](SDCardGuide.md)

Copyright © 2020-2024 The Really Old-School Company Limited. Registered in England and Wales No. 12596175
The Really Old-School Company Ltd, 15 Starthe Bank, GB DE75 7AX Tel: 0330 133 2083

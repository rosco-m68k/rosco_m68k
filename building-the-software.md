[Home](index.md) | [Getting Started](getting-started.md) | [Connecting](connecting.md) | [Running the Examples](running-the-examples.md) | [Toolchain Installation](toolchain-installation.md) | [Building the Software](building-the-software.md) | [Installing the Emulator](installing-the-emulator.md) | [Debugging with MAME](MAME-serial.md) | [Using SD Cards](SDCardGuide.md)

# Building the Software

Getting started with the software for your new board is as simple as grabbing the source code from GitHub and compiling it for the board.

You'll need a m68k toolchain for this part - if you don't have one, you can easily [install ours using Homebrew →](toolchain-installation.md).

We use git for version control and it's the easiest way to get the code and stay up to date, but you can also grab a zip-file if you prefer. No matter how you get the files the rest of the process is the same, so this document applies to both methods.

> **Note:** These instructions apply to macOS® and Linux® only. We recommend that Windows® users use Windows® Subsystem for Linux® or a Linux VM for development.

---

## Step One - Get The Code

Before we can build the software, you'll need to get a copy of it onto your local machine. You can either use git, or download a zip file.

### Using git

This is our preferred option, and it'll make it easy to stay up to date when we add new stuff. If you've never heard of git, check out [this page](https://www.atlassian.com/git/tutorials/what-is-git) for the lowdown.

If you're on macOS® or Linux, the chances are git is already installed. You can check if you already have git installed by typing:

```sh
git --version
```

If it comes back with a version number, you're all set! Otherwise, use your distribution's package manager to install git. For example:

```sh
sudo dnf install git
# or
sudo apt-get install git
```

To clone the project, navigate to a suitable directory and run:

```sh
git clone https://github.com/rosco-m68k/rosco_m68k.git
```

This will copy the very latest version of everything to your local computer. You'll get the code for everything from the sample programs to the code that runs the glue logic on the board, plus a ton of documentation and other stuff. Once git has done its thing you'll find everything below your current directory, in a directory called `rosco_m68k`.

If you're interested in hardware hacking, you might also want to grab some additional design files, which we keep in a separate repository:

```sh
git clone https://github.com/rosco-m68k/hardware-projects.git
```

But these are totally optional - the main repository contains the main design files for the board alongside all the software.

### Download a zip

If you don't want to use git, that's cool too - you can download the latest release as a zip file from the following links:

- [Main repository](https://github.com/rosco-m68k/rosco_m68k/archive/master.zip)
- [Hardware projects](https://github.com/rosco-m68k/hardware-projects/archive/master.zip)

---

## Exploring

If you want to explore the project a bit before you download it, head on over to [https://github.com/rosco-m68k](https://github.com/rosco-m68k) and have a look around - as well as the code, you'll find our issue tracker, documentation, and a bunch of other stuff. If you're interested in feeding back issues or contributing code, now would be a great time to sign up for a free GitHub account if you don't already have one!

---

## Step Two - Build!

Now you have the code locally you're ready to make sure you can build stuff. If you installed our toolchain, this part should be a breeze.

Firstly, you'll need to build some library code that the other programs share. Execute the following:

```sh
cd rosco_m68k/code/software/libs
make install
```

This won't install anything globally on your machine, instead it will just build the libraries and put them in a standard place within the project where the other code can find them.

Now we're ready to build a program. Run the following commands:

```sh
cd ../adventure
make
```

Assuming everything's installed correctly, this should take a second or two, and will create a file called `adventure.bin` - this is a port of [Jeff Tranter's Adventure](https://github.com/jefftranter/6502/tree/master/c/adventure) to the rosco_m68k, and it's all ready for you to upload to your board and try out!

If you see any errors when building either the libraries or the example program, it's likely your m68k toolchain isn't complete. We highly recommend installing our toolchain from Homebrew, but if you've gone with the option of building it yourself then you'll have to do some debugging. If you're stuck you can always [reach out on discord](https://discord.gg/xpZJmhA) and we'll do what we can to help!

All you need to do now is make sure your rosco_m68k is connected to your computer and up and running, then use minicom (or your terminal of choice) to send the `adventure.bin` file to the board using the Kermit protocol. Once the board receives the binary it will automatically start running it, and you'll be playing a fresh new game of Adventure!

---

## Next Steps

Now that you've tested out the toolchain and know you can successfully build software for your rosco_m68k, it's time to have a look around at the rest of the examples, and maybe even start doing some coding yourself.

The best and most up-to-date documentation can always be found in the project itself. You can either open up the README.md files locally, or they're always available (with formatting) on GitHub. A good place to start is [https://github.com/rosco-m68k/rosco_m68k/tree/master/code/software](https://github.com/rosco-m68k/rosco_m68k/tree/master/code/software) - you'll see a list of directories and files, and the README.md for that directory if you scroll down a bit.

Whenever you navigate to a new directory that has a README.md, you'll see the documentation right there!

---

## Building the Firmware & GAL Code

If you opted to not receive pre-programmed ROMs or PLDs when you ordered your rosco_m68k, you'll be wanting to build the firmware and the GAL code.

You'll find what you need in the following locations:
- `rosco_m68k/code/firmware`
- `rosco_m68k/code/pld`

You'll find fairly extensive documentation for the firmware here: [rosco_m68k_firmware](https://github.com/rosco-m68k/rosco_m68k/tree/develop/code/firmware/rosco_m68k_firmware)

For the glue logic, we've included the compiled JEDEC files in Git. If you want to modify the code, you'll need to grab a copy of GALasm [from here](https://github.com/daveho/GALasm) - it isn't included in the standard toolchain, but is easy to build with your platform compiler.

Once you've built them, there are scripts in each directory that will use minipro (included in the standard toolchain) to burn these to the appropriate chips. This will work fine if your EEPROM burner is supported by minipro - if not, you'll need to use the appropriate software that came with your burner.

As always, if you get stuck, [give us a shout on discord](https://discord.gg/76MhBxJ) and we'll help where we can.

---

---

[Home](index.md) | [Getting Started](getting-started.md) | [Connecting](connecting.md) | [Running the Examples](running-the-examples.md) | [Toolchain Installation](toolchain-installation.md) | [Building the Software](building-the-software.md) | [Installing the Emulator](installing-the-emulator.md) | [Debugging with MAME](MAME-serial.md) | [Using SD Cards](SDCardGuide.md)

Copyright © 2020-2024 The Really Old-School Company Limited. Registered in England and Wales No. 12596175
The Really Old-School Company Ltd, 15 Starthe Bank, GB DE75 7AX Tel: 0330 133 2083

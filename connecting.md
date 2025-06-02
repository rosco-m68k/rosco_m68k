[Home](index.md) | [Getting Started](getting-started.md) | [Connecting](connecting.md) | [Running the Examples](running-the-examples.md) | [Toolchain Installation](toolchain-installation.md) | [Building the Software](building-the-software.md) | [Installing the Emulator](installing-the-emulator.md) | [Debugging with MAME](MAME-serial.md) | [Using SD Cards](SDCardGuide.md)

# Connecting your rosco_m68k

## Once you've built your new old computer, it's time to start talking to it!

Hooking up your rosco_m68k to your regular modern computer is a simple affair, thanks to the wonders of modern technology. USB to Serial (UART) converters are cheap and plentiful, and you might even have received one along with your kit (if you opted for one when you purchased). Let's look at what you'll need to get started.

### You'll need:
- A USB lead with +5V and GND broken out to Dupont® connectors, or alternative power connector
- A USB to Serial converter (sometimes called an FTDI converter) or cable
- A USB Mini-B to A cable

> **Warning!**
> - Incorrectly connecting your rosco_m68k may damage it and other equipment connected to it - Check before you connect!
> - Connecting your rosco_m68k to a power source with a voltage higher than 5V is likely to damage it - Check before you connect!
> - Your USB to Serial converter must be 5V tolerant. Some have a jumper to select either 5V or 3.3V, ensure this is set to 5V - Check before you connect!

---

## Connecting the Power

You'll need some kind of 5V power supply that can connect to the two-pin power header on the rosco_m68k. We use modified USB cables and regular wall-wart adapters for this, but any well-regulated 5V power source will work just fine.

If you don't have a power lead, it's easy to make one from an old USB lead - check out [this video](https://www.youtube.com/watch?v=Vw4d0oMl0Mg), for example.

When connecting the power, be sure to observe the polarity - the pins are clearly marked on the board as **5VDC** and **GND**. If using a USB cable, these should be connected to the red and black wires, respectively. It's really important to connect these correctly, getting them the wrong way round *will* damage your rosco_m68k! If in doubt, use a multimeter to check the polarity before you connect.

---

## Connecting the UART to the USB to Serial Converter

The exact method for doing this will vary depending on the specific converter you have, but the general principle remains the same.

Find the four-pin UART connector on your rosco_m68k - it's on the right side of the board, and the pins are marked **CTS**, **RXD**, **TXD** and **GND**.

Now, on your USB to Serial converter, find the corresponding four pins. Most converters (including the one we optionally supply) will already have headers soldered on for these pins.

Using a four-way wire with DuPont connectors at each end, make the following connections:

| rosco_m68k | USB to Serial Converter |
|------------|------------------------|
| CTS        | CTS                    |
| RXD        | TXD (Sometimes TX)     |
| TXD        | RXD (Sometimes RX)     |
| GND        | GND                    |

Now connect the USB cable from your USB to Serial converter to your computer. The converter will probably have some LEDs that light up at this point, and your computer should recognise it as a new serial device.

The new device should appear in the `/dev` directory, ready for use. On macOS, for example, it's named `/dev/cu.usbserial-XXXX`. You can find it easily by running:

```sh
ls /dev/cu*
```

On Linux, you can find the name of the device by looking at the output of the `dmesg` command.

---

## Connecting an SD Card

If you're running Firmware v1.3 and up, you can connect an SD card using an Arduino SD card adapter. Depending on your board revision, this either connects to a dedicated header (on 1.23 boards and higher) or to J5 (on 1.2 boards and below).

See [this page](https://github.com/rosco-m68k/rosco_m68k/blob/develop/SDCardGuide.md) for a detailed hookup guide, as well as information on supported cards and formatting.

---

## Installing Software and Testing

> **Note:** These instructions apply to macOS® and Linux only. We recommend that Windows® users use a Linux VM.

If you hit compilation failures or other issues with CKermit, you may need to install from source - we maintain a fork of the 9.0.160 version, slightly modified to compile on modern systems: [rosco-m68k/ckermit](https://github.com/rosco-m68k/ckermit).

In this section we'll install two programs, `minicom` and `ckermit`. If you already have them installed, or have another terminal emulator / kermit client that you like, then feel free to skip this section.

We recommend using Homebrew to manage your software. If you don't already have it, you can find simple installation instructions at [brew.sh](https://brew.sh/).

If you're using Linux and don't want to install Homebrew, it's very likely that both these packages are available from your distribution's standard package repositories - you'll be able to install them with `apt-get`, `yum`, `dnf`, or whatever your regular package manager is called.

To install the two packages with Homebrew:

```sh
brew install minicom c-kermit
```

(Note: If using your Linux distribution's package manager, the Kermit package is likely to be called `ckermit` instead of `c-kermit`.)

After installation, both packages should be ready to use, but we need to add a little bit of configuration first.

Create a new file in your home directory called `.kermrc`, or edit the existing one if it already exists. The contents of this file should be:

```
set carrier-watch off ;
set flow xon/xoff ;
robust
```

Now launch minicom:

```sh
minicom -D /dev/cu.usbserial-XXXX -c on -R utf-8
```

Replace `/dev/cu.usbserial-XXXX` with the path to the device you determined in the previous step. On Linux, this will probably start with `/dev/tty...` rather than `/dev/cu...`.

> **Note:** On Mac, you may find that the `Esc+KEY` combination used in the following section doesn't work. If you're using [iTerm2](https://iterm2.com/) you can emulate this combination with the right option key by opening the `Profiles` menu, selecting `Open Profiles`. Click the `Edit Profiles` button, and with the `Default` profile selected in the left pane go to the `Keys` tab in the right pane. Near the bottom of this is an option to change the mapping of the `Right Option` key - change this to be `Esc+`.

Once Minicom has launched, open the options (Esc+O or CTRL-A, O on Linux) and navigate to Serial Port Setup. Edit the options as needed, then escape out and select "Save setup as dfl". Restart minicom to ensure the configuration is loaded.

Power up your rosco_m68k (or hit the reset button if it's already powered up), and you should see the startup message on-screen. Congratulations - you're now all set, and your rosco_m68k can talk to your computer!

From here, you can use Esc+S (Ctrl-A, S on Linux) to initiate a Kermit file transfer, and send a compiled binary program to your board and interact with it in the serial terminal.

Now that the rosco_m68k is successfully talking to your computer, it's time to run some example programs! We'll do that in the [next section](running-the-examples.md).

---

---

[Home](index.md) | [Getting Started](getting-started.md) | [Connecting](connecting.md) | [Running the Examples](running-the-examples.md) | [Toolchain Installation](toolchain-installation.md) | [Building the Software](building-the-software.md) | [Installing the Emulator](installing-the-emulator.md) | [Debugging with MAME](MAME-serial.md) | [Using SD Cards](SDCardGuide.md)

Copyright © 2020 The Really Old-School Company Limited. Registered in England and Wales No. 12596175
The Really Old-School Company Ltd, 15 Starthe Bank, GB DE75 7AX Tel: 0330 133 2083

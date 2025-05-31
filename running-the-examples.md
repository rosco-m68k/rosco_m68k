[Home](index.md) | [Getting Started](getting-started.md) | [Connecting](connecting.md) | [Running the Examples](running-the-examples.md) | [Toolchain Installation](toolchain-installation.md) | [Building the Software](building-the-software.md) | [Installing the Emulator](installing-the-emulator.md) | [Debugging with MAME](MAME-serial.md) | [Using SD Cards](SDCardGuide.md)

# Running the Examples

You've built your board and got it connected, so it's time to run some of the pre-built example programs!

In this section we'll download and unpack the examples and use Minicom and Kermit (which you installed in the previous section) to upload them to your board.

We'll take a quick look at Enhanced BASIC, a very capable BASIC interpreter that's available for numerous retro computers, as well as taking a break to play a game of Jeff Tranter's Abandoned Farmhouse Adventure.

Let's get started!

---

## Step One: Download and Unpack the Examples

Before you can run the examples, you'll need to download them and unpack them somewhere convenient.

You can get the latest version of the example programs [here (zip)](https://github.com/rosco-m68k/example_programs/blob/master/examples/rosco_m68k_examples.zip?raw=true). Download them to your computer, and then unpack them somewhere that you'll easily be able to navigate to in Minicom (we recommend something like `rosco_m68k/examples` under your home directory).

Before you proceed, you might want to have a look at the `README.txt` file that's included - it lists all the examples and has a bit of information about each one.

---

## Step Two: Start Minicom and Upload Enhanced BASIC to Your rosco_m68k

For the first example, we'll run `ehbasic.bin`, which is an Enhanced BASIC interpreter written by Lee Davison.

Firstly, you'll need to launch Minicom (which we installed in the previous section). In a terminal, type:

```sh
minicom -D /dev/cu.usbserial-XXXX -c on -R utf-8
```

Replace `/dev/cu.usbserial-XXXX` with the path to the device you determined in the previous section. On Linux, this will probably start with `/dev/tty...`.

Once Minicom is up and running, hit `Esc+S` (or `Ctrl-A, S` on Linux) and use the arrow keys to select "Kermit" to initiate a Kermit file transfer. Next, navigate to the location where you unzipped the examples.

> **Tip:** Navigating the file system in Minicom is a bit counter-intuitive if you're not used to it. Use the cursor keys to move the yellow bar to the directory you want to enter (or the `..` entry to go up a level) and hit space twice to enter. Once you're in the directory where the example binaries are, select the one you want to run and hit space once, followed by `enter` to select and begin the transfer.

After a short while, the progress screen should disappear and you'll be back in Minicom, with the screen showing the Enhanced BASIC banner, followed by the `Ready` prompt. This means EhBASIC is now loaded and running, waiting for you to type in a BASIC program!

---

## Step Three: Type in a Program!

Now that Enhanced BASIC is up and running, let's try it out. In case your BASIC is as rusty as ours (or maybe you've never seen BASIC before), try the following snippet:

```
10 FOR x = 1 TO 10
20 PRINT "Hello Again"
30 NEXT x
```

A few things to note:
- EhBASIC is case-sensitive when it comes to the commands (FOR, PRINT, NEXT etc) - they must be uppercase
- Each line starts with a line number, which you must type in
- Lines are ended by hitting the enter key

If you make a mistake while typing any of the lines, you can correct with backspace if you notice before hitting enter. If you've already hit enter, simply type the whole line in again (including the line number) - this will replace whatever was previously at that line number.

If you want to see what you typed in again, type:

```
LIST
```

And Enhanced BASIC will print out your program - check it against the listing above to make sure that everything matches (remember, case is important!).

Have a play around with EhBASIC - you can write some surprisingly powerful programs quite easily but be warned - there's currently no way to save your programs on the rosco_m68k (because there's no writeable long-term storage attached to the system yet) so anything you type in will be lost when you reset the computer!

If you want to start a new program without resetting the computer, try the `NEW` command.

For more BASIC examples, see [Wikipedia's BASIC page](https://en.wikipedia.org/wiki/BASIC).

---

## Next Steps

Once you're all done with BASIC, reboot your rosco_m68k and follow the same process as before to load another example program. After all the hard work with BASIC, we'd suggest you relax and take a break long enough for a game of `adventure.bin`, which is a rosco_m68k port of Jeff Tranter's Abandoned Farmhouse Adventure, an old-school text adventure that is a lot of fun to play.

Play around with examples for as long as you like. In the next section we'll be getting into more advanced topics, and looking at installing a cross-compiling toolchain and support software that will enable you to compile the examples yourself from source, as well as developing your own software. [Click here](toolchain-installation.md) if you want to get started with that.

---

---

[Home](index.md) | [Getting Started](getting-started.md) | [Connecting](connecting.md) | [Running the Examples](running-the-examples.md) | [Toolchain Installation](toolchain-installation.md) | [Building the Software](building-the-software.md) | [Installing the Emulator](installing-the-emulator.md) | [Debugging with MAME](MAME-serial.md) | [Using SD Cards](SDCardGuide.md)

Copyright © 2020-2024 The Really Old-School Company Limited. Registered in England and Wales No. 12596175
The Really Old-School Company Ltd, 15 Starthe Bank, GB DE75 7AX Tel: 0330 133 2083

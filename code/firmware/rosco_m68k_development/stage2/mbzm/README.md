# mbzm - eMBedded ZModem or something...

A small, simple, modern(ish) and incomplete ZMODEM implementation, for use in resource-constrained 
environments, or wherever you can find a use for it really.

## Zmodem? Really??

Yes, I am aware that it is the twenty-first century, and ZMODEM is hardly the state of the art.
I wrote this for two reasons:

* I wanted a fun, period-appropriate protocol I could use to load 
programs into my retro computer (https://github.com/roscopeco/rosco_m68k) without
having to pull the ROM chips for each iteration. 

* I haven't implemented Zmodem before and wanted to explore how it worked.

As far as possible, I avoided referring to other ZMODEM implementations and just tried to
implement this using the spec (http://pauillac.inria.fr/~doligez/zmodem/zmodem.txt).
The spec is a bit vague on certain things so I spent quite a bit of time reading old
usenet and forum posts, experimenting, and occasionally peeking at the original `zm.c`
implementation to see how things were supposed to work.

## Features/Limitations

Right now, this is very limited. For one thing, it can only receive. For another, it doesn't deal
with errors in a completely correct way (it _does_ however do the minimum needed to get the 
other end to resend bad packets).

Expanding it to support sending probably wouldn't be all that much work, but I don't need it 
right now so I haven't done it. 

Improving the error handling is a WIP, but it's 'good enough' for my purposes right now
(usage with a 1980's UART).

Other notable things:

* It doesn't do any memory allocation, so it can be used where malloc is unavailable.
* It's _sort-of_ optimised for use in 16/32-bit environments (I wrote it with M68010 as the primary target)
* It doesn't support XON/XOFF flow control (it does enough that it _might_ work with it, but it's not tested
  and it certainly won't shut up when XOFF tells it to!).
* It doesn't support **any** of the advanced features of the protocol (compression etc)

Additionally, the included sample has even more limitations, such as:

* It ignores most of the file information in block 0 (it only takes notice of the filename, not the size, mode, etc)
* Related to the above, it doesn't have any support for rejecting files that are too large! 
* It doesn't support the (optional) ZSINIT frame and will just ignore it
* It doesn't support resume
* It has a ton of other limitations I'm too lazy to list right now...
* ... but it does work for the simple case of receiving data.

Note that this last set aren't limitations of the library _per se_ - it's more that they 
aren't provided by the library, and the example program doesn't implement them either.

## Usage

### Tests

There are some unit tests included. They don't cover everything, but they're a start, and
are likely an improvement over some of the other 30+-year-old code out there.

`make test`

### Sample application

A sample application is included that will receive a file. You can use `sz` or `minicom` or
something to send a file, probably using `socat` or similar to set up a virtual link.

E.g. start socat:

`socat -d -d pty,raw,echo=0 pty,raw,echo=0`

You'll probably need to change the source to open the correct device.

To build the application, just do:

`make`

and then run it:

`./rz <device>`

Now you can use e.g. `sz` to send a file to it:

`sz /path/to/somefile > /dev/pts/1 < /dev/pts/1`

**Be aware** that the sample will blindly overwrite files in the current directory
if it receives a file with the same name!

### Use as a library

To use, you'll need to implement two functions in your code:

```c
ZRESULT zm_recv();
ZRESULT zm_send(uint8_t chr);
```

These should return one of the codes used in the rest of the library
to indicate an error if one occurs (see `ztypes.h` for error codes). 

If there isn't a problem, `recv` should return the next byte from the serial
link. `send` should return `OK`.

The `ZRESULT` type encodes various things depending on the result of the
function. `ztypes.h` defines a few macros that can help with decoding these
results (e.g. `IS_ERROR`, `IS_FIN`, `ZVALUE` etc).

#### Cross-compiling

If using this as part of a larger project, you'll probably want to just pull
the source into your existing build. If, for some reason, you just want to
build the objects for m68k, and you have a cross-compiler, you can do:

`make -f Makefile.m68k`

I use this mostly for testing that changes will still build using my cross
toolchain - it probably isn't actually useful for anything... 

When cross-compiling, especially for a freestanding environment, you might want
to define `ZEMBEDDED` as this will stop the library pulling in any stdlib
dependencies. In this case, you're expected to provide two functions:

* `memset` (I might provide a naive default implementation of this later)
* `strcmp` (this will go away in future)

### Debug/Trace Output

If you define `ZDEBUG` and/or `ZTRACE` when compiling, you can get
a **lot** of output from the library as things happen. This can be useful
if things aren't going your way, but they do require a `printf`. 

If you don't have a `printf` but have something similar, edit the
defines at the bottom of `ztypes.c` to suit.

## Shoutouts

The CRC calculation code comes from the `pkg-sbbs` project on Github
(https://github.com/ftnapps/pkg-sbbs), and is licensed under the GNU GPL.
Because that code works well, is fast, and I have zero interest in calculating 
CRCs myself I took the liberty of grabbing the code and reusing it here.

That code is copyright (c) 2000 Rob Swindell. See the included `LICENSE.smblib`
for license details.

And obviously much respect to the late Chuck Fosberg, without whom 
there would be no protocol to implement.


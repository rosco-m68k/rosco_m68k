# r68k

Run native rosco_m68k binaries on your modern computer.

> **Note**: This is not a complete "emulation" or translation layer
> for a full rosco_m68k system. It implements enough of the system
> to run many general purpose programs, and is great for testing /
> iterating on a thing without having to upload to a real machine. 

> **Also note**: This code is horrific by literally any standard 
> you might care to mention. It grew out of a hack, and happened to 
> become useful. 
>
> We only use it for dev and in our build for running tests, so sorry,
> not sorry.

## Build it

You'll need the rosco_m68k toolchain (or other m68k toolchain of
your choosing) installed, as well as build tools for your platform.

```
make clean all
```

## Run it

```shell
./r68k <rosco_m68k binary file>
```

## That's it

Fin.

# Installing the toolchain

Before you can build any software for the rosco_m68k, you'll need a toolchain.
There are two options for this: the easy way, and the slightly-less easy way.

## The Easy Way - Install with Homebrew

If you have Homebrew (<https://brew.sh>) installed, you can install the
toolchain with the following commands:

```bash
brew tap rosco-m68k/toolchain
brew install gcc-cross-m68k@11 vasm-m68k srecord minipro
```

This will automatically download, build and install all the dependencies that
you _would have_ built if you'd followed the instructions in part two.

It'll take a few minutes, as it builds binutils and GCC from source. Once it's
done, you're ready to rock.

## The Slightly-Less Easy Way - Building the Toolchain

0. Configure build environment (Linux only)

> Note: You may be able to skip this step, as the GCC we're building doesn't
> actually need all of these dependencies and some may be pre-installed on your
> system. Verified that this can definitely be skipped on Mac Catalina.

- flex
- libgmp-dev
- libisl-dev
- libmpfr-dev
- libmpc-dev
- texinfo

e.g.

```bash
sudo yum install flex libgmp-devel libisl-devel limbpfr-devel libmpc-devel texinfo
```

You'll want to have `~/opt/cross/bin` in your path, as well as `~/bin`.

1. Build and install binutils-2.28

```bash
wget http://www.mirrorservice.org/sites/ftp.gnu.org/gnu/binutils/binutils-2.28.tar.bz2
tar xf binutils-2.28.tar.bz2
mkdir build-binutils-2.28-m68k
cd build-binutils-2.28-m68k
../binutils-2.28/configure --prefix=$HOME/opt/cross --target=m68k-elf
make -j$(nproc)       # on Mac, use 'make -j$(sysctl -n hw.physicalcpu)' instead

make install
cd ..
```

2. Build and install gcc-7.5.0

```bash
wget http://www.mirrorservice.org/sites/ftp.gnu.org/gnu/gcc/gcc-7.5.0/gcc-7.5.0.tar.gz
tar xf gcc-7.5.0.tar.gz
mkdir build-gcc-7.5.0-m68k
cd build-gcc-7.5.0-m68k
../gcc-7.5.0/configure --prefix=$HOME/opt/cross --target=m68k-elf --enable-languages=c,c++
make -j$(nproc) all-gcc all-target-libgcc        # on Mac, use 'make -j$(sysctl -n hw.physicalcpu) all-gcc all-target-libgcc' instead
make install-gcc install-target-libgcc
cd ..
```

3. Build and install vasm-1.8f

There's no `make install` for this one so just build it and copy it manually.

```bash
wget http://sun.hasenbraten.de/vasm/release/vasm.tar.gz
tar xf vasm.tar.gz
cd vasm
make CPU=m68k SYNTAX=mot
cp vasmm68k_mot ~/opt/cross/bin
cd ..
```

4. Build and install srecord-1.64

> Note: On Mac, you might need `brew install boost` if you don't already have
> boost installed. This also doesn't work with the standard libtool, so `brew
> install libtool` too (and change the configure command as below) You may get
> errors from Make when building documentation, but these are (or appear to be)
> ignorable.

```bash
wget http://srecord.sourceforge.net/srecord-1.64.tar.gz
tar xf srecord-1.64.tar.gz
cd srecord-1.64
./configure --prefix $HOME/opt/cross     # On Mac: 'LIBTOOL=glibtool ./configure --prefix $HOME/opt/cross'
make
make install
cd ..
```

> Note: On Mac, install didn't install the dylib correctly for reasons I didn't
> have time to investigate. To workaround, I just did `cp
> srecord/.libs/libsrecord.0.dylib ~/opt/cross/lib` and it worked fine.

5. (Optional - if wanting to use TL866-series EEPROM programmer from Linux)

Follow instructions at <https://gitlab.com/DavidGriffith/minipro>. Note that the
instructions are slightly out of date, the udev rules have changed and you
probably want the uaccess version of the 61 files rather than the plugdev one
(at least if you're on a modern systemd-based distribution).

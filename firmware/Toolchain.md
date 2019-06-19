# Building the toolchain

0. Configure build environment

- flex
- libgmp-dev
- libisl-dev
- libmpfr-dev
- libmpc-dev
- texinfo

e.g.

```bash
$ sudo yum install flex libgmp-devel libisl-devel limbpfr-devel libmpc-devel texinfo
```
You'll want to have `~/opt/cross/bin` in your path, as well as `~/bin`.

1. Build and install binutils-2.28

```bash
$ wget http://www.mirrorservice.org/sites/ftp.gnu.org/gnu/binutils/binutils-2.28.tar.bz2
$ tar xf binutils-2.28.tar.bz2
$ mkdir build-binutils-2.28-m68k
$ cd build-binutils-2.28-m68k
$ ../binutils-2.28/configure --prefix=$HOME/opt/cross --target=m68k-elf
$ make -j$(nproc)
$ make install
$ cd ..
```

2. Build and install gcc-7.1.0

```bash
$ wget http://www.mirrorservice.org/sites/ftp.gnu.org/gnu/gcc/gcc-7.1.0/gcc-7.1.0.tar.bz2
$ tar xf gcc-7.1.0.tar.bz2
$ mkdir build-gcc-7.1.0-m68k
$ cd build-gcc-7.1.0-m68k
$ ../gcc-7.1.0/configure --prefix=$HOME/opt/cross --target=m68k-elf --enable-languages=c,c++
$ make -j$(nproc) all-gcc all-target-libgcc
$ make install-gcc install-target-libgcc
$ cd ..
```

3. Build and install vasm-1.8f

There's no `make install` for this one so just build it and copy it manually.

```bash
$ wget http://sun.hasenbraten.de/vasm/release/vasm.tar.gz
$ tar xf vasm.tar.gz
$ cd vasm
$ make CPU=m68k SYNTAX=mot
$ cp vasmm68k_mot ~/opt/cross/bin
$ cd ..
```
 
4. Build and install srecord-1.64

```bash
$ wget http://srecord.sourceforge.net/srecord-1.64.tar.gz
$ tar xf srecord-1.64.tar.gz
$ cd srecord-1.64
$ ./configure --prefix $HOME
$ make
$ make install
$ cd ..
```

5. (Optional - if wanting to use TL866-series EEPROM programmer from Linux)

Follow instructions at https://gitlab.com/DavidGriffith/minipro. Note that the instructions are slightly out of date, the udev rules have changed and you probably want the uaccess version of the 61 files rather than the plugdev one (at least if you're on a modern systemd-based distribution).



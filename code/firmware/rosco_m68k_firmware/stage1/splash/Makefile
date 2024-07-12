# Make rosco_m68k boostrap intro
#

CC=m68k-elf-rosco-gcc

AR?=m68k-elf-rosco-ar
RANLIB?=m68k-elf-rosco-ranlib

CFLAGS=																	\
	-std=c11 -Os -ffreestanding -nostartfiles							\
	-Wall -Werror -Wpedantic -Wno-unused-function -Wno-unused-parameter	\
	-mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE)							\
	-fomit-frame-pointer -fno-delete-null-pointer-checks				\
	$(DEFINES) $(INCLUDES)

EXTRA_CFLAGS+=-std=c2x -Wno-format -Iinclude -I../include
EXTRA_LIBS+=

IMAGEBASE?=splash_green
IMAGEEXT=pcx
IMAGESRC=$(IMAGEBASE).$(IMAGEEXT)

STATICLIB=intro-lib.a

OBJECTS=dprint.o intro.o show_pcx.o

all: $(STATICLIB)

%.o: %.c
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

intro.o: splash.h

splash.h: $(IMAGESRC)
	echo "#ifndef _SPLASH_DATA_H" > $@
	echo "#define _SPLASH_DATA_H" >> $@
	xxd -i $(IMAGESRC) | sed -E "s/$(IMAGEBASE)_$(IMAGEEXT)/splash_data/g" >> $@
	echo "#endif" >> $@

clean: clean-data

clean-data:
	rm -f splash.h intro-lib.a

$(STATICLIB): $(OBJECTS) splash.h
	$(AR)   $(ARFLAGS) $@ $^
	$(RANLIB) $@


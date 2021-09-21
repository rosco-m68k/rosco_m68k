# Make rosco_m68k dhrystone

# Copyright (c)2020 Ross Bamford
# See LICENSE

# Hacked by Xark for dhrystone

-include $(ROSCO_M68K_DIR)/user.mk

CPU?=68010
EXTRA_CFLAGS?=
SYSINCDIR?=../libs/build/include
SYSLIBDIR?=../libs/build/lib
DEFINES=-DROSCO_M68K
CFLAGS=-std=c11 -ffreestanding -nostartfiles -Wall -pedantic -Werror        \
				-I$(SYSINCDIR) -mcpu=$(CPU) -march=$(CPU) -mtune=$(CPU) -O1 \
				-mno-align-int -mno-strict-align -Wno-pedantic              \
				-Wno-maybe-uninitialized $(DEFINES)
GCC_LIBS=$(shell $(CC) --print-search-dirs                                  \
		| grep libraries:\ =                                                \
    | sed 's/libraries: =/-L/g'                                             \
    | sed 's/:/m68000\/ -L/g')m68000/
LIBS=-lprintf -lcstdlib -lmachine -lstart_serial -lgcc

ifeq ($(ROSCO_M68K_HUGEROM),true)
LDSCRIPT?=$(SYSLIBDIR)/ld/serial/hugerom_rosco_m68k_program.ld
else
LDSCRIPT?=$(SYSLIBDIR)/ld/serial/rosco_m68k_program.ld
endif

LDFLAGS=-T $(LDSCRIPT) -L $(SYSLIBDIR) -Map=$(MAP)
ASFLAGS=-Felf -m$(CPU) -quiet $(DEFINES)
CC=m68k-elf-gcc
LD=m68k-elf-ld
AS=vasmm68k_mot
RM=rm -f
KERMIT=kermit

SERIAL?=/dev/modem
BAUD?=9600

# Output config
BINARY_BASENAME=dhrystone
BINARY_EXT=bin
MAP=$(BINARY_BASENAME).map

BINARY=$(BINARY_BASENAME).$(BINARY_EXT)

OBJECTS=kmain.o dhrystone.o

ifeq ($(HAVE_TIMER),true)
DEFINES:=$(DEFINES) -DTIME
endif

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.S
	$(AS) $(ASFLAGS) -o $@ $<

$(BINARY) : $(OBJECTS)
	$(LD) $(LDFLAGS) $(GCC_LIBS) $^ -o $@ $(LIBS)
	-chmod a-x $@

.PHONY: all clean dump

all: $(BINARY)

clean: 
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) $(MAP)

dump: $(BINARY)
	od --endian=big -tx1 $(BINARY)

load: $(BINARY)
	kermit -i -l $(SERIAL) -b $(BAUD) -s $(BINARY)

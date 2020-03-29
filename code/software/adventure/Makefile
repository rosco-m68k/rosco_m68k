# Make rosco_m68k ROM images
# 
# Copyright (c)2020 Ross Bamford
# See LICENSE

EXTRA_CFLAGS?=
DEFINES=-DROSCO_M68K
CFLAGS=-std=c11 -ffreestanding -nostartfiles -Wall -pedantic -Werror		\
				-Iinclude -mcpu=68010 -march=68010 -mtune=68010									\
				-mno-align-int -mno-strict-align $(DEFINES)
LDFLAGS=-T ./rosco_m68k_program.ld -Map=$(MAP)
ASFLAGS=-Felf -m68010 -quiet $(DEFINES)
CC=m68k-elf-gcc
LD=m68k-elf-ld
AS=vasmm68k_mot
RM=rm -f
KERMIT=kermit

SERIAL?=/dev/modem
BAUD?=9600

# Output config
BINARY_BASENAME=adventure
BINARY_EXT=bin
MAP=$(BINARY_BASENAME).map

BINARY=$(BINARY_BASENAME).$(BINARY_EXT)

OBJECTS=init.o kinit.o kmain.o adventure.o

include rtlsupport/include.mk
include easy68k/include.mk
include printf/include.mk
include stdlib/include.mk

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.S
	$(AS) $(ASFLAGS) -o $@ $<

$(BINARY) : $(OBJECTS)
	$(LD) $(LDFLAGS) $^ -o $@
	chmod a-x $@

.PHONY: all clean dump

all: $(BINARY)

clean: 
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) $(MAP)

dump: $(BINARY)
	od --endian=big -tx1 $(BINARY)

load: $(BINARY)
	kermit -i -l $(SERIAL) -b $(BAUD) -s $(BINARY)

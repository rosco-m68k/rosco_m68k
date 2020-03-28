# Make rosco_m68k ROM images
# 
# Copyright (c)2019 Ross Bamford
# See LICENSE

EXTRA_CFLAGS?=
DEFINES=
CFLAGS=-std=c11 -ffreestanding -nostartfiles -Wall -Wpedantic -Werror   \
       -Iinclude -mcpu=68010 -march=68010 -mtune=68010                  \
       -mno-align-int -mno-strict-align $(DEFINES)
LDFLAGS=-T ./rosco_m68k_kloader.ld -Map=rom.map
ASFLAGS=-Felf -m68010 -quiet $(DEFINES)
CC=m68k-elf-gcc
LD=m68k-elf-ld
AS=vasmm68k_mot
RM=rm -f

# Output config
BINARY_BASENAME=serial_receive.rom
BINARY_EXT=bin

BINARY=$(BINARY_BASENAME).$(BINARY_EXT)
BINARY_EVEN=$(BINARY_BASENAME)_even.$(BINARY_EXT)
BINARY_ODD=$(BINARY_BASENAME)_odd.$(BINARY_EXT)

OBJECTS=bootstrap.o rtlsupport.o serial.o critical.o main.o

ifeq ($(PROTO),zmodem)
include zmodem/include.mk
else
include kermit/include.mk
endif

ifneq ($(NOEASY),true)
include easy68k/include.mk
endif

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.S
	$(AS) $(ASFLAGS) -o $@ $<

$(BINARY) : $(OBJECTS)
	$(LD) $(LDFLAGS) $^ -o $@
	chmod a-x $@

$(BINARY_EVEN): $(BINARY)
	srec_cat -output $(BINARY_EVEN) -Binary $(BINARY) -Binary -Split 2 0

$(BINARY_ODD): $(BINARY)
	srec_cat -output $(BINARY_ODD) -Binary $(BINARY) -Binary -Split 2 1

.PHONY: all clean dump

all: $(BINARY_EVEN) $(BINARY_ODD)

clean: 
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) rom.map

dump: $(BINARY)
	od --endian=big -tx1 $(BINARY)

burn: $(BINARY_EVEN) $(BINARY_ODD)
	./burn.sh


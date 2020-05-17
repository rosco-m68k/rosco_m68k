# Make rosco_m68k programs
# 
# Copyright (c)2020 Ross Bamford
# See LICENSE

DEFINES=
CFLAGS=-std=c11 -ffreestanding -Ifat_io_lib -Wno-unused-parameter     \
       -Wall -Werror -Wpedantic -Wno-unused-function              \
			 -Iinclude -I../include -mcpu=68010 -march=68010 -mtune=68010   \
			 -mno-align-int -mno-strict-align $(DEFINES)
LDFLAGS=-T rosco_m68k_stage2.ld -Map=$(MAP)
ASFLAGS=-Felf -m68010 -quiet $(DEFINES)
CC=m68k-elf-gcc
LD=m68k-elf-ld
AS=vasmm68k_mot
RM=rm -f

# Output config
BINARY_BASENAME=loader2
BINARY_EXT=bin
MAP=$(BINARY_BASENAME).map
BINARY=$(BINARY_BASENAME).$(BINARY_EXT)
BINARY_ZIP=$(BINARY).zip

LZG_SRC?=../tools/liblzg/src
LZG?=$(LZG_SRC)/tools/lzg

OBJECTS=start.o serial.o machine.o rtlsupport.o main.o

#include kermit/include.mk
include sdfat/include.mk

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.S
	$(AS) $(ASFLAGS) -o $@ $<

$(BINARY) : $(OBJECTS)
	$(LD) $(LDFLAGS) $^ -o $@ $(LIBS)
	chmod a-x $@

$(BINARY_ZIP): $(BINARY) $(LZG)
	$(LZG) -9 $< $@

$(LZG): $(LZG_SRC)
	make -C $^

.PHONY: all clean

all: $(BINARY_ZIP)

clean: 
	$(RM) $(OBJECTS) $(BINARY) $(MAP)


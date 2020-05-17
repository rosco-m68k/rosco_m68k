# Make rosco_m68k ROM images
# 
# Copyright (c)2019 Ross Bamford
# See LICENSE

EXTRA_CFLAGS?=
DEFINES:=$(DEFINES)
CFLAGS=-std=c11 -ffreestanding -nostartfiles -Wall -Wpedantic -Werror   \
       -Iinclude -mcpu=68010 -march=68010 -mtune=68010 -Os              \
       -mno-align-int -mno-strict-align $(DEFINES)
LDFLAGS=-T ./rosco_m68k_kloader.ld -Map=$(MAP)
ASFLAGS=-Felf -m68010 -quiet $(DEFINES)
CC=m68k-elf-gcc
LD=m68k-elf-ld
AS=vasmm68k_mot
RM=rm -f

# Output config
BINARY_BASENAME=stage1
BINARY_EXT=bin
BLOB_BASENAME=rosco_m68k
BLOB_EXT=rom

BINARY=$(BINARY_BASENAME).$(BINARY_EXT)
MAP=$(BINARY_BASENAME).map
STAGE2_DIR=stage2
STAGE2=$(STAGE2_DIR)/loader2.bin.zip
BLOB=$(BLOB_BASENAME).$(BLOB_EXT)
BLOB_EVEN=$(BLOB_BASENAME)_even.$(BLOB_EXT)
BLOB_ODD=$(BLOB_BASENAME)_odd.$(BLOB_EXT)

ROMDEVICE?=AT28C64B

OBJECTS=bootstrap.o lzgmini_68k.o decompress.o main.o 

ifneq ($(NOEASY),true)
include easy68k/include.mk
endif

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.S
	$(AS) $(ASFLAGS) -o $@ $<

$(STAGE2) : $(STAGE2_DIR)
	make -C $^

$(BINARY) : $(OBJECTS)
	$(LD) $(LDFLAGS) $^ -o $@
	chmod a-x $@

$(BLOB) : $(BINARY) $(STAGE2)
	cat $^ > $@

$(BLOB_EVEN): $(BLOB)
	srec_cat -output $(BLOB_EVEN) -Binary $(BLOB) -Binary -Split 2 0

$(BLOB_ODD): $(BLOB)
	srec_cat -output $(BLOB_ODD) -Binary $(BLOB) -Binary -Split 2 1

.PHONY: all clean dump tools

all: $(BLOB_EVEN) $(BLOB_ODD)

clean:
	make -C $(STAGE2_DIR) clean	
	$(RM) $(OBJECTS) $(BINARY) $(BLOB) $(BLOB_ODD) $(BLOB_EVEN) $(MAP)

burn: $(BLOB_EVEN) $(BLOB_ODD)
	ROMDEVICE=$(ROMDEVICE) ./burn.sh

tools: 
	make -C tools/liblzg/src


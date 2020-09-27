# Make rosco_m68k ROM images
# 
# Copyright (c)2019 Ross Bamford
# See LICENSE

EXTRA_CFLAGS?=
DEFINES:=$(DEFINES)
CFLAGS=-std=c11 -ffreestanding -nostartfiles -Wall -Wpedantic -Werror   \
       -Iinclude -mcpu=68010 -march=68010 -mtune=68010 -Os              \
       -fomit-frame-pointer -mno-align-int -mno-strict-align $(DEFINES)
ifeq ($(BIGROM),true)
LDFLAGS=-T ./rosco_m68k_firmware_64k.ld -Map=$(MAP)
else
LDFLAGS=-T ./rosco_m68k_firmware.ld -Map=$(MAP)
endif
ASFLAGS=-Felf -m68010 -quiet $(DEFINES)
CC=m68k-elf-gcc
LD=m68k-elf-ld
AS=vasmm68k_mot
RM=rm -f

# Output config
BINARY_BASENAME=rosco_m68k
BINARY_EXT=rom

BINARY=$(BINARY_BASENAME).$(BINARY_EXT)
MAP=$(BINARY_BASENAME).map
STAGE2_DIR=stage2
STAGE2_FILE=loader2.bin.zip.o
STAGE2=$(STAGE2_DIR)/$(STAGE2_FILE)
BINARY_EVEN=$(BINARY_BASENAME)_even.$(BINARY_EXT)
BINARY_ODD=$(BINARY_BASENAME)_odd.$(BINARY_EXT)

ifeq ($(BIGROM),true)
ROMDEVICE?=AT28C256
else
ROMDEVICE?=AT28C64B
endif

ifeq ($(NO68681),true)
DEFINES:=$(DEFINES) -DNO_68681
endif

OBJECTS=bootstrap.o lzgmini_68k.o decompress.o ansicon.o trap14.o main1.o 

# Big ROM configuration (enable everything)
ifeq ($(BIGROM),true)
WITH_SDFAT=true
WITH_KERMIT=true
else
# Kermit enabled by default in non-big ROM, pass WITH_KERMIT=false to disable...
WITH_SDFAT?=false
WITH_KERMIT?=true
endif

include easy68k/include.mk

ifneq ($(WITH_VDP),false)
include video9958/include.mk
endif

export WITH_SDFAT
export WITH_KERMIT

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.S
	$(AS) $(ASFLAGS) -o $@ $<

$(STAGE2) : $(STAGE2_DIR)
	make -C $^ $(STAGE2_FILE)

$(BINARY) : $(OBJECTS) $(STAGE2)
	$(LD) $(LDFLAGS) $^ -o $@
	chmod a-x $@

$(BINARY_EVEN): $(BINARY)
	srec_cat -output $(BINARY_EVEN) -Binary $(BINARY) -Binary -Split 2 0

$(BINARY_ODD): $(BINARY)
	srec_cat -output $(BINARY_ODD) -Binary $(BINARY) -Binary -Split 2 1

.PHONY: all clean dump tools

all: $(BINARY_EVEN) $(BINARY_ODD)

clean:
	make -C $(STAGE2_DIR) clean	
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) $(MAP)

burn: $(BINARY_EVEN) $(BINARY_ODD)
	ROMDEVICE=$(ROMDEVICE) ./burn.sh

tools: 
	make -C tools/liblzg/src


# Make rosco_m68k programs
# 
# Copyright (c)2020 Ross Bamford
# See LICENSE

CPU?=68010
ARCH?=$(CPU)
TUNE?=$(CPU)
DEFINES=
BASE_CFLAGS=-std=c11 -ffreestanding -Wno-unused-parameter     															\
            -fomit-frame-pointer -Wall -Werror -Wpedantic -Wno-unused-function							\
            -Ifat_io_lib -Iinclude -I../include -mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE)	\
            $(DEFINES)
EXTRA_CFLAGS=
CFLAGS=$(BASE_CFLAGS) -O9
SIZE_CFLAGS=$(BASE_CFLAGS) -Os
LDFLAGS=-T rosco_m68k_stage2.ld -Map=$(MAP)
ASFLAGS=-Felf -m$(CPU) -quiet $(DEFINES)
CC=m68k-elf-gcc
LD=m68k-elf-ld
AS=vasmm68k_mot
RM=rm -f

# GCC-version-specific settings
ifneq ($(findstring GCC,$(shell $(CC) --version 2>/dev/null)),)
CC_VERSION:=$(shell $(CC) -dumpfullversion)
CC_MAJOR:=$(firstword $(subst ., ,$(CC_VERSION)))
# If this is GCC 12 or 13, add flag --param=min-pagesize=0 to CFLAGS
ifeq ($(CC_MAJOR),12)
CFLAGS+=--param=min-pagesize=0
endif
ifeq ($(CC_MAJOR),13)
CFLAGS+=--param=min-pagesize=0
endif
endif

# Output config
BINARY_BASENAME=loader2
BINARY_EXT=bin
MAP=$(BINARY_BASENAME).map
BINARY=$(BINARY_BASENAME).$(BINARY_EXT)
BINARY_ZIP=$(BINARY).zip
BINARY_ZIP_OBJ=$(BINARY_ZIP).o

ifeq ($(MAME),true)
DEFINES:=$(DEFINES) -DMAME_FIRMWARE
endif

LZG_SRC?=../tools/liblzg/src
LZG?=$(LZG_SRC)/tools/lzg

OBJECTS=init2.o common.o serial.o machine.o main2.o

ifeq ($(ATA_DEBUG),true)
DEFINES:=$(DEFINES) -DATA_DEBUG
endif
ifeq ($(WITH_KERMIT),true)
include kermit/include.mk
endif
ifeq ($(WITH_BLOCKDEV),true)
include load/include.mk
include part/include.mk
include sdfat/include.mk
include idehdd/include.mk
endif
ifeq ($(REVISION1X),true)
DEFINES:=$(DEFINES) -DREVISION1X
endif

export CFLAGS

main2.o: main2.c
	$(CC) $(SIZE_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

common.o: common.c
	$(CC) $(SIZE_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.asm
	$(AS) $(ASFLAGS) -o $@ $<

$(BINARY) : $(OBJECTS)
	$(LD) $(LDFLAGS) $^ -o $@ $(LIBS)
	-chmod a-x $@

$(BINARY_ZIP): $(BINARY) $(LZG)
	$(LZG) -9 $< $@

$(BINARY_ZIP_OBJ): $(BINARY_ZIP)
	m68k-elf-objcopy -I binary -O elf32-m68k -B m68k --rename-section .data=.zipdata $< $@

$(LZG): $(LZG_SRC)
	make -C $^

.PHONY: all clean

all: $(BINARY_ZIP_OBJ)

clean: 
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ZIP) $(BINARY_ZIP_OBJ) $(MAP)


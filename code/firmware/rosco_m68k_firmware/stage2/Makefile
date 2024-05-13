# Make rosco_m68k ROM stage2
# 
# Copyright (c)2020-2024 Ross Bamford
# See LICENSE

ifeq ($(MAKELEVEL),0)
$(error Cannot use stage2 as top-level Makefile)
endif

include ../common.mk

INCLUDES=-Ifat_io_lib -Iinclude -I../stage1/include
CFLAGS+=-O9
SIZE_CFLAGS=$(CFLAGS) -Os
LDFLAGS+=-T rosco_m68k_stage2.ld

# Output config
BINARY_BASENAME=loader2
BINARY_EXT=bin

BINARY=$(BINARY_BASENAME).$(BINARY_EXT)
MAP=$(BINARY_BASENAME).map
BINARY_ZIP=$(BINARY).zip
BINARY_ZIP_OBJ=$(BINARY_ZIP).o

ifeq ($(MAME),true)
DEFINES+=-DMAME_FIRMWARE
endif

LZG_SRC?=../tools/liblzg/src
LZG?=$(LZG_SRC)/tools/lzg

OBJECTS:=init2.o common.o serial.o main2.o

.PHONY: all clean

all: $(BINARY_ZIP_OBJ)

ifeq ($(WITH_ATA), true)
DEFINES+=-DROSCO_M68K_ATA
ifeq ($(ATA_DEBUG),true)
DEFINES+=-DATA_DEBUG
endif
endif
ifeq ($(WITH_KERMIT),true)
include kermit/include.mk
endif
ifeq ($(WITH_BLOCKDEV),true)
INCLUDES+=-I../stage1/blockdev/include
include load/include.mk
include part/include.mk
include sdfat/include.mk
ifeq ($(WITH_ATA), true)
include idehdd/include.mk
endif
endif
ifeq ($(REVISION1X),true)
DEFINES+=-DREVISION1X
endif

main2.o: main2.c
	$(CC) $(SIZE_CFLAGS) -c -o $@ $<

common.o: common.c
	$(CC) $(SIZE_CFLAGS) -c -o $@ $<

$(BINARY) : $(OBJECTS)
	$(LD) $(LDFLAGS) -Map=$(MAP) $^ -o $@ -R../stage1/stage1.elf $(LIBS)
	-chmod a-x $@

$(BINARY_ZIP): $(BINARY) $(LZG)
	$(LZG) -9 $< $@

$(BINARY_ZIP_OBJ): $(BINARY_ZIP)
	m68k-elf-objcopy -I binary -O elf32-m68k -B m68k --rename-section .data=.zipdata $< $@

clean: 
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ZIP) $(BINARY_ZIP_OBJ) $(MAP)

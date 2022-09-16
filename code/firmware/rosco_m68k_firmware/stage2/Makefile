# Make stage2 for rosco_m68k ROM images
# 
# Copyright (c)2020-2022 Ross Bamford and contributors
# See LICENSE

default: all

include ../config.mk

EXTRA_CFLAGS+=-Wno-unused-function -O9
INCLUDES+=-Iinclude -I../include
LDFLAGS+=-T rosco_m68k_stage2.ld -Map=$(MAP)

# Output file configuration
BINARY_BASENAME=loader2
BINARY_EXT=bin

MAP=$(BINARY_BASENAME).map
BINARY=$(BINARY_BASENAME).$(BINARY_EXT)
BINARY_ZIP=$(BINARY).zip
BINARY_ZIP_OBJ=$(BINARY_ZIP).o

LZG_SRC?=../tools/liblzg/src
LZG?=$(LZG_SRC)/tools/lzg

OBJECTS=init2.o common.o serial.o machine.o main2.o

# Configuration-based defines
ifeq ($(REVISION1X),true)
DEFINES+=-DREVISION1X
endif
ifeq ($(HUGEROM),true)
DEFINES+=-DHUGEROM
endif
ifeq ($(ATA_DEBUG),true)
DEFINES+=-DATA_DEBUG
endif
ifeq ($(WITH_MAME_LOADER),true)
DEFINES+=-DMAME_LOADER
endif

# Configuration-based subdirectory includes
ifeq ($(WITH_KERMIT_LOADER),true)
include kermit/include.mk
endif
ifeq ($(WITH_BLOCKDEV_LOADER),true)
include load/include.mk
include part/include.mk
include sdcard/include.mk
include idehdd/include.mk
endif

$(BINARY): $(OBJECTS)
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

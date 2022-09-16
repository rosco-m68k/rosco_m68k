# Common build variables for rosco_m68k ROM images
#
# Copyright (c)2019-2022 Ross Bamford and contributors
# See LICENSE

# Avoid a plain `make` without a target before `include config.mk`
decoy_config_mk:
	@echo A default target should exist before \"config.mk\" is included.

CPU?=68010
ARCH?=$(CPU)
TUNE?=$(CPU)
EXTRA_CFLAGS?=-g
DEFINES:=$(DEFINES)
INCLUDES:=$(INCLUDES)
CFLAGS=-mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE)						\
       -std=c11 -ffreestanding -nostartfiles -Os						\
       -Wall -Wpedantic -Werror															\
       -fomit-frame-pointer -fno-delete-null-pointer-checks	\
       $(INCLUDES) $(DEFINES)
LDFLAGS=
ASFLAGS=-Felf -m$(CPU) -quiet $(DEFINES)

# Tools
CC=m68k-elf-gcc
LD=m68k-elf-ld
AS=vasmm68k_mot
OBJCOPY=m68k-elf-objcopy
OBJDUMP=m68k-elf-objdump
SIZE=m68k-elf-size
NM=m68k-elf-nm
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

# System-specific default configuration options
ifeq ($(REVISION1X),true)
HUGEROM?=false
else
HUGEROM?=true
endif
ifeq ($(CPU),68000)
WITH_ATA?=false
WITH_VDP?=false
WITH_XOSERA?=false
ifeq ($(REVISION1X),true)
WITH_68681?=false
endif
endif

# Default configuration options
WITH_68681?=true
WITH_BLOCKDEV?=true
WITH_BBSD?=true
WITH_ATA?=true
WITH_VDP?=true
WITH_XOSERA?=true
WITH_KERMIT?=true
WITH_DEBUG_STUB?=true

# Configuration-based defines for stage1 and stage2
ifeq ($(REVISION1X),true)
DEFINES+=-DREVISION1X
endif
ifeq ($(ATA_DEBUG),true)
DEFINES+=-DATA_DEBUG
endif

# Configuration-based defines for stage1
ifeq ($(HUGEROM),true)
DEFINES+=-DHUGEROM
endif
ifeq ($(NO_TICK),true)
DEFINES+=-DNO_TICK
endif
ifneq ($(WITH_68681),true)
DEFINES+=-DNO_68681
endif

# Configuration-based defines for stage2
ifeq ($(MAME),true)
DEFINES+=-DMAME_FIRMWARE
endif

# Generic recipes

%.o: %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o: %.asm
	$(AS) $(ASFLAGS) -o $@ $<

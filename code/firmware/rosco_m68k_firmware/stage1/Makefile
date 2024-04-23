# Make rosco_m68k ROM images
# 
# Copyright (c)2019-2024 Ross Bamford
# See LICENSE

CPU?=68000
ARCH?=$(CPU)
TUNE?=$(CPU)
EXTRA_CFLAGS?=-g
DEFINES:=$(DEFINES) -DROSCO_M68K_KERNEL_BUILD
CFLAGS=-std=c11 -ffreestanding -nostartfiles -Wall -Wpedantic -Werror				\
       -Iinclude -Ikernel/include -mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE) -Os	\
       -fomit-frame-pointer -fno-delete-null-pointer-checks							\
       $(DEFINES)
LDFLAGS=-Map=$(MAP) -L ..
ASFLAGS=-Felf -m$(CPU) -quiet $(DEFINES) -align
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

# Output config
STAGE1_BASENAME=stage1
ELF_EXT=elf

STAGE1=$(STAGE1_BASENAME).$(ELF_EXT)
DISASM=$(STAGE1_BASENAME).dis
SYM=$(STAGE1_BASENAME).sym
MAP=$(STAGE1_BASENAME).map

OBJECTS=bootstrap.o mfp.o duart.o rev1.o rev2.o lzgmini_68k.o	\
				decompress.o ansicon.o char_device.o trap14.o	\
				cpuspeed.o cputype.o warmboot.o					\
				keyboard_efp.o keyboard.o common.o				\
				main1.o

# Big ROM configuration (enable everything) is now default
WITH_BLOCKDEV?=true
WITH_KERMIT?=true
WITH_DEBUG_STUB?=true
WITH_ATA?=true

.PHONY: all clean test

all: $(STAGE1) $(DISASM) $(SYM) $(MAP)

ifeq ($(REVISION1X),true)
$(info === Building rosco_m68k firmware for revision 1.x board with MC$(CPU) CPU)
DEFINES:=$(DEFINES) -DREVISION1X
else
$(info === Building rosco_m68k firmware for revision 2.x board with MC$(CPU) CPU)
endif

ifeq ($(NOBANNER),true)
$(info === Building rosco_m68k firmware with no serial banner output at startup)
DEFINES:=$(DEFINES) -DNO_BANNER
else
ifeq ($(LATEBANNER),true)
$(info === Building rosco_m68k firmware with late banner output at startup)
DEFINES:=$(DEFINES) -DLATE_BANNER
endif
endif

ifneq ($(NO_KERNEL),true)
$(info === Building rosco_m68k firmware with ROM kernel for revision 2.x board)
DEFINES:=$(DEFINES) -DWITH_KERNEL
endif

# Set up Size-specific things appropriately..
ifeq ($(REVISION1X),true)
HUGEROM?=false
ifeq ($(MAME),true)
$(info === Building rosco_m68k firmware for MAME (rosco))
LDFLAGS+=-T rosco_m68k_firmware_64k.ld
else
ifeq ($(HUGEROM),true)
$(info === Building rosco_m68k firmware for 1MB SST39SF040 (HUGEROM))
LDFLAGS+=-T rosco_m68k_firmware_1M.ld
DEFINES:=$(DEFINES) -DHUGEROM
else
$(info === Building rosco_m68k firmware for 64KB AT28C256 (BIGROM))
LDFLAGS+=-T rosco_m68k_firmware_64k.ld
endif
endif
else
HUGEROM?=true
ifeq ($(MAME),true)
$(info === Building rosco_m68k firmware for MAME (rosco_classicv2))
LDFLAGS+=-T rosco_m68k_firmware_1M.ld
DEFINES:=$(DEFINES) -DHUGEROM
else
ifeq ($(HUGEROM),false)
$(error === Invalid option combination: Cannot build AT28C256 ROMs for r2.x boards!)
else
$(info === Building rosco_m68k firmware for 1MB SST39SF040 (HUGEROM))
LDFLAGS+=-T rosco_m68k_firmware_1M.ld
DEFINES:=$(DEFINES) -DHUGEROM
endif
endif
endif

ifeq ($(NO68681),true)
$(info === Building rosco_m68k firmware NO_68681 without DUART)
DEFINES:=$(DEFINES) -DNO_68681
else
$(info === Building rosco_m68k firmware with 68681 DUART support)
endif

ifeq ($(NO_TICK),true)
$(info === Building rosco_m68k firmware with NO_TICK)
DEFINES:=$(DEFINES) -DNO_TICK
endif

ifneq ($(WITH_BLOCKDEV),false)
$(info === Building rosco_m68k firmware with block device support)
include blockdev/include.mk
ifeq ($(WITH_ATA),true)
$(info === Building rosco_m68k firmware with ATA support)
ifeq ($(ATA_DEBUG),true)
$(info === Building rosco_m68k firmware with ATA_DEBUG IDE)
DEFINES:=$(DEFINES) -DATA_DEBUG
endif
else
$(info === Building rosco_m68k firmware without ATA support)
endif
endif

ifneq ($(WITH_VDP),false)
$(info === Building rosco_m68k firmware with V9958 VDP)
include video9958/include.mk
endif

# only one Xosera console at a time
ifneq ($(XOSERA_API_MINIMAL),false)
$(info === Building rosco_m68k firmware with Xosera ANSI console)
include videoXoseraANSI/include.mk
endif

ifeq ($(WITH_DEBUG_STUB),true)
$(info === Building rosco_m68k firmware with DEBUG_STUB)
include debug_stub/include.mk
endif

include easy68k/include.mk

export WITH_ATA
export ATA_DEBUG
export WITH_BLOCKDEV
export WITH_KERMIT
export CPU ARCH TUNE
export REVISION1X
export MAME

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.asm
	$(AS) $(ASFLAGS) -o $@ $<

kernel/kernel.a:
	$(MAKE) -C kernel $(nodir $@)

$(STAGE1) : $(OBJECTS) kernel/kernel.a
	$(LD) $(LDFLAGS) $^ -r -o $@
	$(SIZE) $@

$(SYM) : $(STAGE1)
	$(NM) --numeric-sort $< >$@

$(DISASM) : $(STAGE1)
	$(OBJDUMP) --disassemble -S $< >$@

clean:
	$(MAKE) -C kernel clean
	$(RM) $(OBJECTS) $(STAGE1) $(DISASM) $(SYM) $(MAP) $(BINARY_BASENAME)_mame.$(BINARY_EXT).bin

test:
	$(MAKE) -C kernel test

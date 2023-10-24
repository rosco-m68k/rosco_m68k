# Make rosco_m68k ROM images
# 
# Copyright (c)2019-2022 Ross Bamford
# See LICENSE

CPU?=68010
ARCH?=$(CPU)
TUNE?=$(CPU)
EXTRA_CFLAGS?=-g
DEFINES:=$(DEFINES) -DROSCO_M68K_KERNEL_BUILD
CFLAGS=-std=c11 -ffreestanding -nostartfiles -Wall -Wpedantic -Werror				\
       -Iinclude -Ikernel/include -mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE) -Os	\
       -fomit-frame-pointer -fno-delete-null-pointer-checks							\
       $(DEFINES)
LDFLAGS=-Map=$(MAP)
ASFLAGS=-Felf -m$(CPU) -quiet $(DEFINES)
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
BINARY_BASENAME=rosco_m68k
BINARY_EXT=rom
ELF_EXT=elf

ELF=$(BINARY_BASENAME).$(ELF_EXT)
BINARY=$(BINARY_BASENAME).$(BINARY_EXT)
DISASM=$(BINARY_BASENAME).dis
SYM=$(BINARY_BASENAME).sym
MAP=$(BINARY_BASENAME).map
STAGE2_DIR=stage2
STAGE2_FILE=loader2.bin.zip.o
STAGE2=$(STAGE2_DIR)/$(STAGE2_FILE)
BINARY_EVEN=$(BINARY_BASENAME)_even.$(BINARY_EXT)
BINARY_ODD=$(BINARY_BASENAME)_odd.$(BINARY_EXT)

ROMDEVICE?=SST39SF040
OBJECTS=bootstrap.o mfp.o duart.o rev1.o rev2.o lzgmini_68k.o	\
				decompress.o ansicon.o serial.o trap14.o cpuspeed.o		\
				cputype.o warmboot.o main1.o 

# Big ROM configuration (enable everything) is now default
WITH_BLOCKDEV?=true
WITH_KERMIT?=true
WITH_DEBUG_STUB?=true

all: $(BINARY_EVEN) $(BINARY_ODD)

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
ifeq ($(MAME),true)
$(info === Building rosco_m68k firmware for MAME (rosco))
LDFLAGS:=-T ./rosco_m68k_firmware_64k.ld -Map=$(MAP)
MAMESIZE=0x00010000
else
ifeq ($(HUGEROM),true)
$(info === Building rosco_m68k firmware for 1MB SST39SF040 (HUGEROM))
LDFLAGS:=-T ./rosco_m68k_firmware_1M.ld -Map=$(MAP)
ROMDEVICE=SST39SF040
DEFINES:=$(DEFINES) -DHUGEROM
else
$(info === Building rosco_m68k firmware for 64KB AT28C256 (BIGROM))
LDFLAGS:=-T ./rosco_m68k_firmware_64k.ld -Map=$(MAP)
ROMDEVICE=AT28C256
endif
endif
else
ifeq ($(MAME),true)
$(info === Building rosco_m68k firmware for MAME (rosco_classicv2))
MAMESIZE=0x00100000
LDFLAGS:=-T ./rosco_m68k_firmware_1M.ld -Map=$(MAP)
DEFINES:=$(DEFINES) -DHUGEROM
else
ifeq ($(HUGEROM),false)
$(error === Invalid option combination: Cannot build AT28C256 ROMs for r2.x boards!)
else
$(info === Building rosco_m68k firmware for 1MB SST39SF040 (HUGEROM))
LDFLAGS:=-T ./rosco_m68k_firmware_1M.ld -Map=$(MAP)
ROMDEVICE=SST39SF040
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
ifeq ($(ATA_DEBUG),true)
$(info === Building rosco_m68k firmware with ATA_DEBUG IDE)
DEFINES:=$(DEFINES) -DATA_DEBUG
endif
endif

ifneq ($(WITH_VDP),false)
$(info === Building rosco_m68k firmware with V9958 VDP)
include video9958/include.mk
endif

# only one Xosera console at a time
ifneq ($(XOSERA_ANSI_CON),false)
$(info === Building rosco_m68k firmware with Xosera ANSI console)
include videoXoseraANSI/include.mk
endif

ifeq ($(WITH_DEBUG_STUB),true)
$(info === Building rosco_m68k firmware with DEBUG_STUB)
include debug_stub/include.mk
endif

include easy68k/include.mk

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

$(STAGE2) : $(STAGE2_DIR)
	CPU='$(CPU)' ARCH='$(ARCH)' TUNE='$(TUNE)' make -C $^ $(STAGE2_FILE)

$(ELF) : $(OBJECTS) $(STAGE2) kernel/kernel.a
	$(LD) $(LDFLAGS) $^ -o $@
	$(NM) --numeric-sort $@ >$(SYM)
	$(SIZE) $@
	-chmod a-x $@

$(BINARY) : $(ELF) $(DISASM) $(SYMS)
	$(OBJCOPY) -O binary $< $@
	-chmod a-x $@
ifeq ($(HUGEROM),false)
		@echo === Completed building rosco_m68k firmware for 64KB BIGROM AT28C256: $@
else
		@echo === Completed building rosco_m68k firmware for 1MB HUGEROM SST39SF040: $@
endif

$(DISASM) : $(ELF)
	$(OBJDUMP) --disassemble -S $(ELF) >$(DISASM)

$(BINARY_EVEN): $(BINARY)
	srec_cat -output $(BINARY_EVEN) -Binary $(BINARY) -Binary -Split 2 0

$(BINARY_ODD): $(BINARY)
	srec_cat -output $(BINARY_ODD) -Binary $(BINARY) -Binary -Split 2 1

.PHONY: all clean dump tools test

clean:
	$(MAKE) -C $(STAGE2_DIR) clean
	$(MAKE) -C kernel clean
	$(MAKE) -C tools/liblzg/src clean
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) $(MAP) $(BINARY_BASENAME)_mame.$(BINARY_EXT).bin

test:
	$(MAKE) -C kernel test
	
burn: $(BINARY_EVEN) $(BINARY_ODD)
	ROMDEVICE=$(ROMDEVICE) ./burn.sh

tools: 
	$(MAKE) -C tools/liblzg/src

ifeq ($(MAME),true)
mame: $(BINARY)
	srec_cat -output $(BINARY_BASENAME)_mame.$(BINARY_EXT).bin -Binary $(BINARY) -Binary -fill 0xFF 0x00000000 $(MAMESIZE)
endif


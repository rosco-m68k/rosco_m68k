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
       -fomit-frame-pointer -fno-delete-null-pointer-checks $(EXTRA_CFLAGS)			\
       $(DEFINES)
LDFLAGS=-Map=$(MAP) -L . -T $(LINKER_SCRIPT)
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

STAGE1_DIR=stage1
STAGE1_FILE=stage1.elf
STAGE1=$(STAGE1_DIR)/$(STAGE1_FILE)
STAGE2_DIR=stage2
STAGE2_FILE=loader2.bin.zip.o
STAGE2=$(STAGE2_DIR)/$(STAGE2_FILE)

# Output config
BINARY_BASENAME=rosco_m68k
BINARY_EXT=rom
ELF_EXT=elf

ELF=$(BINARY_BASENAME).$(ELF_EXT)
BINARY=$(BINARY_BASENAME).$(BINARY_EXT)
DISASM=$(BINARY_BASENAME).dis
SYM=$(BINARY_BASENAME).sym
MAP=$(BINARY_BASENAME).map
BINARY_EVEN=$(BINARY_BASENAME)_even.$(BINARY_EXT)
BINARY_ODD=$(BINARY_BASENAME)_odd.$(BINARY_EXT)

ROMDEVICE?=SST39SF040

# Big ROM configuration (enable everything) is now default
WITH_BLOCKDEV?=true
WITH_KERMIT?=true
WITH_DEBUG_STUB?=true
WITH_ATA?=true

.PHONY: all clean tools test

all: $(BINARY_EVEN) $(BINARY_ODD) $(SYM) $(DISASM)

# Set up Size-specific things appropriately..
ifeq ($(REVISION1X),true)
HUGEROM?=false
ifeq ($(MAME),true)
$(info === Building rosco_m68k firmware for MAME (rosco))
LINKER_SCRIPT=rosco_m68k_firmware_64k.ld
MAMESIZE=0x00010000
else
ifeq ($(HUGEROM),true)
$(info === Building rosco_m68k firmware for 1MB SST39SF040 (HUGEROM))
LINKER_SCRIPT=rosco_m68k_firmware_1M.ld
ROMDEVICE=SST39SF040
DEFINES:=$(DEFINES) -DHUGEROM
else
$(info === Building rosco_m68k firmware for 64KB AT28C256 (BIGROM))
LINKER_SCRIPT=rosco_m68k_firmware_64k.ld
ROMDEVICE=AT28C256
endif
endif
else
HUGEROM?=true
ifeq ($(MAME),true)
$(info === Building rosco_m68k firmware for MAME (rosco_classicv2))
MAMESIZE=0x00100000
LINKER_SCRIPT=rosco_m68k_firmware_1M.ld
DEFINES:=$(DEFINES) -DHUGEROM
else
ifeq ($(HUGEROM),false)
$(error === Invalid option combination: Cannot build AT28C256 ROMs for r2.x boards!)
else
$(info === Building rosco_m68k firmware for 1MB SST39SF040 (HUGEROM))
LINKER_SCRIPT=rosco_m68k_firmware_1M.ld
ROMDEVICE=SST39SF040
DEFINES:=$(DEFINES) -DHUGEROM
endif
endif
endif

export LINKER_SCRIPT
export NO68681
export NO_TICK
export WITH_BLOCKDEV
export WITH_ATA
export ATA_DEBUG
export WITH_VDP
export XOSERA_API_MINIMAL
export WITH_DEBUG_STUB
export WITH_KERMIT
export CPU ARCH TUNE
export REVISION1X
export HUGEROM
export MAME
export NOBANNER
export LATEBANNER

$(STAGE1) : $(STAGE1_DIR)
	make -C $< $(STAGE1_FILE)

$(STAGE2) : $(STAGE2_DIR) $(STAGE1) tools
	make -C $< $(STAGE2_FILE)

$(ELF) : $(STAGE1) $(STAGE2)
	$(LD) $(LDFLAGS) $^ -o $@
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

$(SYM) : $(ELF)
	$(NM) --numeric-sort $< >$@

$(DISASM) : $(ELF)
	$(OBJDUMP) --disassemble -S $< >$@

$(BINARY_EVEN): $(BINARY)
	srec_cat -output $(BINARY_EVEN) -Binary $(BINARY) -Binary -Split 2 0

$(BINARY_ODD): $(BINARY)
	srec_cat -output $(BINARY_ODD) -Binary $(BINARY) -Binary -Split 2 1

clean:
	$(MAKE) -C $(STAGE1_DIR) clean
	$(MAKE) -C $(STAGE2_DIR) clean
	$(MAKE) -C tools/liblzg/src clean
	$(RM) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) $(ELF) $(DISASM) $(SYM) $(MAP) $(BINARY_BASENAME)_mame.$(BINARY_EXT).bin

test:
	$(MAKE) -C $(STAGE1_DIR) test
	
burn: $(BINARY_EVEN) $(BINARY_ODD)
	ROMDEVICE=$(ROMDEVICE) ./burn.sh

tools: 
	$(MAKE) -C tools/liblzg/src

ifeq ($(MAME),true)
mame: $(BINARY)
	srec_cat -output $(BINARY_BASENAME)_mame.$(BINARY_EXT).bin -Binary $(BINARY) -Binary -fill 0xFF 0x00000000 $(MAMESIZE)
endif


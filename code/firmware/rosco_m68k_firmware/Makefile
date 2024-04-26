# Make rosco_m68k ROM images
# 
# Copyright (c)2019-2024 Ross Bamford
# See LICENSE

# Configuration options, default to rev. 2 with MC68000, with all features except VDP
# CPU options
export CPU?=68000
export ARCH?=$(CPU)
export TUNE?=$(CPU)
# Board version
export REVISION1X?=false
ifeq ($(REVISION1X),true)
export HUGEROM?=false
else
export HUGEROM?=true
endif
export MAME?=false
# Firmware features
export WITH_BLOCKDEV?=true
export WITH_KERMIT?=true
export WITH_DEBUG_STUB?=true
export WITH_ATA?=true
export WITH_VDP?=false
export NO68681?=false
export XOSERA_API_MINIMAL?=true
# Firmware behaviour
export NOBANNER?=false
export LATEBANNER?=false
export ATA_DEBUG?=false
export NO_TICK?=false

# Only rev. 1 can use BIGROM 
ifneq ($(REVISION1X),true)
ifeq ($(HUGEROM),false)
$(error === Invalid option combination: Cannot build AT28C256 ROMs for r2.x boards)
endif
endif

# Generic ROM-type options
ifeq ($(HUGEROM),false)
export LINKER_SCRIPT=rosco_m68k_firmware_64k.ld
ROM_TYPE_NAME=BIGROM
else
DEFINES:=$(DEFINES) -DHUGEROM
export LINKER_SCRIPT=rosco_m68k_firmware_1M.ld
ROM_TYPE_NAME=HUGEROM
endif

# Hardware vs. MAME ROM-type options
ifeq ($(MAME),true)
# Is built for MAME
ifeq ($(REVISION1X),true)
MAME_NAME=rosco
MAMESIZE=0x00010000
else
MAME_NAME=rosco_classicv2
MAMESIZE=0x00100000
endif
$(info === Building rosco_m68k firmware for MAME ($(MAME_NAME)))
else
# Is built for real hardware
ifeq ($(HUGEROM),false)
ROMDEVICE?=AT28C256
else
ROMDEVICE?=SST39SF040
endif
# Lookup ROM size
ifeq ($(ROMDEVICE),AT28C256)
ROM_CHIP_SIZE=0x00008000
BOARD_ROM_SIZE=64KB
else ifeq ($(ROMDEVICE),SST39SF010A)
ROM_CHIP_SIZE=0x00020000
BOARD_ROM_SIZE=256KB
else ifeq ($(ROMDEVICE),SST39SF020A)
ROM_CHIP_SIZE=0x00040000
BOARD_ROM_SIZE=512KB
else ifeq ($(ROMDEVICE),SST39SF040)
ROM_CHIP_SIZE=0x00080000
BOARD_ROM_SIZE=1MB
else
ifeq ($(ROM_CHIP_SIZE),)
$(error === Unknown ROMDEVICE has been set without ROM_CHIP_SIZE)
endif
BOARD_ROM_SIZE?=$(ROM_CHIP_SIZE)*2B
endif
$(info === Building rosco_m68k firmware for $(BOARD_ROM_SIZE) $(ROMDEVICE) ($(ROM_TYPE_NAME)))
endif

# These are used in CFLAGS by common.mk
export DEFINES:=-DROSCO_M68K_KERNEL_BUILD
export INCLUDES:=
export EXTRA_CFLAGS?:=

include ./common.mk

LDFLAGS+=-L . -T $(LINKER_SCRIPT)

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
BINARY_MAME=$(BINARY_BASENAME)_mame.$(BINARY_EXT).bin

.PHONY: all clean tools test

ifneq ($(MAME),true)
all: $(BINARY_EVEN) $(BINARY_ODD) $(SYM) $(DISASM)
else
all: $(BINARY_MAME) $(SYM) $(DISASM)
endif

$(STAGE1) : $(STAGE1_DIR)
	make -C $< $(STAGE1_FILE)

$(STAGE2) : $(STAGE2_DIR) $(STAGE1) tools
	make -C $< $(STAGE2_FILE)

$(ELF) : $(STAGE1) $(STAGE2)
	$(LD) $(LDFLAGS) -Map=$(MAP) $^ -o $@
	$(SIZE) $@
	-chmod a-x $@

$(BINARY) : $(ELF) $(DISASM) $(SYMS)
	$(OBJCOPY) -O binary $< $@
	-chmod a-x $@
ifneq ($(MAME),true)
	@echo === Completed building rosco_m68k firmware for $(BOARD_ROM_SIZE) $(ROMDEVICE) \($(ROM_TYPE_NAME)\): $@
else
	@echo === Completed building rosco_m68k firmware for MAME \($(MAME_NAME)\): $@
endif

$(BINARY_MAME): $(BINARY)
ifeq ($(MAME),true)
	srec_cat -output $@ -Binary $< -Binary -fill 0xFF 0x00000000 $(MAMESIZE)
else
	$(error === Cannot generate MAME ROM for real hardware)
endif

$(BINARY_EVEN): $(BINARY)
ifneq ($(MAME),true)
	srec_cat -output $@ -Binary $< -Binary -Split 2 0 -fill 0xFF 0x00000000 $(ROM_CHIP_SIZE)
else
	$(error === Cannot generate split ROM for MAME)
endif

$(BINARY_ODD): $(BINARY)
ifneq ($(MAME),true)
	srec_cat -output $@ -Binary $< -Binary -Split 2 1 -fill 0xFF 0x00000000 $(ROM_CHIP_SIZE)
else
	$(error === Cannot generate split ROM for MAME)
endif

clean:
	$(MAKE) -C $(STAGE1_DIR) clean
	$(MAKE) -C $(STAGE2_DIR) clean
	$(MAKE) -C tools/liblzg/src clean
	$(RM) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) $(BINARY_MAME) $(ELF) $(DISASM) $(SYM) $(MAP)

test:
	$(MAKE) -C $(STAGE1_DIR) test
	
burn: $(BINARY_EVEN) $(BINARY_ODD)
ifeq ($(MAME),true)
	$(error === Cannot burn ROM when building for MAME)
endif
	ROMDEVICE=$(ROMDEVICE) ./burn.sh

tools: 
	$(MAKE) -C tools/liblzg/src

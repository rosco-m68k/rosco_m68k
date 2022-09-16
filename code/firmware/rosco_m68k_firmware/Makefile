# Make rosco_m68k ROM images
#
# Copyright (c)2019-2022 Ross Bamford and contributors
# See LICENSE

default: all

include config.mk

INCLUDES+=-Iinclude
LDFLAGS+=-Map=$(MAP)

# Output file configuration
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
MAME_BINARY=$(BINARY_BASENAME)_mame.$(BINARY_EXT).bin

OBJECTS=bootstrap.o mfp.o duart.o rev1.o rev2.o lzgmini_68k.o	\
        decompress.o ansicon.o serial.o trap14.o cpuspeed.o		\
        cputype.o warmboot.o main1.o

ifeq ($(REVISION1X),true)
$(info === Building rosco_m68k firmware for revision 1.x board with MC$(CPU) CPU)
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

# When MAME is true, override HUGEROM and set relevant variables
ifeq ($(MAME),true)
ifeq ($(REVISION1X),true)
MAMESIZE=0x00010000
HUGEROM=
MAMENAME=rosco
else
MAMESIZE=0x00100000
HUGEROM=true
MAMENAME=rosco_classicv2
endif
endif

# Select linker script and set relevant variables according to ROM type
ifeq ($(HUGEROM),true)
LDFLAGS+=-T ./rosco_m68k_firmware_1M.ld
ROMDEVICE?=SST39SF040
ROMSIZETEXT=1MB
ROMSIZENAME=HUGEROM
else
ifneq ($(REVISION1X),true)
$(error === Invalid option combination: Cannot build non-HUGEROM for r2.x boards!)
endif
LDFLAGS+=-T ./rosco_m68k_firmware_64k.ld
ROMDEVICE?=AT28C256
ROMSIZETEXT=64KB
ROMSIZENAME=BIGROM
endif

ifeq ($(MAME),true)
FIRMWARE_TARGET=MAME ($(MAMENAME))
else
FIRMWARE_TARGET=$(ROMSIZETEXT) $(ROMDEVICE) ($(ROMSIZENAME))
endif

$(info === Building rosco_m68k firmware for $(FIRMWARE_TARGET))

ifneq ($(WITH_68681),true)
$(info === Building rosco_m68k firmware without 68681 DUART support)
else
$(info === Building rosco_m68k firmware with 68681 DUART support)
endif

ifeq ($(NO_TICK),true)
$(info === Building rosco_m68k firmware with NO_TICK)
endif

ifeq ($(WITH_BLOCKDEV),true)
$(info === Building rosco_m68k firmware with block device support)
include blockdev/include.mk
ifeq ($(ATA_DEBUG),true)
$(info === Building rosco_m68k firmware with ATA_DEBUG IDE)
endif
endif

ifeq ($(WITH_VDP),true)
$(info === Building rosco_m68k firmware with V9958 VDP)
include video9958/include.mk
endif

ifeq ($(WITH_XOSERA),true)
$(info === Building rosco_m68k firmware with Xosera ANSI console)
include videoXoseraANSI/include.mk
endif

ifeq ($(WITH_DEBUG_STUB),true)
$(info === Building rosco_m68k firmware with DEBUG_STUB)
include debug_stub/include.mk
endif

include easy68k/include.mk

# Hardware configuration options
export CPU ARCH TUNE
export REVISION1X

# Software configuration options
export WITH_KERMIT
export WITH_BLOCKDEV

# Special software configuration options
export ATA_DEBUG
export MAME

# Recipes

$(STAGE2): $(STAGE2_DIR)
	make -C $^ $(STAGE2_FILE)

$(ELF): $(OBJECTS) $(STAGE2)
	$(LD) $(LDFLAGS) $^ -o $@
	$(NM) --numeric-sort $@ >$(SYM)
	$(SIZE) $@
	-chmod a-x $@

$(BINARY): $(ELF) $(DISASM) $(SYMS)
	$(OBJCOPY) -O binary $< $@
	-chmod a-x $@
	@echo === Completed building rosco_m68k firmware for "$(FIRMWARE_TARGET)": $@

$(DISASM): $(ELF)
	$(OBJDUMP) --disassemble -S $(ELF) >$(DISASM)

ifeq ($(MAME),true)
$(MAME_BINARY): $(BINARY)
	srec_cat -output $(MAME_BINARY) -Binary $(BINARY) -Binary -fill 0xFF 0x00000000 $(MAMESIZE)
else
$(BINARY_EVEN): $(BINARY)
	srec_cat -output $(BINARY_EVEN) -Binary $(BINARY) -Binary -Split 2 0
$(BINARY_ODD): $(BINARY)
	srec_cat -output $(BINARY_ODD) -Binary $(BINARY) -Binary -Split 2 1
endif

.PHONY: all clean burn tools

ifeq ($(MAME),true)
all: $(MAME_BINARY)
else
all: $(BINARY_EVEN) $(BINARY_ODD)
endif

clean:
	make -C $(STAGE2_DIR) clean	
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) $(MAP) $(MAME_BINARY)

burn: $(BINARY_EVEN) $(BINARY_ODD)
	ROMDEVICE=$(ROMDEVICE) ./burn.sh

tools: 
	make -C tools/liblzg/src

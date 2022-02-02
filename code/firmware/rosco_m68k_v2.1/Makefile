# Make rosco_m68k ROM images
# 
# Copyright (c)2019-2022 Ross Bamford
# See LICENSE

CPU?=68010
ARCH?=$(CPU)
TUNE?=$(CPU)
EXTRA_CFLAGS?=-g
DEFINES:=$(DEFINES)
CFLAGS=-std=c11 -ffreestanding -nostartfiles -Wall -Wpedantic -Werror	\
       -Iinclude -mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE) -Os				\
       -fomit-frame-pointer -fno-delete-null-pointer-checks						\
			 -mno-align-int -mno-strict-align $(DEFINES)
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

# Set up Size-specific things appropriately..
ifeq ($(REVISION1X),true)
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


%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.asm
	$(AS) $(ASFLAGS) -o $@ $<

$(STAGE2) : $(STAGE2_DIR)
	CPU='$(CPU)' ARCH='$(ARCH)' TUNE='$(TUNE)' make -C $^ $(STAGE2_FILE)

$(ELF) : $(OBJECTS) $(STAGE2)
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

.PHONY: all clean dump tools


clean:
	make -C $(STAGE2_DIR) clean	
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) $(MAP) $(BINARY_BASENAME)_mame.$(BINARY_EXT).bin

burn: $(BINARY_EVEN) $(BINARY_ODD)
	ROMDEVICE=$(ROMDEVICE) ./burn.sh

tools: 
	make -C tools/liblzg/src

mame: $(BINARY)
	srec_cat -output $(BINARY_BASENAME)_mame.$(BINARY_EXT).bin -Binary $(BINARY) -Binary -fill 0xFF 0x00000000 0x00010000


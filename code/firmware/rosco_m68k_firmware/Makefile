# Make rosco_m68k ROM images
#
# Copyright (c)2019-2022 Ross Bamford and contributors
# See LICENSE

include config.mk

INCLUDES+=$(INCLUDES) -Iinclude
LDFLAGS+=-Map=$(MAP)

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

all: $(BINARY_EVEN) $(BINARY_ODD)

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

# Set up Size-specific things appropriately...
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
else
ifneq ($(HUGEROM),true)
$(error === Invalid option combination: Cannot build AT28C256 ROMs for r2.x boards!)
else
$(info === Building rosco_m68k firmware for 1MB SST39SF040 (HUGEROM))
LDFLAGS:=-T ./rosco_m68k_firmware_1M.ld -Map=$(MAP)
ROMDEVICE=SST39SF040
endif
endif
endif

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

export CPU ARCH TUNE
export REVISION1X
export WITH_KERMIT
export WITH_BLOCKDEV
export MAME
export ATA_DEBUG

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
ifeq ($(HUGEROM),true)
		@echo === Completed building rosco_m68k firmware for 1MB HUGEROM SST39SF040: $@
else
		@echo === Completed building rosco_m68k firmware for 64KB BIGROM AT28C256: $@
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

ifeq ($(MAME),true)
mame: $(BINARY)
	srec_cat -output $(BINARY_BASENAME)_mame.$(BINARY_EXT).bin -Binary $(BINARY) -Binary -fill 0xFF 0x00000000 $(MAMESIZE)
endif


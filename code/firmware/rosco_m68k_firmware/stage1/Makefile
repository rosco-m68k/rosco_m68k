# Make rosco_m68k ROM stage1
# 
# Copyright (c)2019-2024 Ross Bamford
# See LICENSE

ifeq ($(MAKELEVEL),0)
$(error Cannot use stage1 as top-level Makefile)
endif

include ../common.mk

EXTRA_CFLAGS?=-g
INCLUDES=-Iinclude -Ikernel/include
LDFLAGS+=-L .. -T $(LINKER_SCRIPT)

# Output config
STAGE1_BASENAME=stage1
ELF_EXT=elf

STAGE1=$(STAGE1_BASENAME).$(ELF_EXT)
DISASM=$(STAGE1_BASENAME).dis
SYM=$(STAGE1_BASENAME).sym
MAP=$(STAGE1_BASENAME).map

OBJECTS:=													\
	bootstrap.o mfp.o duart.o rev1.o rev2.o lzgmini_68k.o	\
	decompress.o ansicon.o char_device.o trap14.o			\
	cpuspeed.o cputype.o warmboot.o							\
	keyboard_efp.o keyboard.o common.o						\
	main1.o

ifeq ($(REVISION1X),true)
$(info === Building rosco_m68k firmware for revision 1.x board with MC$(CPU) CPU)
DEFINES+=-DREVISION1X
else
$(info === Building rosco_m68k firmware for revision 2.x board with MC$(CPU) CPU)
endif

ifeq ($(NOBANNER),true)
$(info === Building rosco_m68k firmware with no serial banner output at startup)
DEFINES+=-DNO_BANNER
else
ifeq ($(LATEBANNER),true)
$(info === Building rosco_m68k firmware with late banner output at startup)
DEFINES+=-DLATE_BANNER
endif
endif

ifneq ($(NO_KERNEL),true)
$(info === Building rosco_m68k firmware with ROM kernel for revision 2.x board)
DEFINES+=-DWITH_KERNEL
endif

ifeq ($(NO68681),true)
$(info === Building rosco_m68k firmware NO_68681 without DUART)
DEFINES+=-DNO_68681
else
$(info === Building rosco_m68k firmware with 68681 DUART support)
endif

ifeq ($(NO_TICK),true)
$(info === Building rosco_m68k firmware with NO_TICK)
DEFINES+=-DNO_TICK
endif

ifneq ($(WITH_BLOCKDEV),false)
$(info === Building rosco_m68k firmware with block device support)
include blockdev/include.mk
ifeq ($(WITH_ATA),true)
$(info === Building rosco_m68k firmware with ATA support)
ifeq ($(ATA_DEBUG),true)
$(info === Building rosco_m68k firmware with ATA_DEBUG IDE)
DEFINES+=-DATA_DEBUG
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

.PHONY: all clean test

all: $(STAGE1) $(DISASM) $(SYM) $(MAP)

include easy68k/include.mk

kernel/kernel.a:
	$(MAKE) -C kernel $(nodir $@)

$(STAGE1) : $(OBJECTS) kernel/kernel.a
	$(LD) $(LDFLAGS) -Map=$(MAP) $^ -r -o $@
	$(SIZE) $@

$(DISASM) : $(STAGE1)
	$(OBJDUMP) --disassemble -S $< >$@

clean:
	$(MAKE) -C kernel clean
	$(RM) $(OBJECTS) $(STAGE1) $(DISASM) $(SYM) $(MAP) $(BINARY_BASENAME)_mame.$(BINARY_EXT).bin

test:
	$(MAKE) -C kernel test

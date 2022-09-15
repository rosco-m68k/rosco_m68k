# Make updateflash program to update rosco_m68k firmware
#
# Copyright (c) 2020-2022 Ross Bamford and contributors
# See LICENSE

ROSCO_M68K_DEFAULT_DIR=../../..

ifndef ROSCO_M68K_DIR
$(info NOTE: ROSCO_M68K_DIR not set, using libs: $(ROSCO_M68K_DEFAULT_DIR)/code/software/libs)
ROSCO_M68K_DIR=$(ROSCO_M68K_DEFAULT_DIR)
else
$(info NOTE: Using ROSCO_M68K_DIR libs in: $(ROSCO_M68K_DIR))
endif

-include $(ROSCO_M68K_DIR)/code/software/software.mk

EXTRA_LIBS=-lsdfat -lsst_flash

ROM_OBJ=rosco_rom.o
ifneq ($(ROM_BIN),)
$(info NOTE: Embedding ROM firmware image in $(ELF) binary: $(ROM_BIN))
DEFINES+=-DFIRMWARE_EMBEDDED
OBJECTS+=$(ROM_OBJ)
endif
TO_CLEAN+=rosco_rom.bin $(ROM_OBJ)

$(ROM_OBJ): $(ROM_BIN)
	$(CP) $(ROM_BIN) rosco_rom.bin
	$(OBJCOPY) -I binary -O elf32-m68k -B m68k:68000 rosco_rom.bin $@

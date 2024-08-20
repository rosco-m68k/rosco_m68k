# Make rosco_m68k ROM stage2
# 
# Copyright (c)2020-2024 Ross Bamford
# See LICENSE

ifeq ($(MAKELEVEL),0)
$(error Cannot use stage2 as top-level Makefile)
endif

include ../common.mk

CC=m68k-elf-rosco-gcc
LD=m68k-elf-rosco-gcc

CFLAGS=																	\
	-std=c11 -g -nostartfiles --param=min-pagesize=0					\
	-Wall -Werror -Wpedantic -Wno-unused-function -Wno-unused-parameter	\
	-mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE)							\
	-fno-delete-null-pointer-checks										\
	$(DEFINES) $(INCLUDES)

INCLUDES=-Ifat_io_lib -Iinclude -I../stage1/include
CFLAGS+=-O9
SIZE_CFLAGS=$(CFLAGS) -Os
LDFLAGS+=-T rosco_m68k_stage2.ld -Wl,--warn-common

# Output config
BINARY_BASENAME=loader2
BINARY_ELF_EXT=elf
BINARY_BIN_EXT=bin

ELF=$(BINARY_BASENAME).$(BINARY_ELF_EXT)
BINARY=$(BINARY_BASENAME).$(BINARY_BIN_EXT)
MAP=$(BINARY_BASENAME).map
BINARY_ZIP=$(BINARY).zip
BINARY_ZIP_OBJ=$(BINARY_ZIP).o

ifeq ($(MAME),true)
DEFINES+=-DMAME_FIRMWARE
endif

LZG_SRC?=../tools/liblzg/src
LZG?=$(LZG_SRC)/tools/lzg

OBJECTS:=init2.o serial.o main2.o

.PHONY: all clean

all: $(BINARY_ZIP_OBJ)

ifeq ($(WITH_ATA), true)
DEFINES+=-DROSCO_M68K_ATA
ifeq ($(ATA_DEBUG),true)
DEFINES+=-DATA_DEBUG
endif
endif
ifeq ($(WITH_KERMIT),true)
include kermit/include.mk
endif
ifeq ($(WITH_BLOCKDEV),true)
INCLUDES+=-I../stage1/blockdev/include
include load/include.mk
include sdfat/include.mk
ifeq ($(WITH_ATA), true)
include idehdd/include.mk
endif
ifeq ($(HUGEROM), true)
ifeq ($(ROMFS_SIZE), 360)
DEFINES+=-DROMFS_BLOCKS=45
include romfs/include.mk
else ifeq ($(ROMFS_SIZE), 720)
DEFINES+=-DROMFS_BLOCKS=90
include romfs/include.mk
endif
endif
endif
ifeq ($(REVISION1X),true)
DEFINES+=-DREVISION1X
endif
ifneq ($(XOSERA_API_MINIMAL),false)
DEFINES+=-DXOSERA_API_MINIMAL
INCLUDES+=-I../stage1/videoXoseraANSI -I../stage1/splash/include
ifeq ($(HUGEROM),true)
ifeq ($(BOARD_ROM_SIZE),256KB)
DEFINES+=-DWITH_SPLASH
else
INCLUDES+=-Iboot_menu
LIBS+=boot_menu/libboot_menu.a
DEFINES+=-DWITH_BOOT_MENU -DWITH_ROMFS -DWITH_SPLASH
endif
endif
endif

main2.o: main2.c
	$(CC) $(SIZE_CFLAGS) -c -o $@ $<

common.o: common.c
	$(CC) $(SIZE_CFLAGS) -c -o $@ $<

$(ELF) : $(OBJECTS) $(LIBS)
	$(LD) $(LDFLAGS) -Wl,-Map=$(MAP) $^ -o $@ -Wl,-R../stage1/stage1.elf -nostartfiles $(LIBS)
	-chmod a-x $@

$(BINARY) : $(ELF)
	$(OBJCOPY) -O binary $< $@

$(BINARY_ZIP): $(BINARY) $(LZG)
	$(LZG) -9 $< $@

$(BINARY_ZIP_OBJ): $(BINARY_ZIP)
	m68k-elf-objcopy -I binary -O elf32-m68k -B m68k --rename-section .data=.zipdata $< $@

ifneq ($(XOSERA_API_MINIMAL),false)
boot_menu/libboot_menu.a:
	$(MAKE) -C boot_menu tests libboot_menu.a

clean_boot_menu:
	$(MAKE) -C boot_menu clean
clean: clean_boot_menu
else
clean: 
endif
	$(RM) $(OBJECTS) $(ELF) $(BINARY) $(BINARY_ZIP) $(BINARY_ZIP_OBJ) $(MAP)

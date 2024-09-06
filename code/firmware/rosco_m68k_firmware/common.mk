# Common variables and rules for rosco_m68k firmware
# 
# Copyright (c)2019-2024 Ross Bamford and contributors
# See LICENSE

CC=m68k-elf-rosco-gcc
LD=m68k-elf-rosco-ld
VASM=vasmm68k_mot
GNU_AS=m68k-elf-rosco-as
AS=$(VASM)
AR=m68k-elf-rosco-ar
RANLIB=m68k-elf-rosco-ranlib
OBJCOPY=m68k-elf-rosco-objcopy
OBJDUMP=m68k-elf-rosco-objdump
SIZE=m68k-elf-rosco-size
NM=m68k-elf-rosco-nm
RM=rm -f

CFLAGS=																	\
	-std=c11 -Os -ffreestanding -nostartfiles							\
	-Wall -Werror -Wpedantic -Wno-unused-function -Wno-unused-parameter	\
	-mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE)							\
	-fomit-frame-pointer -fno-delete-null-pointer-checks				\
	$(DEFINES) $(INCLUDES)
LDFLAGS=
VASMFLAGS=-Felf -m$(CPU) -quiet $(DEFINES) -align
GNU_ASFLAGS=-mcpu=$(CPU) -march=$(CPU)
ASFLAGS=$(VASMFLAGS)

# GCC-version-specific settings
ifneq ($(findstring GCC,$(shell $(CC) --version 2>/dev/null)),)
CC_VERSION:=$(shell $(CC) -dumpfullversion)
CC_MAJOR:=$(firstword $(subst ., ,$(CC_VERSION)))
# If this is GCC 12, 13, or 14, add flag --param=min-pagesize=0 to CFLAGS
ifeq ($(CC_MAJOR),12)
CFLAGS+=--param=min-pagesize=0
endif
ifeq ($(CC_MAJOR),13)
CFLAGS+=--param=min-pagesize=0
endif
ifeq ($(CC_MAJOR),14)
CFLAGS+=--param=min-pagesize=0
endif
endif

%.o : %.c
	$(CC) $(CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

%.o : %.asm
	$(AS) $(ASFLAGS) $(EXTRA_ASFLAGS) -o $@ $<

%.o : %.s
	$(AS) $(ASFLAGS) $(EXTRA_ASFLAGS) -o $@ $<

%.sym : %.elf
	$(NM) --numeric-sort $< >$@

%.dis : %.elf
	$(OBJDUMP) --disassemble -S $< >$@

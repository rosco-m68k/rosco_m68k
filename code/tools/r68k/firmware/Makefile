# Make rosco_m68k ROM images
# 
# Copyright (c)2019-2022 Ross Bamford
# See LICENSE

CPU?=68010
ARCH?=$(CPU)
TUNE?=$(CPU)
EXTRA_CFLAGS?=-g
DEFINES:=$(DEFINES) -DNO_BANNER
CFLAGS=-std=c11 -ffreestanding -nostartfiles -Wall -Wpedantic -Werror		\
       -Iinclude -mcpu=$(CPU) -march=$(ARCH) -mtune=$(TUNE) -Os				\
       -fomit-frame-pointer -fno-delete-null-pointer-checks					\
       $(DEFINES)
LDFLAGS=-T ./rosco_m68k_translator.ld -Map=$(MAP)
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

OBJECTS=bootstrap.o cputype.o trap13.o trap14.o trap15.o

.PHONY: all clean

all: $(BINARY)

include debug_stub/include.mk

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.asm
	$(AS) $(ASFLAGS) -o $@ $<

$(ELF) : $(OBJECTS) $(STAGE2)
	$(LD) $(LDFLAGS) $^ -o $@
	$(NM) --numeric-sort $@ >$(SYM)
	$(SIZE) $@
	-chmod a-x $@

$(BINARY) : $(ELF) $(DISASM) $(SYMS)
	$(OBJCOPY) -O binary $< $@
	-chmod a-x $@

$(DISASM) : $(ELF)
	$(OBJDUMP) --disassemble -S $(ELF) >$(DISASM)

clean:
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) $(MAP) $(BINARY_BASENAME)_mame.$(BINARY_EXT).bin



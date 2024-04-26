CC=m68k-elf-gcc
LD=m68k-elf-ld
AS=vasmm68k_mot
OBJCOPY=m68k-elf-objcopy
OBJDUMP=m68k-elf-objdump
SIZE=m68k-elf-size
NM=m68k-elf-nm
RM=rm -f

CFLAGS=																					\
	-std=c11 -Os -ffreestanding -nostartfiles											\
	-Wall -Werror -Wpedantic -Wno-unused-function -Wno-unused-parameter					\
	$(if $(CPU),-mcpu=$(CPU)) $(if $(ARCH),-march=$(ARCH)) $(if $(TUNE),-mtune=$(TUNE))	\
	-fomit-frame-pointer -fno-delete-null-pointer-checks								\
	$(DEFINES) $(INCLUDES) $(EXTRA_CFLAGS)
LDFLAGS=
ASFLAGS=-Felf -m$(CPU) -quiet $(DEFINES) -align

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

%.o : %.asm
	$(AS) $(ASFLAGS) -o $@ $<

%.sym : %.elf
	$(NM) --numeric-sort $< >$@

%.dis : %.elf
	$(OBJDUMP) --disassemble -S $< >$@

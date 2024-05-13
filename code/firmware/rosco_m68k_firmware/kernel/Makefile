# Make rosco_m68k ROM kernel
#
# Copyright (c)2023 Ross Bamford & contributors
# MIT LICENSE

CPU?=68010
EXTRA_CFLAGS?=-g -O1 -fomit-frame-pointer
DEFINES=-DROSCO_M68K -DROSCO_M68K_KERNEL_BUILD
FLAGS=-ffreestanding -ffunction-sections -fdata-sections							\
				-Wall -Wextra -Wno-unused-function 									\
				-Wno-unused-parameter -Wno-format -pedantic 						\
				-I../stage1/include -Iinclude -Itests/include								\
				-mcpu=$(CPU) -march=$(CPU) -mtune=$(CPU) $(DEFINES)
CFLAGS=-std=c11 $(FLAGS)
ASFLAGS=-mcpu=$(CPU) -march=$(CPU)
VASMFLAGS=-Felf -m$(CPU) -quiet -Lnf $(DEFINES)
ARFLAGS=

CC=m68k-elf-gcc
CXX=m68k-elf-g++
AS=m68k-elf-as
NM=m68k-elf-nm
LD=m68k-elf-ld
AR=m68k-elf-ar
RANLIB=m68k-elf-ranlib
OBJDUMP=m68k-elf-objdump
OBJCOPY=m68k-elf-objcopy
SIZE=m68k-elf-size
VASM=vasmm68k_mot
RM=rm -f

LIBOBJECTS=kmachine.o bitmap.o pmm.o slab.o list.o task.o sched.o api.o

.PHONY: clean test

all: kernel.a

kernel.a: $(LIBOBJECTS)
	$(AR) $(ARFLAGS) rs $@ $^
	$(RANLIB) $@

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.asm
	$(VASM) $(VASMFLAGS) $(EXTRA_VASMFLAGS) -L $(basename $@).lst -o $@ $<

test:
	$(MAKE) -C tests

clean:
	$(RM) kernel.a *.o *.bin *.elf *.lst
	$(MAKE) -C tests clean

# Make rosco_m68k programs
# 
# Copyright (c)2020 Ross Bamford
# See LICENSE

EXTRA_CFLAGS?=
SYSINCDIR?=../libs/build/include
SYSLIBDIR?=../libs/build/lib
LIBS=-lprintf -lcstdlib -lgcc -lmachine -lstart_serial
GCC_LIBS=$(shell $(CC) --print-search-dirs 															\
		| grep libraries:\ =																								\
    | sed 's/libraries: =/-L/g' 																				\
    | sed 's/:/m68000\/ -L/g')m68000/
DEFINES=-DROSCO_M68K
CFLAGS=-std=c11 -ffreestanding -Wall -pedantic -Werror -I$(SYSINCDIR) 	\
			 -mcpu=68010 -march=68010 -mtune=68010 -fomit-frame-pointer				\
			 -mno-align-int -mno-strict-align $(DEFINES)
LDFLAGS=-T $(SYSLIBDIR)/ld/serial/rosco_m68k_program.ld -L $(SYSLIBDIR) \
				-Map=$(MAP)
ASFLAGS=-Felf -m68010 -quiet $(DEFINES)
CC=m68k-elf-gcc
LD=m68k-elf-ld
AS=vasmm68k_mot
RM=rm -f

KERMIT=kermit
SERIAL?=/dev/modem
BAUD?=9600

# Output config
BINARY_BASENAME=newserial
BINARY_EXT=bin
MAP=$(BINARY_BASENAME).map
BINARY=$(BINARY_BASENAME).$(BINARY_EXT)

OBJECTS=kmain.o buffer.o serial.o

ifeq ($(WITHKERMIT),true)
include kermit/include.mk
endif

%.o : %.c
	$(CC) -c $(CFLAGS) $(EXTRA_CFLAGS) -o $@ $<

%.o : %.S
	$(AS) $(ASFLAGS) -o $@ $<

$(BINARY) : $(OBJECTS)
	$(LD) $(LDFLAGS) $(GCC_LIBS) $^ -o $@ $(LIBS)
	chmod a-x $@

.PHONY: all clean load

all: $(BINARY)

clean: 
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN) $(MAP)

load: $(BINARY)
	kermit -i -l $(SERIAL) -b $(BAUD) -s $(BINARY)

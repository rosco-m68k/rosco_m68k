# Make rosco_m68k programs
# 
# Copyright (c)2020 Ross Bamford
# See LICENSE

EXTRA_CFLAGS?=
SYSINCDIR?=../libs/build/include
SYSLIBDIR?=../libs/build/lib
LIBS=-lcstdlib -lmachine -lstart_serial -lgpio -lgcc
GCC_LIBS=$(shell $(CC) --print-search-dirs 															\
		| grep libraries:\ =																								\
    | sed 's/libraries: =/-L/g' 																				\
    | sed 's/:/m68000\/ -L/g')m68000/
DEFINES=-DROSCO_M68K -DFATFS_USE_CUSTOM_OPTS_FILE -DSPI_FASTER 					\
				-DSPI_FAST -DSD_FASTER -DSD_MINIMAL
CFLAGS=-std=c11 -ffreestanding  -Ifat_io_lib	-I$(SYSINCDIR)						\
			-Wall -Werror -Wno-unused-function 																\
			-Iinclude -mcpu=68010 -march=68010 -mtune=68010 -Os								\
			-mno-align-int -mno-strict-align  $(DEFINES)
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
BINARY_BASENAME=bbsd-test
BINARY_EXT=bin
MAP=$(BINARY_BASENAME).map
BINARY=$(BINARY_BASENAME).$(BINARY_EXT)

OBJECTS=kmain.o bbspi.o bbsd.o  fat_io_lib/fat_access.o  fat_io_lib/fat_cache.o	\
				fat_io_lib/fat_filelib.o fat_io_lib/fat_format.o fat_io_lib/fat_misc.o  \
				fat_io_lib/fat_string.o fat_io_lib/fat_table.o fat_io_lib/fat_write.o

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

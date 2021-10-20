# Make rosco_m68k ROM images
# 
# Copyright (c)2019 Ross Bamford
# See LICENSE

LDFLAGS=-T ../rosco_m68k_v1/rosco_m68k_rom.ld -Map=monitor.map
ASFLAGS=-Felf -m68010
LD=m68k-elf-ld
AS=vasmm68k_mot
RM=rm -f

# Output config
BINARY_BASENAME=monitor
BINARY_EXT=bin

BINARY=$(BINARY_BASENAME).$(BINARY_EXT)
BINARY_EVEN=$(BINARY_BASENAME)_even.$(BINARY_EXT)
BINARY_ODD=$(BINARY_BASENAME)_odd.$(BINARY_EXT)

OBJECTS=monitor.o

%.o : %.S
	$(AS) $(ASFLAGS) -o $@ $<

$(BINARY) : $(OBJECTS)
	$(LD) $(LDFLAGS) $^ -o $@
	-chmod a-x $@

$(BINARY_EVEN): $(BINARY)
	srec_cat -output $(BINARY_EVEN) -Binary $(BINARY) -Binary -Split 2 0

$(BINARY_ODD): $(BINARY)
	srec_cat -output $(BINARY_ODD) -Binary $(BINARY) -Binary -Split 2 1

.PHONY: all clean dump

all: $(BINARY_EVEN) $(BINARY_ODD)

clean: 
	$(RM) $(OBJECTS) $(BINARY) $(BINARY_ODD) $(BINARY_EVEN)

dump: $(BINARY)
	od --endian=big -tx1 $(BINARY)

burn: $(BINARY_EVEN) $(BINARY_ODD)
	./burn.sh

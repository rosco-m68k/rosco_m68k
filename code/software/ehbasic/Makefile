# Make ehbasic for rosco_m68k
# 
# Copyright (c)2020 Ross Bamford
# See LICENSE

DEFINES=-DROSCO_M68K
ASFLAGS=-Fbin -m68010 -quiet $(DEFINES)
AS=vasmm68k_mot
RM=rm -f

KERMIT=kermit
SERIAL?=/dev/modem
BAUD?=9600

# Output config
BINARY_BASENAME=ehbasic
BINARY_EXT=bin
LST=$(BINARY_BASENAME).lst
BINARY=$(BINARY_BASENAME).$(BINARY_EXT)

$(BINARY) : ehbasic.S ehdefs.S
	vasmm68k_mot -Fbin -m68010 -L $(LST) -o $(BINARY) ehbasic.S
	chmod a-x $@

.PHONY: all clean load

all: $(BINARY)

clean: 
	$(RM) $(BINARY) $(LST)

load: $(BINARY)
	kermit -i -l $(SERIAL) -b $(BAUD) -s $(BINARY)


CC=m68k-elf-rosco-gcc
OBJCOPY=m68k-elf-rosco-objcopy
OBJDUMP=m68k-elf-rosco-objdump
CFLAGS?=
LDFLAGS?=

PROGRAM=filetest

all: $(PROGRAM).bin $(PROGRAM).dis

$(PROGRAM).elf: main.o
	$(CC) $(LDFLAGS) -Wl,-Map=$(PROGRAM).map -Wl,--warn-common -o $@ $^

$(PROGRAM).dis: $(PROGRAM).elf
	$(OBJDUMP) -d $< > $@

$(PROGRAM).bin: $(PROGRAM).elf
	$(OBJCOPY) -O binary $< $@

clean:
	$(RM) main.o $(PROGRAM).bin $(PROGRAM).map $(PROGRAM).elf $(PROGRAM).dis

.PHONY: all clean


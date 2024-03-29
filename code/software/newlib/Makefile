.PHONY: all clean

all: filetest.bin gdbtest.bin

clean: 
	$(MAKE) -C libc_gdb clean
	$(MAKE) -C libc_sd clean
	$(RM) *.bin

libc_sd/filetest.bin:
	$(MAKE) -C libc_sd filetest.bin

filetest.bin: libc_sd/filetest.bin
	cp $< $@

libc_gdb/gdbtest.bin:
	$(MAKE) -C libc_gdb gdbtest.bin

gdbtest.bin: libc_gdb/gdbtest.bin
	cp $< $@


OBJECTS := $(OBJECTS) easy68k/syscalls_asm.o easy68k/syscalls.o
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -DEASY68K_TRAP

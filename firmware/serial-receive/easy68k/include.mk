CFLAGS := $(CFLAGS) -DEASY68K_TRAP
OBJECTS := $(OBJECTS) easy68k/syscalls_asm.o easy68k/syscalls.o

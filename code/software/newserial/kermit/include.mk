CFLAGS := $(CFLAGS) -DWITHKERMIT -Ikermit/include -DNODEBUG -DRECVONLY -DNO_CTRLC -DSTATIC=static
OBJECTS := $(OBJECTS) kermit/kermit.o kermit/kermit_support.o

OBJECTS := $(OBJECTS) kermit/kermit.o kermit/kermit_support.o
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -Ikermit/include -DNODEBUG -DRECVONLY 		\
	-DNO_CTRLC -DSTATIC=static -DKERMIT_LOADER	 

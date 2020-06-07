OBJECTS := $(OBJECTS) kermit/kermit.o kermit/kermit_support.o
EXTRA_CFLAGS := $(EXTRA_CFLAGS) -Ikermit/include -DNODEBUG -DRECVONLY 		\
	-DNO_CTRLC -DSTATIC=static	 
KERMIT_CFLAGS=-std=c11 -ffreestanding -Wno-unused-parameter								\
       -Wall -Werror -Wpedantic -Wno-unused-function -Os               		\
			 -Iinclude -I../include -mcpu=68010 -march=68010 -mtune=68010   		\
			 -mno-align-int -mno-strict-align $(DEFINES)

kermit/kermit.o: kermit/kermit.c
	$(CC) $(KERMIT_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

kermit/kermit_support.o: kermit/kermit_support.c
	$(CC) $(KERMIT_CFLAGS) $(EXTRA_CFLAGS) -c -o $@ $<

OBJECTS+=kermit/kermit.o kermit/kermit_support.o
INCLUDES+=-Ikermit/include
KERMIT_DEFINES:=-DNODEBUG -DRECVONLY -DNO_CTRLC -DSTATIC=static -DKERMIT_LOADER
KERMIT_INCLUDES:=-Iinclude -I../stage1/include
KERMIT_CFLAGS=											\
	$(CFLAGS) $(KERMIT_DEFINES) $(KERMIT_INCLUDES)		\
	-Wno-maybe-uninitialized -Wno-unused-variable		\
	-Wno-unused-but-set-variable -Wno-stringop-overflow

kermit/kermit.o: kermit/kermit.c
	$(CC) $(KERMIT_CFLAGS) -c -o $@ $<

kermit/kermit_support.o: kermit/kermit_support.c
	$(CC) $(KERMIT_CFLAGS) -c -o $@ $<

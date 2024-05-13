OBJECTS+=kermit/kermit.o kermit/kermit_support.o
INCLUDES+=-Ikermit/include

KERMIT_DEFINES:=-DNODEBUG -DRECVONLY -DNO_CTRLC -DSTATIC=static -DKERMIT_LOADER
KERMIT_EXTRA_CFLAGS=									\
	-Wno-maybe-uninitialized -Wno-unused-variable		\
	-Wno-unused-but-set-variable -Wno-stringop-overflow	\
	$(KERMIT_DEFINES)

kermit/%.o: CFLAGS+=$(KERMIT_EXTRA_CFLAGS)

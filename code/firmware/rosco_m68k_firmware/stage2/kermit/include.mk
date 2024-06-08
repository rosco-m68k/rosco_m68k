OBJECTS+=kermit/kermit.o kermit/kermit_support.o
DEFINES+=-DKERMIT_LOADER
INCLUDES+=-Ikermit/include

KERMIT_DEFINES:=-DNODEBUG -DRECVONLY -DNO_CTRLC -DSTATIC=static
KERMIT_EXTRA_CFLAGS=									\
	-Wno-maybe-uninitialized -Wno-unused-variable		\
	-Wno-unused-but-set-variable -Wno-stringop-overflow	\
	$(KERMIT_DEFINES)

kermit/%.o: CFLAGS+=$(KERMIT_EXTRA_CFLAGS)

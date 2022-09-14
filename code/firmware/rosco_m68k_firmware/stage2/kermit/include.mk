OBJECTS+=kermit/kermit.o kermit/kermit_support.o
INCLUDES+=-Ikermit/include
DEFINES+=-DNODEBUG -DRECVONLY -DNO_CTRLC -DSTATIC=static -DKERMIT_LOADER	 

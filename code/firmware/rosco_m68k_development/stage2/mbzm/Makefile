CC=gcc
LD=gcc
CCP=g++
LDP=g++

CFLAGS=-std=c11 -Wall -Werror -Wpedantic -Iinclude -O3
CPPFLAGS=-std=c++17 -Wall -Werror -Wpedantic -Iinclude -O3
LDFLAGS=

OBJFILES=zheaders.o znumbers.o zserial.o crc16.o crc32.o

all: rz test cpptest

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.cpp
	$(CCP) $(CPPFLAGS) -c -o $@ $<
	
rz: rz.o $(OBJFILES)
	$(LD) $(LDFLAGS) $^ -o $@

test: tests.c zheaders.c znumbers.c zserial.c crc16.c crc32.c
	$(CC) $(CFLAGS) -DTEST -o $@ $^
	./$@

cpptest: cpptest.o $(OBJFILES) 
	$(LDP) $(LDPFLAGS) $^ -o $@
	
clean:
	rm -f *.o rz test


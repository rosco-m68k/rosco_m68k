CFLAGS=-I.. -Iunity -g
LDFLAGS=

.PHONY: all clean

all: test

clean:
	rm -rf *.o test_parse_menu

%.o: ../%.c
	$(CC) -c $(CFLAGS) -o $@ $<

unity/unity.o: unity/unity.c
	$(CC) -c $(CFLAGS) -o $@ $<

test_parse_menu.o: test_parse_menu.c
	$(CC) -c $(CFLAGS) -o $@ $<

test_parse_menu: test_parse_menu.o parse_menu.o unity/unity.o
	$(CC) $(LDFLAGS) -o $@ $^

test: test_parse_menu
	./test_parse_menu

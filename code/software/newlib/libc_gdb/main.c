#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <rosco_m68k/debug.h>

#define BUF_SIZE    64

static void existing_file_test();
static void new_file_test();

static void afunc() {
    int a = 3 + 5;
    printf("Int is %d\n", a);
}

int main() {
    printf("Waiting for debugger attach...\n");    
    breakpoint();

    afunc();
}


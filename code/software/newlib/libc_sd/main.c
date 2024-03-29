#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <rosco_m68k/debug.h>

#define BUF_SIZE    64

static void existing_file_test();
static void new_file_test();

int main() {
    printf("## libc file test\n\n");

    existing_file_test();
    new_file_test();
    
    printf("Tests are done!\n");

    breakpoint();
}

static void do_read_test(char *fn) {
    FILE *f = fopen(fn, "r");

    if (f) {
        printf("File %s opened - reading\n", fn);
        char buffer[BUF_SIZE];
        int num;

        do {
            num = fread(buffer, 1, BUF_SIZE, f);

            if (num > 0) {
                printf("%.*s", num, buffer);
            } else if (num == -1) {
                printf("  Read failed: 0x%08x\n", errno);
            } else {
                if (feof(f)) {
                    printf("<--- EOF>\n");
                } else {
                    printf("<--- ERR>\n");
                }
            }
        } while (num > 0);
    } else {
        printf("Open failed: 0x%08x\n", errno);
    }

    fclose(f);
}

static void existing_file_test() {
    printf("### Read existing file\n");
    do_read_test("/sd/test.txt");
    printf("Existing file test done\n\n");
}

static void new_file_test() {
    printf("### Write / read new file\n");
    FILE *f = fopen("/sd/test2.txt", "w");

    if (f) {
        printf("File /sd/test2.txt opened - writing\n");
        char *buffer = "This is some data for a new file\nOf course, it is also rather awesome!\n\n";
        int total = 0;
        int num;

        do {
            num = fwrite(buffer, 1, strlen(buffer), f);

            if (num > 0) {
                total += num;
                printf("  Wrote %d bytes [%d of total %d done]\n", num, total, strlen(buffer));
            } else if (num == -1) {
                printf("  Write failed: 0x%08x\n", errno);
                break;
            }
        } while (total < strlen(buffer));
    } else {
        printf("Open failed: 0x%08x\n", errno);
    }

    fclose(f);

    do_read_test("/sd/test2.txt");

    printf("New file test done\n\n");
}


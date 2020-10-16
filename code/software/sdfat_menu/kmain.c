/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2020 Xark
 * MIT License
 *
 * Example SD card file menu
 * ------------------------------------------------------------
 */

#include <ctype.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdnoreturn.h>
#include <string.h>

#include <basicio.h>
#include <debug_stub.h>
#include <machine.h>
#include <sdfat.h>

#define INSTALL_DEBUG_STUB 1 // set to 1 to trap exceptions
#define ENABLE_CMD_PROMPT  1 // set to 1 to enable mini command prompt
#define ENABLE_LOAD_CRC32  1 // set to 1 to print CRC32 of loaded programs
#define DISABLE_SD_BOOT    0 // set to 1 to always disable next SD boot

// number of elements in C array
#define ELEMENTS(a) ((int)(sizeof(a) / sizeof(*a)))

// timer helpers
static uint32_t start_tick;

void timer_start()
{
    uint32_t ts = _TIMER_100HZ;
    uint32_t t;
    while ((t = _TIMER_100HZ) == ts)
        ;
    start_tick = t;
}

uint32_t timer_stop()
{
    uint32_t stop_tick = _TIMER_100HZ;

    return (stop_tick - start_tick) * 10;
}

// From https://web.mit.edu/freebsd/head/sys/libkern/crc32.c
/*-
 *  COPYRIGHT (C) 1986 Gary S. Brown.  You may use this program, or
 *  code or tables extracted from it, as desired without restriction.
 *
 * CRC32 code derived from work by Gary S. Brown.
 */

static const uint32_t crc32_tab[] = {
    0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3,
    0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91,
    0x1db71064, 0x6ab020f2, 0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
    0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5,
    0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172, 0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b,
    0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
    0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423, 0xcfba9599, 0xb8bda50f,
    0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924, 0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d,
    0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
    0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01,
    0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457,
    0x65b0d9c6, 0x12b7e950, 0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
    0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb,
    0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0, 0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9,
    0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
    0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81, 0xb7bd5c3b, 0xc0ba6cad,
    0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683,
    0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
    0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7,
    0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5,
    0xd6d6a3e8, 0xa1d1937e, 0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
    0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79,
    0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236, 0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f,
    0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
    0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f, 0x72076785, 0x05005713,
    0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21,
    0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
    0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45,
    0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db,
    0xaed16a4a, 0xd9d65adc, 0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
    0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf,
    0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94, 0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d};

/*
 * A function that calculates the CRC-32 based on the table above is
 * given below for documentation purposes. An equivalent implementation
 * of this function that's actually used in the kernel can be found
 * in sys/libkern.h, where it can be inlined.
 */

static uint32_t crc32b(uint32_t crc, const void * buf, size_t size)
{
    const uint8_t * p = buf;

    crc ^= ~0U;
    while (size--)
    {
        crc = crc32_tab[(crc ^ *p++) & 0xFF] ^ (crc >> 8);
    }
    return crc ^ ~0U;
}

// resident _EFP_SD_INIT hook to disable SD loader for next boot
#define RESIDENT_MAGIC 0xb007c0de
extern void resident_init();

static void disable_sd_boot()
{
    int32_t reserved = _SDB_MEM_SIZE - _INITIAL_STACK;
    if (reserved == 0 || *(uint32_t *)_INITIAL_STACK != RESIDENT_MAGIC)
    {
        resident_init();
    }
}

noreturn static void warm_boot(bool no_sd)
{
#if DISABLE_SD_BOOT
    (void)no_sd;
#else
    if (no_sd)
#endif
    {
        disable_sd_boot();
    }
    printf("Exit\n");
    _WARM_BOOT();
    __builtin_unreachable();
}

#define MAX_BIN_FILES   26
#define MAX_BIN_NAMELEN 128

static int num_bin_files;
static char bin_files[MAX_BIN_FILES][MAX_BIN_NAMELEN];
static uint32_t bin_sizes[MAX_BIN_FILES];
static char current_dir[MAX_BIN_NAMELEN];
static char filename[256];

// NOTE: puts full path in "filename"
static char * fullpath(const char * path)
{
    // full path
    if (path[0] == '/')
    {
        strncpy(filename, path, sizeof(filename) - 1);
    }
    else
    {
        snprintf(filename, sizeof(filename) - 1, "/%s%s%s", current_dir, strlen(current_dir) > 0 ? "/" : "",
                 path);
    }

    return filename;
}

static void get_bin_list()
{
    num_bin_files = 0;
    memset(bin_files, 0, sizeof(bin_files));
    memset(bin_sizes, 0, sizeof(bin_sizes));
    FL_DIR dirstat;

    if (fl_opendir(fullpath(""), &dirstat))
    {
        struct fs_dir_ent dirent;

        while (fl_readdir(&dirstat, &dirent) == 0)
        {
            if (!dirent.is_dir)
            {
                int len = strlen(dirent.filename);
                if (len > 4)
                {
                    const char * ext = dirent.filename + len - 4;
                    if (strcasecmp(ext, ".bin") == 0)
                    {
                        if (num_bin_files >= MAX_BIN_FILES)
                        {
                            printf("*** Too many BIN files (use prompt to access others > 26)\n");
                            break;
                        }
                        // strncpy while lowercaseing
                        for (int i = 0; i < MAX_BIN_NAMELEN - 1; i++)
                        {
                            char c = tolower(dirent.filename[i]);
                            bin_files[num_bin_files][i] = c;
                            if (c == 0)
                            {
                                break;
                            }
                        }
                        bin_sizes[num_bin_files] = dirent.size;
                        num_bin_files++;
                    }
                }
            }
        }

        fl_closedir(&dirstat);
    }
}

static void show_bin_list()
{
    char mem_str[16]; // xxxxxK
    char up_str[16];  // xxx:xx
    uint32_t ts = _TIMER_100HZ;
    uint32_t tm = ts / (60 * 100);
    ts = (ts - (tm * (60 * 100))) / 100;

    sprintf(mem_str, "%uK", (_INITIAL_STACK + 1023) / 1024);
    sprintf(up_str, "%02u:%02u", tm, ts);
    printf("Dir: %-34.34s <Mem %-6.6s Uptime %s>\n", fullpath(""), mem_str, up_str);
    int half = (num_bin_files + 1) / 2;
    for (int d = 0; d < num_bin_files; d++)
    {
        uint32_t fsize = (bin_sizes[d] + 1023) / 1024;
        char unit = 'K';

        if (fsize >= 1000)
        {
            unit = 'M';
            fsize = (fsize + 1023) / 1024;
        }

        if (d & 1)
        {
            printf("[%3u%c] %c - %-28.28s\n", fsize, unit, 'A' + half + (d / 2), bin_files[d]);
        }
        else
        {
            printf("[%3u%c] %c - %-28.28s  ", fsize, unit, 'A' + (d / 2), bin_files[d]);
        }
    }

    if (num_bin_files & 1)
    {
        printf("\n");
    }
}

static bool no_sd_boot;

static void load_bin_file(const char * name)
{
    fullpath(name);
    printf("Loading \"%s\"", filename);

    timer_start();
    void * file = fl_fopen(filename, "r");

    if (!file)
    {
        char * ext = strrchr(filename, '.');
        if (ext)
        {
            for (int i = 1; i < 4; i++)
            {
                if (ext[i] == '\0')
                {
                    ext[i] = ' ';
                }
            }
            ext[4] = '\0';
        }
        file = fl_fopen(filename, "r");
    }

    if (file != NULL)
    {
        int c = 0;
        int b = 0;
        uint8_t * loadstartptr = (uint8_t *)_LOAD_ADDRESS;
        uint8_t * loadptr = loadstartptr;
        uint8_t * endptr = (uint8_t *)_INITIAL_STACK;
        while (loadptr < endptr && (c = fl_fread(loadptr, 512, 1, file)) > 0)
        {
            loadptr += c;
            /* period every 4KiB, does not noticeably affect speed */
            if (++b == 8)
            {
                mcSendchar('.');
                b = 0;
            }
        }

        fl_fclose(file);
        uint32_t load_time = timer_stop();
        uint32_t bytes = loadptr - loadstartptr;

        if (c == EOF)
        {
            printf("\nLoaded %u bytes in %u.%02u sec.; ", bytes, load_time / 1000U, load_time % 1000U);
#if ENABLE_LOAD_CRC32
            printf("CRC-32=");
            uint32_t crc = crc32b(0, loadstartptr, bytes);
            printf("0x%08X; ", crc);
#endif
            printf("Starting...\n\n");

            if (no_sd_boot)
            {
                disable_sd_boot();
            }
            __asm__ __volatile__(" jmp _LOAD_ADDRESS\n" : : :);
            __builtin_unreachable();
        }
        else
        {
            printf("\n*** %s error at offset %d (0x%08x)\n", (loadptr < endptr) ? "Read" : "Too large", bytes,
                   bytes);
        }
    }
    else
    {
        printf("...open failed.\n\n");
    }
}

#if ENABLE_CMD_PROMPT

static char buffer[512];
static char cmd_line[256];
static uint32_t bytecount;
static uint32_t filecrc;

static void dir_operation(const char * name)
{
    int num_files = 0;
    int num_dirs = 0;
    uint32_t totalsize = 0;
    FL_DIR dirstat;

    fullpath(name);
    printf("Directory: %s\n", filename);
    if (fl_opendir(filename, &dirstat))
    {
        struct fs_dir_ent dirent;

        while (fl_readdir(&dirstat, &dirent) == 0)
        {
            if (!dirent.is_dir)
            {
                printf("%10d  %s\n", dirent.size, dirent.filename);
                uint32_t old_total = totalsize; // clamp vs wrap
                totalsize += dirent.size;
                if (totalsize < old_total)
                {
                    totalsize = ~0U;
                }
                num_files++;
            }
            else if (strcmp(dirent.filename, ".") != 0)
            {
                printf("  <Dir>     %s\n", dirent.filename);
                num_dirs++;
            }
        }

        fl_closedir(&dirstat);

        printf("\n%d file%s, %d dir%s, %s%u total bytes\n", num_files, num_files == 1 ? "" : "s", num_dirs,
               num_dirs == 1 ? "" : "s", totalsize == ~0U ? "> " : "", totalsize);
    }
    else
    {
        printf("\n*** Can't dir \"%s\"\n", filename);
    }
}

static void file_operation(const char * name, void (*op_func)(char * p, int l))
{
    bytecount = 0;
    fullpath(name);
    printf("\"%s\":\n", filename);

    void * file = fl_fopen(filename, "r");
    // try again with 3 character extension
    if (!file)
    {
        char * ext = strrchr(filename, '.');
        if (ext)
        {
            for (int i = 1; i < 4; i++)
            {
                if (ext[i] == '\0')
                {
                    ext[i] = ' ';
                }
            }
            ext[4] = '\0';
        }
        file = fl_fopen(filename, "r");
    }

    if (file != NULL)
    {
        int c;
        while ((c = fl_fread(buffer, sizeof(buffer), 1, file)) > 0)
        {
            op_func(buffer, c);
            bytecount += c;
        }

        fl_fclose(file);

        if (c != EOF)
        {
            printf("\n*** Read error at offset %d (0x%08x)\n", bytecount, bytecount);
        }
    }
    else
    {
        printf("\n*** Can't open \"%s\"\n", filename);
    }
}

static void op_type(char * p, int l)
{
    while (l--)
    {
        char c = *p++;

        if ((c < ' ' || c > '~') && c != '\n' && c != '\t')
        {
            printf("\\x%02x", (uint8_t)c);
        }
        else
        {
            printf("%c", c);
        }
    }
}

// NOTE: assumes l is always multiple of 16
static void op_dump(char * p, int l)
{
    uint32_t off = bytecount;
    uint8_t * t = (uint8_t *)p;
    uint8_t * s = t;
    while (l--)
    {
        if ((off & 0xf) == 0)
        {
            printf("%08x: ", off);
            s = t;
        }
        printf("%02x ", *t++);
        if ((off & 0xf) == 0xf)
        {
            printf("  ");
            for (int a = 0; a < 16; a++)
            {
                printf("%c", s[a] < ' ' || s[a] > '~' ? '.' : s[a]);
            }
            printf("\n");
        }
        off++;
    }
}

static void op_crc(char * p, int l)
{
    filecrc = crc32b(filecrc, p, l);
}

void command_prompt()
{
    printf("SD card command prompt (? for help)\n\n");
    while (true)
    {
        printf("%s> ", fullpath(""));
        memset(cmd_line, 0, sizeof(cmd_line));
        readline(cmd_line, sizeof(cmd_line) - 1);

        char * cmd = cmd_line;
        while (*cmd == ' ')
        {
            cmd++;
        }
        char * arg = cmd;
        while (*arg && *arg != ' ')
        {
            arg++;
        }
        if (*arg)
        {
            *arg++ = '\0';
        }

        if (strcasecmp(cmd, "exit") == 0 || strcasecmp(cmd, "x") == 0)
        {
            printf("Menu...\n");
            break;
        }
        else if (strcasecmp(cmd, "dir") == 0)
        {
            dir_operation(arg);
        }
        else if (strcasecmp(cmd, "cd") == 0)
        {
            if (*arg == '\0')
            {
                memset(current_dir, 0, sizeof(current_dir));
            }
            else if (strcmp(arg, "..") == 0)
            {
                if (current_dir[strlen(current_dir)] == '/')
                {
                    current_dir[strlen(current_dir)] = '\0';
                }
                char * parent = strrchr(current_dir, '/');
                if (parent)
                {
                    *parent = '\0';
                }
                else
                {
                    current_dir[0] = '\0';
                }
            }
            else if (fl_is_dir(fullpath(arg)))
            {
                strncpy(current_dir, filename + 1, sizeof(current_dir) - 1); // skip leading /
            }
            else
            {
                printf("*** \"%s\" not a dir\n", filename);
            }
        }
        else if (strcasecmp(cmd, "run") == 0)
        {
            load_bin_file(arg);
        }
        else if (strcasecmp(cmd, "type") == 0)
        {
            file_operation(arg, op_type);
        }
        else if (strcasecmp(cmd, "dump") == 0)
        {
            file_operation(arg, op_dump);
            if ((bytecount & 0xf) != 0)
            {
                printf("\n");
            }
        }
        else if (strcasecmp(cmd, "crc") == 0)
        {
            filecrc = 0;
            file_operation(arg, op_crc);
            printf("%d bytes, CRC-32=0x%08X\n", bytecount, filecrc);
        }
        else if (strcasecmp(cmd, "upload") == 0)
        {
            warm_boot(true);
        }
        else if (strcasecmp(cmd, "boot") == 0)
        {
            warm_boot(false);
        }
        else if (strlen(cmd) > 0)
        {
            printf("SD card commands:\n");
            printf("dir  [dir]      Directory listing\n");
            printf("cd   [dir]      Change current directory\n");
            printf("run  <file>     Load and execute BIN file\n");
            printf("type <file>     Type ASCII file\n");
            printf("dump <file>     Hex+ASCII dump of file\n");
            printf("crc  <file>     CRC-32 of file\n");
            printf("upload          Warm-boot with no SD card boot\n");
            printf("boot            Warm-boot\n");
            printf("exit            Exit to menu (with current dir)\n");
        }
    }
}
#endif // ENABLE_CMD_PROMPT

static uint32_t private_stack[1024]; // 4KB "private" stack
void kmain()
{
    // switch to private stack (to avoid loaded program overwriting stack)
    // NOTE: kmain should not try to "return", due to this. :)
    __asm__ __volatile__("move.l %[private_stack],%%a7\n"
                         :
                         : [ private_stack ] "a"(&private_stack[ELEMENTS(private_stack)])
                         :);

#if INSTALL_DEBUG_STUB
    debug_stub();
#endif

    printf("\nrosco_m68k [FW:%X.%02X%s]: SD Card menu - Xark (" __DATE__ " " __TIME__ ")\n\n",
           (_FIRMWARE_REV >> 8) & 0xff, _FIRMWARE_REV & 0xff, _FIRMWARE_REV & (1 << 31) ? "*" : "");

    if (!SD_check_support())
    {
        printf("*** This program requires SD card support in firmware.\n");
        printf("Press any key...\n");
        readchar();
        _WARM_BOOT();
    }

    while (1)
    {
        while (!SD_FAT_initialize())
        {
            printf("\nNo SD card found. SPACE to retry, other key to exit: ");
            char key = readchar();
            if (key != ' ')
            {
                printf("Exit\n\n");
                warm_boot(false);
            }
            printf("Retry\n\n");
        }

        get_bin_list();

        if (num_bin_files == 0)
        {
            printf("\nNo BIN files present.\n");
#if ENABLE_CMD_PROMPT
            command_prompt();
#endif
            continue;
        }

        show_bin_list();

#if ENABLE_CMD_PROMPT
        printf("\nPress A-%c to run, RETURN for prompt, '/' to upload, SPACE to reload: ",
               'A' + num_bin_files - 1);
#else
        printf("\nPress A-%c to run, '/' to upload, SPACE to reload: ", 'A' + num_bin_files - 1);
#endif

        bool getnewkey;
        do
        {
            getnewkey = false;
            char key = readchar();

#if ENABLE_CMD_PROMPT
            if (key == '\n' || key == '\r')
            {
                printf("prompt\n\n");
                command_prompt();
                continue;
            }
#endif
            key = toupper(key);
            if (key >= 'A' && key <= 'Z')
            {
                int run_num = (key - 'A');
                int half = (num_bin_files + 1) / 2;
                if (run_num >= half)
                {
                    run_num = ((run_num - half) * 2) + 1;
                }
                else
                {
                    run_num = run_num * 2;
                }

                if (run_num >= num_bin_files)
                {
                    mcSendchar('\a');
                    getnewkey = true;
                    continue;
                }

                printf("%c\n\n", key);

                load_bin_file(bin_files[run_num]);
            }
            else if (key == '.')
            {
                no_sd_boot = !no_sd_boot;
                printf("%s \n\n", no_sd_boot ? "sd boot OFF" : "sd boot ON");
            }
            else if (key == '/' || key == '\x01') // ^a for kermit
            {
                printf("upload\n\n");
                warm_boot(true);
            }
            else if (key != ' ')
            {
                printf("exit\n\n");
                warm_boot(no_sd_boot);
            }
            else if (!getnewkey)
            {
                printf("reload\n\n");
            }
        } while (getnewkey);
    }

    warm_boot(false);
}

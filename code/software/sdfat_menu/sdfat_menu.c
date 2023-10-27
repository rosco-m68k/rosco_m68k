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
#include <strings.h>

#include <basicio.h>
#include <machine.h>
#include <sdfat.h>

// menu program options
#define ENABLE_LOAD_CRC32 1        // 1 to calc CRC-32 of loaded programs (slight delay)

// number of elements in C array
#define ELEMENTS(a) ((int)(sizeof(a) / sizeof(*a)))

#define MAX_FILE_PAGES  10
#define MAX_BIN_FILES   26 * MAX_FILE_PAGES            // A to Z menu BIN files
#define MAX_DIR_FILES   10                             // 0 to 9 menu directories
#define MAX_BIN_NAMELEN FATFS_MAX_LONG_FILENAME        // full name length

static bool         no_sd_boot;                                        // flag to disable SD boot upon warm-start
static int          num_menu_files;                                    // number of BIN files in menu
static int          num_menu_pages;                                    // number menu pages
static int          cur_page;                                          // current menu page
static int          num_dir_files;                                     // number of directories in menu
static char         menu_files[MAX_BIN_FILES][MAX_BIN_NAMELEN];        // names of BIN files
static char         dir_files[MAX_DIR_FILES][MAX_BIN_NAMELEN];         // names of directories
static unsigned int bin_sizes[MAX_BIN_FILES];                          // sizes of BIN files
static char         current_dir[MAX_BIN_NAMELEN];                      // current dir string (root = "")
static char         buffer[512];                                       // file sector buffer
static char         cmd_line[256];                                     // prompt command line buffer
static void *       file2;                                             // target fileptr
static char *       cmd_ptr;                                           // ptr to next token in cmd_line
static unsigned int filesize;                                          // current filesize at start of sector
static unsigned int filecrc;                                           // current CRC-32 at start of sector for crc

// timer helpers
unsigned int timer_start()
{
    unsigned int t;
    unsigned int ts = _TIMER_100HZ;
    // synchronize start to next 100Hz interrupt
    while ((t = _TIMER_100HZ) == ts)
        ;
    return t;
}

unsigned int timer_stop(unsigned int start_tick)
{
    unsigned int stop_tick = _TIMER_100HZ;
    return (stop_tick - start_tick) * 10;
}

// From https://web.mit.edu/freebsd/head/sys/libkern/crc32.c
/*-
 *  COPYRIGHT (C) 1986 Gary S. Brown.  You may use this program, or
 *  code or tables extracted from it, as desired without restriction.
 *
 * CRC32 code derived from work by Gary S. Brown.
 */

/*
 * A function that calculates the CRC-32 based on the table above is
 * given below for documentation purposes. An equivalent implementation
 * of this function that's actually used in the kernel can be found
 * in sys/libkern.h, where it can be inlined.
 */

static unsigned int crc32b(unsigned int crc, const void * buf, size_t size)
{
    static const unsigned int crc32_tab[] = {
        0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f, 0xe963a535, 0x9e6495a3, 0x0edb8832,
        0x79dcb8a4, 0xe0d5e91e, 0x97d2d988, 0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91, 0x1db71064, 0x6ab020f2,
        0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7, 0x136c9856, 0x646ba8c0, 0xfd62f97a,
        0x8a65c9ec, 0x14015c4f, 0x63066cd9, 0xfa0f3d63, 0x8d080df5, 0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
        0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b, 0x35b5a8fa, 0x42b2986c, 0xdbbbc9d6, 0xacbcf940, 0x32d86ce3,
        0x45df5c75, 0xdcd60dcf, 0xabd13d59, 0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423,
        0xcfba9599, 0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924, 0x2f6f7c87, 0x58684c11, 0xc1611dab,
        0xb6662d3d, 0x76dc4190, 0x01db7106, 0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
        0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d, 0x91646c97, 0xe6635c01, 0x6b6b51f4,
        0x1c6c6162, 0x856530d8, 0xf262004e, 0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
        0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65, 0x4db26158, 0x3ab551ce, 0xa3bc0074,
        0xd4bb30e2, 0x4adfa541, 0x3dd895d7, 0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
        0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa, 0xbe0b1010, 0xc90c2086, 0x5768b525,
        0x206f85b3, 0xb966d409, 0xce61e49f, 0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81,
        0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a, 0xead54739, 0x9dd277af, 0x04db2615,
        0x73dc1683, 0xe3630b12, 0x94643b84, 0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
        0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb, 0x196c3671, 0x6e6b06e7, 0xfed41b76,
        0x89d32be0, 0x10da7a5a, 0x67dd4acc, 0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5, 0xd6d6a3e8, 0xa1d1937e,
        0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b, 0xd80d2bda, 0xaf0a1b4c, 0x36034af6,
        0x41047a60, 0xdf60efc3, 0xa867df55, 0x316e8eef, 0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
        0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe, 0xb2bd0b28, 0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7,
        0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d, 0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f,
        0x72076785, 0x05005713, 0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38, 0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7,
        0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242, 0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
        0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69, 0x616bffd3, 0x166ccf45, 0xa00ae278,
        0xd70dd2ee, 0x4e048354, 0x3903b3c2, 0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc,
        0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9, 0xbdbdf21c, 0xcabac28a, 0x53b39330,
        0x24b4a3a6, 0xbad03605, 0xcdd70693, 0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
        0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d};

    const uint8_t * p = buf;
    crc               = crc ^ ~0U;
    while (size--)
    {
        crc = crc32_tab[(crc ^ *p++) & 0xFF] ^ (crc >> 8);
    }
    return crc ^ ~0U;
}

// return -1 if ^C
bool       ctrl_c_flag;
static int check_ctrlc()
{
    if (!checkchar())
    {
        return 0;
    }

    char c = readchar();

    if (c == 3)
    {
        printf("^C\n");
        ctrl_c_flag = true;
        return -1;
    }

    return 1;
}

// pause if space, return -1 if ^C
static int check_pause()
{
    int rc = check_ctrlc();
    if (rc < 0)
    {
        return -1;
    }
    else if (rc > 0)
    {
        if (readchar() == 3)
        {
            rc = -1;
            printf("^C\n");
            ctrl_c_flag = true;
        }
    }

    return rc;
}

// read line from keyboard with basic editing
static int prompt_readline(char * buf, int buf_size)
{
    ctrl_c_flag = false;
    memset(buf, 0, buf_size);

    int len = 0;
    while (true)
    {
        char c = readchar();

        // accept string
        if (c == '\r')
        {
            break;
        }

        switch (c)
        {
            // backspace
            case '\b': /* ^H */
            case 0x7F: /* DEL */
                if (len > 0)
                {
                    buf[--len] = '\0';
                    printf("\b \b");
                }
                break;
            // clear string
            case '\x3':  /* ^C */
            case '\x18': /* ^X */
                while (len > 0)
                {
                    buf[--len] = '\0';
                    printf("\b \b");
                }
                break;

            // add non-control character
            default:
                if (len < (buf_size - 1) && c >= ' ')
                {
                    printchar(c);
                    buf[len++] = c;
                }
        }
    }
    printf("\n");
    // make sure string is terminated
    buf[len] = 0;
    return len;
}

// resident _EFP_SD_INIT hook to disable SD loader upon next boot
static void disable_sd_boot()
{
    extern void        resident_init();              // no SD boot resident setup
    const unsigned int magic    = 0xb007c0de;        // no SD boot signature (from resident.asm)
    int32_t            reserved = _SDB_MEM_SIZE - _INITIAL_STACK;
    // if no high memory reserved, or no SD signature not detected
    if (reserved == 0 || *(unsigned int *)_INITIAL_STACK != magic)
    {
        resident_init();        // install no SD hook next next warm-start
    }
}

// warm-boot helper, no_sd true to disable SD card booting
noreturn static void warm_boot(bool no_sd)
{
    if (no_sd)
    {
        disable_sd_boot();
    }
    printf("\nMenu exit.  -= DON'T PANIC =-");
    _WARM_BOOT();
    __builtin_unreachable();
}

// NOTE: puts full path in "filename"
static char * fullpath(const char * path)
{
    static char filename[FATFS_MAX_LONG_FILENAME];        // temp filename string buffer

    // clear filename string
    memset(filename, 0, sizeof(filename));

    // full path
    if (path[0] == '/')
    {
        strncpy(filename, path, sizeof(filename) - 1);
    }
    else
    {
        snprintf(filename, sizeof(filename) - 1, "/%s%s%s", current_dir, strlen(current_dir) > 0 ? "/" : "", path);
    }

    return filename;
}

// return next argument from cmd_ptr
char * next_cmd_token()
{
    char * token = cmd_ptr;
    // skip leading spaces
    while (*token == ' ')
    {
        token++;
    }
    bool quoted = false;
    if (*token == '"')
    {
        quoted = true;
        token++;
    }
    // arg string
    char * end_token = token;
    // either empty or starts after space (unless quoted)
    while (*end_token && *end_token != '"' && !(*end_token == ' ' && quoted == false))
    {
        end_token++;
    }
    // end cmd_ptr string
    *end_token++ = '\0';
    cmd_ptr      = end_token;

    return token;
}

// format size to "friendly" 4 char string (e.g, 321B, 4.2K, 42M or 3.1G)
static char * friendly_size(unsigned int v)
{
    static char  size_str[8];        // friendly string buffer
    unsigned int units     = 1;
    char         unitlabel = 'B';

    if (v > 999)
    {
        if (v < (999 * 1024))
        {
            units     = 1024;
            unitlabel = 'K';
        }
        else if (v < (999 * 1024 * 1024))
        {
            units     = 1024 * 1024;
            unitlabel = 'M';
        }
        else
        {
            units     = 1024 * 1024 * 1024;
            unitlabel = 'G';
        }
    }

    // if single digit, also give tenths
    unsigned int round = (units / 10) / 2;
    unsigned int iv    = (v + round) / units;
    if (iv < 10 && units > 1)
    {
        unsigned int tenth_units = units / 10;
        unsigned int tv          = (v + round - (iv * units)) / (tenth_units > 0 ? tenth_units : 1);
        snprintf(size_str, sizeof(size_str), "%u.%u%c", iv, tv, unitlabel);
    }
    else
    {
        round = (units / 1000) / 2;
        iv    = (v + round) / units;
        snprintf(size_str, sizeof(size_str), "%u%c", iv, unitlabel);
    }

    return size_str;
}

// verify SD card and FAT is initialized and current directory is valid
static void check_sd_card()
{
    while (!SD_FAT_initialize())
    {
        printf("\nNo SD card detected. SPACE to retry, other key to warm-boot: ");
        char key = readchar();
        if (key != ' ')
        {
            printf("exit\n");
            warm_boot(false);
        }
        printf("retry\n");
    }

    // double check current_dir is still valid (in case SD card changed)
    if (!fl_is_dir(fullpath("")))
    {
        printf("*** Current dir set to /\n");
        memset(current_dir, 0, sizeof(current_dir));
    }
}

// gather files and directories for menu from current dir
static void get_menu_files()
{
    cur_page       = 0;
    num_menu_pages = 0;
    num_menu_files = 0;
    num_dir_files  = 0;
    memset(menu_files, 0, sizeof(menu_files));
    memset(bin_sizes, 0, sizeof(bin_sizes));
    memset(dir_files, 0, sizeof(dir_files));
    FL_DIR dirstat;
    bool   too_many_files = false;
    bool   too_many_dirs  = false;

    if (fl_opendir(fullpath(""), &dirstat))
    {
        struct fs_dir_ent dirent;

        while (fl_readdir(&dirstat, &dirent) == 0)
        {
            if (!dirent.is_dir)
            {
                int len = strlen(dirent.filename);
                if (len >= 4)
                {
                    const char * ext = dirent.filename + len - 4;
                    if (strcasecmp(ext, ".bin") == 0 || strcasecmp(ext, ".txt") == 0)
                    {
                        if (num_menu_files < MAX_BIN_FILES)
                        {
                            strncpy(menu_files[num_menu_files], dirent.filename, MAX_BIN_NAMELEN - 1);
                            bin_sizes[num_menu_files] = dirent.size;
                            num_menu_files++;
                        }
                        else
                        {
                            if (!too_many_files)
                            {
                                printf("*** Too many menu files (use prompt to access others > %d)\n", MAX_BIN_FILES);
                                too_many_files = true;
                            }
                        }
                    }
                }
            }
            else if (strcmp(dirent.filename, ".") != 0)
            {
                if (num_dir_files < MAX_DIR_FILES)
                {
                    // ignore hidden/system directories
                    if (dirent.filename[0] != '.')
                    {
                        strncpy(dir_files[num_dir_files], dirent.filename, MAX_BIN_NAMELEN - 1);
                        num_dir_files++;
                    }
                }
                else
                {
                    if (!too_many_dirs)
                    {
                        printf("*** Too many directories (use prompt to access others > %d)\n", MAX_DIR_FILES);
                        too_many_dirs = true;
                    }
                }
            }
        }

        fl_closedir(&dirstat);
    }

    num_menu_pages = (num_menu_files + 25) / 26;
}

// display file menu
static void show_menu_files()
{
    char         mem_str[16];        // xxxxxK
    char         up_str[16];         // xxx:xx
    unsigned int ts = _TIMER_100HZ;
    unsigned int tm = ts / (60 * 100);
    ts              = (ts - (tm * (60 * 100))) / 100;

    int first_file = cur_page * 26;
    int file_count = first_file + 26 < num_menu_files ? 26 : num_menu_files - first_file;

    snprintf(mem_str, sizeof(mem_str), "%luK", (_INITIAL_STACK + 1023) / 1024);
    snprintf(up_str, sizeof(up_str), "%02u:%02u", tm, ts);
    printf("\nDir: %-33.33s <Mem %-6.6s Uptime %s>  Page %d/%d\n",
           fullpath(""),
           mem_str,
           up_str,
           cur_page + 1,
           num_menu_pages);
    bool odd  = false;
    int  half = (file_count + 1) / 2;
    for (int i = 0; i < file_count; i++)
    {
        int fi = first_file + i;
        printf("[%4s] %c - %-27.27s%s",
               friendly_size(bin_sizes[fi]),
               'A' + (i / 2) + (odd ? half : 0),
               menu_files[fi],
               odd ? "\n" : "  ");
        odd = !odd;
    }

    half = (num_dir_files + 1) / 2;
    for (int i = 0; i < num_dir_files; i++)
    {
        printf("<Dir>  %c = %-27.27s%s", '0' + (i / 2) + (i & 1 ? half : 0), dir_files[i], odd ? "\n" : "  ");
        odd = !odd;
    }

    if (odd)
    {
        printf("\n");
    }
}

static void execute_bin_file(const char * name, uint8_t * loadstartptr)
{
    const char * filename = fullpath(name);
    printf("Loading \"%s\"", filename);

    if (loadstartptr != (uint8_t *)_LOAD_ADDRESS)
    {
        printf(" to address 0x%08x", (int)loadstartptr);
    }

    unsigned int timer = timer_start();
    void *       file  = fl_fopen(filename, "r");

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
        int       c       = 0;
        int       b       = 0;
        uint8_t * loadptr = loadstartptr;
        uint8_t * endptr  = (uint8_t *)_INITIAL_STACK;
        while (loadptr < endptr && (c = fl_fread(loadptr, 1, 512, file)) > 0)
        {
            loadptr += c;
            /* period every 4KiB, does not noticeably affect speed */
            if (++b == 8)
            {
                mcPrintchar('.');
                b = 0;
            }
        }

        fl_fclose(file);
        unsigned int load_time = timer_stop(timer);
        unsigned int bytes     = loadptr - loadstartptr;

        if (c == EOF)
        {
            int sec           = load_time / 1000;
            int hundredth_sec = (load_time - (sec * 1000)) / 10;
            printf("\nLoaded %u bytes in %u.%02u sec.; ", bytes, sec, hundredth_sec);
#if ENABLE_LOAD_CRC32
            printf("CRC-32=");
            unsigned int crc = crc32b(0, loadstartptr, bytes);
            printf("0x%08X; ", crc);
#endif
            printf("Starting...\n\n");

            if (no_sd_boot)
            {
                disable_sd_boot();
            }

            __asm__ __volatile__("move.l %0,%%a0\n" : : "g"(loadstartptr));
            __asm__ __volatile__(" jmp (%%a0)\n" : : :);
            __builtin_unreachable();
        }
        else
        {
            printf("\n*** %s error at offset %u (0x%08x)\n",
                   (loadptr < endptr) ? ctrl_c_flag ? "^C" : "Read" : "Too large",
                   bytes,
                   bytes);
        }
    }
    else
    {
        printf("...open failed!\n\n");
    }
}

// change current dir (primitive)
static void change_dir(const char * name)
{
    // fake parent directory
    if (strcmp(name, "..") == 0)
    {
        if (current_dir[strlen(current_dir)] == '/')
        {
            current_dir[strlen(current_dir)] = '\0';
        }
        char * parent = strrchr(current_dir, '/');
        if (!parent)
        {
            parent = current_dir;
        }
        memset(parent, 0, sizeof(current_dir) - (parent - current_dir));
    }
    else
    {
        const char * filename = fullpath(name);
        if (!fl_is_dir(filename))
        {
            printf("*** Can't change dir to \"%s\"\n", filename);
        }
        else
        {
            strncpy(current_dir, filename + 1, sizeof(current_dir) - 1);        // skip leading '/'
        }
    }
}

// directory listing
static void dir_operation(const char * name)
{
    int          num_files = 0;
    int          num_dirs  = 0;
    unsigned int totalsize = 0;
    FL_DIR       dirstat;

    const char * filename = fullpath(name);
    printf("Directory: %s\n", filename);
    if (fl_opendir(filename, &dirstat))
    {
        struct fs_dir_ent dirent;

        while (fl_readdir(&dirstat, &dirent) == 0)
        {
            if (!dirent.is_dir)
            {
                printf("%10lu  %s\n", dirent.size, dirent.filename);
                unsigned int old_total = totalsize;        // clamp vs wrap
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

        printf("\n%d file%s, %d dir%s, total size %s%u bytes (%s)\n",
               num_files,
               num_files == 1 ? "" : "s",
               num_dirs,
               num_dirs == 1 ? "" : "s",
               totalsize == ~0U ? "> " : "",
               totalsize,
               friendly_size(totalsize));
    }
    else
    {
        printf("*** Can't dir \"%s\"\n", filename);
    }
}

// perform generic operation on a file via callback
static void file_operation(const char * name, int (*op_func)(char * p, int l))
{
    filesize    = 0;
    filecrc     = 0;
    ctrl_c_flag = false;

    const char * filename = fullpath(name);
    printf("\"%s\":\n", filename);

    void * file = fl_fopen(filename, "r");
    // if open failed, try again with padded 3 character extension
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
        while ((c = fl_fread(buffer, 1, sizeof(buffer), file)) > 0)
        {
            int rc = op_func(buffer, c);
            filesize += c;
            if (rc < 0)
            {
                break;
            }
        }

        fl_fclose(file);

        op_func(NULL, 0);

        if (c != EOF)
        {
            printf("\n*** %s error at offset %u (0x%08x)\n", ctrl_c_flag ? "^C" : " Read", filesize, filesize);
        }
    }
    else
    {
        printf("\n*** Can't open \"%s\"\n", filename);
    }

    printf("\n");
}

static void file_del(char * name)
{
    const char * filename = fullpath(name);
    printf("Delete \"%s\", are you sure? ", filename);
    char k = readchar();
    if (tolower(k) == 'y')
    {
        printf("yes\nDelete \"%s\"...", filename);
        int res = fl_remove(filename);
        printf("%s (%d)\n", res == 0 ? "OK" : "failed!", res);
    }
    else
    {
        printf("no\n");
    }
}

// type operation callback
static int op_type(char * p, int l)
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

        if (check_pause() < 0)
        {
            return -1;
        }
    }

    return check_pause();
}

// hex-dump operation callback
// NOTE: assumes l is always multiple of 16
static int op_dump(char * p, int l)
{
    if (l == 0)
    {
        return 0;
    }
    unsigned int off = filesize;
    uint8_t *    t   = (uint8_t *)p;
    uint8_t *    s   = t;
    while (l--)
    {
        if ((off & 0xf) == 0)
        {
            printf("%08x: ", off);
            s = t;
        }
        else if ((off & 0x7) == 0)
        {
            printf(" ");
        }
        printf("%02x ", *t++);
        if ((off & 0xf) == 0xf)
        {
            printf(" |");
            for (int a = 0; a < 16; a++)
            {
                printf("%c", s[a] < ' ' || s[a] > '~' ? '.' : s[a]);
            }
            printf("|\n");
            if (check_pause() < 0)
            {
                return -1;
            }
        }
        off++;
    }

    l = (off & 0xf);
    while ((off & 0xf) != 0x0)
    {
        if ((off & 0x7) == 0)
        {
            printf(" ");
        }
        printf("   ");
        if ((off & 0xf) == 0xf)
        {
            printf(" |");
            for (int a = 0; a < l; a++)
            {
                printf("%c", s[a] < ' ' || s[a] > '~' ? '.' : s[a]);
            }
            printf("\n");
        }
        off++;
    }

    return check_pause();
}

// crc operation callback
static int op_crc(char * p, int l)
{
    filecrc = crc32b(filecrc, p, l);
    if ((filesize & 0x3fff) == 0 || l == 0)
    {
        printf("\r%-4.4s", friendly_size(filesize));
    }

    return check_ctrlc();
}

// copy operation callback
static int op_copy(char * p, int l)
{
    if (l)
    {
        int res = fl_fwrite(p, 1, l, file2);
        if (res != l)
        {
            printf("*** Write error (%d vs %d) at offset %u (0x%08x)\n", res, l, filesize, filesize);
        }
    }
    if ((filesize & 0x3fff) == 0 || l == 0)
    {
        printf("\r%-4.4s", friendly_size(filesize));
    }

    return check_ctrlc();
}

// simple command prompt
enum
{
    CMD_DIR,
    CMD_CD,
    CMD_MKDIR,
    CMD_RUN,
    CMD_DEL,
    CMD_TYPE,
    CMD_DUMP,
    CMD_WRITE,
    CMD_CRC,
    CMD_COPY,
    CMD_BOOT,
    CMD_UPLOAD,
    CMD_EXIT,
    NUM_CMD
};

static struct
{
    const char * command;
    const char * alias;
    const char * help;
} cmd_table[NUM_CMD] = {[CMD_DIR]    = {"dir", "ls", "Directory listing"},
                        [CMD_CD]     = {"cd", NULL, "Change current dir"},
                        [CMD_MKDIR]  = {"mkdir", "md", "Make directory"},
                        [CMD_RUN]    = {"run", NULL, "Load and execute BIN file"},
                        [CMD_DEL]    = {"del", "rm", "Delete file"},
                        [CMD_TYPE]   = {"type", "cat", "Display ASCII file"},
                        [CMD_DUMP]   = {"dump", NULL, "Dump file in hex and ASCII"},
                        [CMD_WRITE]  = {"write", NULL, "Write/verify 512KB test file"},
                        [CMD_CRC]    = {"crc", NULL, "CRC-32 of file"},
                        [CMD_COPY]   = {"copy", "cp", "Copy file"},
                        [CMD_BOOT]   = {"boot", NULL, "Warm-boot"},
                        [CMD_UPLOAD] = {"upload", "/", "Warm-boot without SD card boot"},
                        [CMD_EXIT]   = {"exit", "x", "Exit to menu in current dir"}};

void command_prompt()
{
    printf("\nrosco_m68k: SD Card nano-shell prompt (built " __DATE__ " " __TIME__ ")\n\n");
    while (true)
    {
        check_sd_card();
        printf("%s> ", fullpath(""));
        prompt_readline(cmd_line, sizeof(cmd_line));

        // cmd string
        cmd_ptr = cmd_line;

        char * cmd = next_cmd_token();

        if (strlen(cmd) < 1)
        {
            continue;
        }

        int cmd_num;
        for (cmd_num = 0; cmd_num < NUM_CMD; cmd_num++)
        {
            if (strcasecmp(cmd, cmd_table[cmd_num].command) == 0 ||
                (cmd_table[cmd_num].alias != NULL && strcasecmp(cmd, cmd_table[cmd_num].alias) == 0))
            {
                break;
            }
        }

        char * arg  = next_cmd_token();
        char * arg2 = NULL;

        switch (cmd_num)
        {
            case CMD_DIR:
                dir_operation(arg);
                break;
            case CMD_CD:
                change_dir(arg);
                break;
            case CMD_DEL:
                file_del(arg);
                break;
            case CMD_MKDIR: {
                char * filename = fullpath(arg);
                printf(
                    "Create directory \"%s\"...%s\n", filename, fl_createdirectory(filename) == 1 ? "OK" : "failed!");
                break;
            }
            case CMD_RUN: {
                uint8_t * load_addr = (uint8_t *)_LOAD_ADDRESS;        // Default load address.
                arg2                = next_cmd_token();
                if (arg2 != NULL && arg2[0] != 0)
                {
                    load_addr = (uint8_t *)strtol(arg2, NULL, 16);        // Use load addr from cmd line.
                }
                execute_bin_file(arg, load_addr);
                break;
            }
            case CMD_TYPE:
                file_operation(arg, op_type);
                break;
            case CMD_DUMP:
                file_operation(arg, op_dump);
                break;
            case CMD_WRITE: {
                unsigned int crc      = 0;
                char *       filename = fullpath(arg);
                printf("Writing 512K test file \"%s\"...\n", filename);
                void * file = fl_fopen(filename, "w");
                if (file != NULL)
                {
                    filesize = 0;
                    while (filesize < (512 * 1024))
                    {
                        memset(buffer, filesize >> 9, sizeof(buffer));
                        crc   = crc32b(crc, buffer, sizeof(buffer));
                        int l = fl_fwrite(buffer, 1, sizeof(buffer), file);
                        if (l != sizeof(buffer))
                        {
                            printf("*** Error writing %d\n", l);
                            break;
                        }
                        filesize += sizeof(buffer);
                        if ((filesize & 0x3fff) == 0 || l == 0)
                        {
                            printf("\r%-4.4s", friendly_size(filesize));
                        }
                    }
                    fl_fclose(file);

                    printf("\nCRC=0x%08x, size %u (%s)\n", crc, filesize, friendly_size(filesize));
                }
                else
                {
                    printf("*** Can't create \"%s\"\n", filename);
                    break;
                }
                printf("Verify ");
                file_operation(arg, op_crc);
                printf("%10u bytes, CRC-32=0x%08X %s\n",
                       filesize,
                       filecrc,
                       filecrc == crc ? "VERIFIED" : "*** MISMATCH ***");
                break;
            }
            case CMD_CRC:
                file_operation(arg, op_crc);
                printf("%10u bytes, CRC-32=0x%08X\n", filesize, filecrc);
                break;
            case CMD_COPY:
                arg2  = fullpath(next_cmd_token());
                file2 = fl_fopen(arg2, "w");
                if (file2 != NULL)
                {
                    printf("Copying ");
                    file_operation(arg, op_copy);
                    fl_fclose(file2);

                    printf("%10u (0x%08x) bytes, copied.\n", filesize, filesize);
                }
                else
                {
                    printf("*** Can't create \"%s\"\n", arg2);
                }
                file2 = NULL;
                break;
            case CMD_BOOT:
                warm_boot(no_sd_boot);
                break;
            case CMD_UPLOAD:
                warm_boot(true);
                break;
            case CMD_EXIT:
                printf("\nExit to menu.\n");
                return;
            default:
                printf("SD Card prompt commands:\n");
                for (cmd_num = 0; cmd_num < NUM_CMD; cmd_num++)
                {
                    const char * cmd_arg = cmd_num == CMD_RUN   ? "<filename> [hex_load_addr]"
                                           : cmd_num < CMD_RUN  ? "[directory]"
                                           : cmd_num < CMD_COPY ? "<filename>"
                                           : cmd_num < CMD_BOOT ? "<src> <dest>"
                                                                : "";
                    printf(" %-8.8s %-27.27s %s", cmd_table[cmd_num].command, cmd_arg, cmd_table[cmd_num].help);
                    if (cmd_table[cmd_num].alias != NULL)
                    {
                        printf(" (alias %s)", cmd_table[cmd_num].alias);
                    }
                    printf("\n");
                }
        }
    }
}

// main SD Card Menu function
void sdfat_menu()
{
    printf("\nrosco_m68k [FW:%lX.%02lX%s]: SD Card Menu - (c) 2020 Xark, MIT License\n",
           (_FIRMWARE_REV >> 8) & 0xff,
           _FIRMWARE_REV & 0xff,
           _FIRMWARE_REV & (1 << 31) ? "*" : "");

    if (!SD_check_support())
    {
        printf("*** This program requires SD card support in firmware.\n");
        _WARM_BOOT();
    }

    // clear pending input character, if it was a 'k' pending, assume kermit wants to upload
    if (checkchar() && readchar() == 'k')
    {
        warm_boot(true);
    }

    bool reshow = false;

    while (true)
    {
        if (!reshow)
        {
            check_sd_card();

            get_menu_files();

            if (num_menu_files == 0 && num_dir_files == 0)
            {
                printf("\nNo menu files present.\n");
                command_prompt();
                continue;
            }
        }
        else
        {
            printf("\n\n\n");
        }
        reshow = false;

        int first_file = cur_page * 26;
        int file_count = first_file + 26 < num_menu_files ? 26 : num_menu_files - first_file;
        show_menu_files();

        printf("\n");
        if (num_menu_files > 0)
        {
            printf("A-%c to run, ", 'A' + file_count - 1);
        }
        if (num_dir_files > 0)
        {
            printf("0-%c for dir, ", '0' + num_dir_files - 1);
        }
        if (num_menu_pages > 1)
        {
            printf("<-> page, ");
        }
        printf("RETURN for prompt, ' ' to reload:");

        bool getnewkey;
        do
        {
            getnewkey   = false;
            char rawkey = readchar();
            char key    = toupper(rawkey);

            if (key == '\r')
            {
                printf("prompt\n");
                command_prompt();
                continue;
            }

            // check if user is "kermit" trying to upload...
            if (rawkey == 'k')
            {
                // loop on checkchar 10000 times (~1/4 second)
                for (int retry = 0; retry < 10000; retry++)
                {
                    if (checkchar())
                    {
                        rawkey = readchar();
                        if (rawkey == '\x01')        // ^A upload key
                        {
                            key = rawkey;
                            break;
                        }
                        retry = 0;
                    }
                }
            }

            if (key >= 'A' && key <= 'Z')
            {
                int run_num = (key - 'A');
                int half    = (file_count + 1) / 2;
                if (run_num >= half)
                {
                    run_num = ((run_num - half) * 2) + 1;
                }
                else
                {
                    run_num = run_num * 2;
                }

                run_num += first_file;

                if (run_num >= num_menu_files)
                {
                    mcPrintchar('\a');
                    getnewkey = true;
                    continue;
                }

                printf("%c\n", key);

                const char * n = menu_files[run_num];

                // if ends with 't', assume ".txt"
                if (tolower(n[strlen(n) - 1]) == 't')
                {
                    file_operation(n, op_type);

                    printf("Press any key:");
                    readchar();
                    printf("\n");
                }
                else
                {
                    execute_bin_file(n, (uint8_t *)_LOAD_ADDRESS);
                }
            }
            else if (key >= '0' && key <= '9')
            {
                int dir_num = (key - '0');
                int half    = (num_dir_files + 1) / 2;
                if (dir_num >= half)
                {
                    dir_num = ((dir_num - half) * 2) + 1;
                }
                else
                {
                    dir_num = dir_num * 2;
                }

                if (dir_num >= num_dir_files)
                {
                    mcPrintchar('\a');
                    getnewkey = true;
                    continue;
                }

                printf("%c\n", key);

                change_dir(dir_files[dir_num]);
            }
            else if (key == ',' || key == '<')
            {
                if (cur_page >= 1)
                {
                    cur_page -= 1;
                    reshow = true;
                    break;
                }
                else
                {
                    getnewkey = true;
                }
            }
            else if (key == '.' || key == '>')
            {
                if (cur_page + 1 < num_menu_pages)
                {
                    cur_page += 1;
                    reshow = true;
                    break;
                }
                else
                {
                    getnewkey = true;
                }
            }
            else if (key == '\\')
            {
                no_sd_boot = !no_sd_boot;
                printf("%s\n", no_sd_boot ? "no boot" : "SD boot");
            }
            else if (key == '/' || key == '\x01')        // ^a for kermit
            {
                printf("upload\n");
                warm_boot(true);
            }
            else if (key != ' ')
            {
                printf("exit\n");
                warm_boot(no_sd_boot);
            }
            else if (!getnewkey)
            {
                printf("reload\n");
            }
        } while (getnewkey);
    }
}

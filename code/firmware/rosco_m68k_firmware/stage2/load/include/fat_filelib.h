#ifndef __FAT_FILELIB_H__
#define __FAT_FILELIB_H__

#include "fat_opts.h"
#include "fat_access.h"
#include "fat_list.h"

//-----------------------------------------------------------------------------
// Defines
//-----------------------------------------------------------------------------
#ifndef SEEK_CUR
    #define SEEK_CUR    1
#endif

#ifndef SEEK_END
    #define SEEK_END    2
#endif

#ifndef SEEK_SET
    #define SEEK_SET    0
#endif

#ifndef EOF
    #define EOF         (-1)
#endif

#if FATFS_MINIMAL_API
#define FATFS_INC_WRITE_SUPPORT     0       // No write support in minimal API
#endif

//-----------------------------------------------------------------------------
// Structures
//-----------------------------------------------------------------------------
struct sFL_FILE;

struct cluster_lookup
{
    uint32 ClusterIdx;
    uint32 CurrentCluster;
};

typedef struct sFL_FILE
{
    uint32                  parentcluster;
    uint32                  startcluster;
    uint32                  bytenum;
    uint32                  filelength;
    int                     filelength_changed;
    char                    path[FATFS_MAX_LONG_FILENAME];
    char                    filename[FATFS_MAX_LONG_FILENAME];
    uint8                   shortfilename[11];

#ifdef FAT_CLUSTER_CACHE_ENTRIES
    uint32                  cluster_cache_idx[FAT_CLUSTER_CACHE_ENTRIES];
    uint32                  cluster_cache_data[FAT_CLUSTER_CACHE_ENTRIES];
#endif

    // Cluster Lookup
    struct cluster_lookup   last_fat_lookup;

    // Read/Write sector buffer
    uint8                   file_data_sector[FAT_SECTOR_SIZE];
    uint32                  file_data_address;
    int                     file_data_dirty;

    // File fopen flags
    uint8                   flags;
#define FILE_READ           (1 << 0)
#define FILE_WRITE          (1 << 1)
#define FILE_APPEND         (1 << 2)
#define FILE_BINARY         (1 << 3)
#define FILE_ERASE          (1 << 4)
#define FILE_CREATE         (1 << 5)

    struct fat_node         list_node;
} FL_FILE;

//-----------------------------------------------------------------------------
// Prototypes
//-----------------------------------------------------------------------------

// External
void                fl_init(void);
#if FATFS_INC_LOCKING
void                fl_attach_locks(void (*lock)(void), void (*unlock)(void));
#endif
int                 fl_attach_media(fn_diskio_read rd, fn_diskio_write wr);
#if FATFS_INC_WRITE_SUPPORT
void                fl_shutdown(void);      // This is a no-op if write isn't enabled
#endif

// Standard API
void*               fl_fopen(const char *path, const char *modifiers);
int                 fl_fread(void * data, int size, int count, void *file );
int                 fl_feof(void *f);
void                fl_fclose(void *file);

#if !FATFS_MINIMAL_API
int                 fl_fgetc(void *file);
char *              fl_fgets(char *s, int n, void *f);
int                 fl_fputc(int c, void *file);
int                 fl_fputs(const char * str, void *file);
int                 fl_fseek(void *file , long offset , int origin );
int                 fl_fgetpos(void *file , uint32 * position);
long                fl_ftell(void *f);

#if FATFS_INC_WRITE_SUPPORT
int                 fl_fwrite(const void * data, int size, int count, void *file );
int                 fl_fflush(void *file);
int                 fl_remove(const char * filename);
#endif

// Equivelant dirent.h
typedef struct fs_dir_list_status    FL_DIR;
typedef struct fs_dir_ent            fl_dirent;

FL_DIR*             fl_opendir(const char* path, FL_DIR *dir);
int                 fl_readdir(FL_DIR *dirls, fl_dirent *entry);
int                 fl_closedir(FL_DIR* dir);

// Extensions
void                fl_listdirectory(const char *path);
#if FATFS_INC_WRITE_SUPPORT
int                 fl_createdirectory(const char *path);
#endif
int                 fl_is_dir(const char *path);

#if FATFS_INC_FORMAT_SUPPORT
int                 fl_format(uint32 volume_sectors, const char *name);
#endif
#endif

// Test hooks
#ifdef FATFS_INC_TEST_HOOKS
struct fatfs*       fl_get_fs(void);
#endif

//-----------------------------------------------------------------------------
// Stdio file I/O names
//-----------------------------------------------------------------------------
#ifdef USE_FILELIB_STDIO_COMPAT_NAMES

#define FILE            FL_FILE

#define fopen(a,b)      fl_fopen(a, b)
#define fclose(a)       fl_fclose(a)
#define fread(a,b,c,d)  fl_fread(a, b, c, d)
#define feof(a)         fl_feof(a)

#if !FATFS_MINIMAL_API
#define fgetc(a)        fl_fgetc(a)
#define fgets(a,b,c)    fl_fgets(a, b, c)
#define fputc(a,b)      fl_fputc(a, b)
#define fputs(a,b)      fl_fputs(a, b)
#define fseek(a,b,c)    fl_fseek(a, b, c)
#define fgetpos(a,b)    fl_fgetpos(a, b)
#define ftell(a)        fl_ftell(a)
#if FATFS_INC_WRITE_SUPPORT
#define fflush(a)       fl_fflush(a)
#define fwrite(a,b,c,d) fl_fwrite(a, b, c, d)
#define remove(a)       fl_remove(a)
#define mkdir(a)        fl_createdirectory(a)
#define rmdir(a)        0
#endif

#endif
#endif

#endif

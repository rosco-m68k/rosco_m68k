### FAT16/32 File System Library

Github:   [http://github.com/ultraembedded/fat_io_lib](https://github.com/ultraembedded/fat_io_lib)

#### Intro

Designed for low memory embedded systems back in 2003, this project is a multi-purpose platform independent C code implementation of a FAT16 & FAT32 driver with read & write support.

The library provides stdio like interface functions such as fopen(), fgetc(), fputc(), fread(), fwrite() etc, allowing existing applications to be ported easily using a familiar API.  
The project is aimed at applications which require file system support such as MP3 players, data loggers, etc and has a low memory footprint with customizable build options to enable it to run on platforms such as the Atmel AVR, ARM & PIC microcontrollers.

The source code is available for free under GPL license, or alternatively, with a commercial compatible license for a small donation.

This library has been used in many open source projects including;
* Aleph - Open source sound computer.
* IV:MP - Grand Theft Auto: IV multiplayer game mod.
* hxcfloppyemu - HxC Floppy Drive Emulator.

#### Features

* Standard file I/O API (fopen(), fread(), fwrite(), etc)
* FAT16/FAT32 support (read + write)
* Long filename support (optional)
* Format function (optional)
* Directory listing (optional)
* Buffering & caching for higher performance (optional)

#### API

The following file IO API is provided:

* fopen
* fclose
* fread
* fwrite
* fputc
* fputs
* fgetc
* fflush
* fgetpos
* fseek
* ftell
* feof
* remove

Just add sector read & write functions for the media/platform you are using for a complete file system!

#### Testing

Each release of the project is tested using self verifying test benches to ensure validity and to protect against regressions (not currently released).

#### Commercial

If you would like to use this code in a commercial project with a closed source compatible license, please contact me.

#### Configuration
See the following defines in src/fat_opts.h:

```
FATFS_IS_LITTLE_ENDIAN 	[1/0]
  Which endian is your system? Set to 1 for little endian, 0 for big endian.

FATFS_MAX_LONG_FILENAME	[260]
  By default, 260 characters (max LFN length). Increase this to support greater path depths.

FATFS_MAX_OPEN_FILES 	
  The more files you wish to have concurrently open, the greater this number should be.
  This increases the number of FL_FILE file structures in the library, each of these is around 1K in size (assuming 512 byte sectors).

FAT_BUFFER_SECTORS
  Minimum is 1, more increases performance.
  This defines how many FAT sectors can be buffered per FAT_BUFFER entry.

FAT_BUFFERS
  Minimum is 1, more increases performance.
  This defines how many FAT buffer entries are available.
  Memory usage is FAT_BUFFERS * FAT_BUFFER_SECTORS * FAT_SECTOR_SIZE

FATFS_INC_WRITE_SUPPORT
  Support file write functionality.

FAT_SECTOR_SIZE
  Sector size used by buffers. Most likely to be 512 bytes (standard for ATA/IDE).

FAT_PRINTF
  A define that allows the File IO library to print to console/stdout. 
  Provide your own printf function if printf not available.

FAT_CLUSTER_CACHE_ENTRIES
  Size of cluster chain cache (can be undefined if not required).
  Mem used = FAT_CLUSTER_CACHE_ENTRIES * 4 * 2
  Improves access speed considerably.

FATFS_INC_LFN_SUPPORT 	[1/0]
  Enable/Disable support for long filenames.

FATFS_DIR_LIST_SUPPORT 	[1/0]
  Include support for directory listing.

FATFS_INC_TIME_DATE_SUPPORT  [1/0]
  Use time/date functions provided by time.h to update creation & modification timestamps.

FATFS_INC_FORMAT_SUPPORT
  Include support for formatting disks (FAT16 only).

FAT_PRINTF_NOINC_STDIO
  Disable use of printf & inclusion of stdio.h
```


#### Interfacing to storage media
```
-----------------------------------------------------------------
int media_read(uint32 sector, uint8 *buffer, uint32 sector_count)
-----------------------------------------------------------------
Params:
    Sector: 32-bit sector number
    Buffer: Target buffer to read n sectors of data into.
    Sector_count: Number of sectors to read

Return: 
    int, 1 = success, 0 = failure.

Description:
    Application/target specific disk/media read function.
    Sector number (sectors are usually 512 byte pages) to read.

-----------------------------------------------------------------
int media_write(uint32 sector, uint8 *buffer, uint32 sector_count)
-----------------------------------------------------------------

Params:
    Sector: 32-bit sector number
    Buffer: Target buffer to write n sectors of data from.
    Sector_count: Number of sectors to write.

Return: 
    int, 1 = success, 0 = failure.

Description:
    Application/target specific disk/media write function.
    Sector number (sectors are usually 512 byte pages) to write to.


-----------------------------------------------------------------
Use the following API to attach the media IO functions to the File IO library;

fl_attach_media(media_read, media_write);
```

#### History

* v2.6.11 - Fix compilation with GCC on 64-bit machines
* v2.6.10 - Added support for FAT32 format.
* v2.6.9 - Added support for time & date handling.
* v2.6.8 - Fixed error with FSINFO sector write.
* v2.6.7 - Added fgets(). Fixed C warnings, removed dependency on some string.h functions.
* v2.6.6 - Massive read + write performance  improvements.
* v2.6.5 - Bug fixes for big endian systems.
* v2.6.4 - Further bug fixes and performance improvements for write operations.
* v2.6.3 - Performance improvements, FAT16 formatting support. Various bug fixes
* v2.6 - Basic support for FAT16 added
* v2.5 - Code cleaned up. Many bugs fixed. Thread safety functions added.
* v2.x - Write support added as well as better stdio like API.
* v1.0 - Rewrite of all code to enable multiple files to be opened and provides a better file API.
* v0.1b - fopen(), fgetc(), fopenDIR() using new software stack for IDE drives and FAT32 access.
* v0.1a - First release; fopen(), fgetc() unbuffered reads.... (27/12/03)
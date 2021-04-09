/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v1
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Custom configuration for ultraembedded fat_io_lib
 * ------------------------------------------------------------
 */

// Standard stuff to exclude
#define FATFS_IS_LITTLE_ENDIAN          0
#define FATFS_INC_WRITE_SUPPORT         1
#define FATFS_INC_FORMAT_SUPPORT        1
#define FATFS_INC_TIME_DATE_SUPPORT     0
#define FATFS_INC_LFN_SUPPORT           1
#define FATFS_DIR_LIST_SUPPORT          1

// Standard options
#define FATFS_MAX_OPEN_FILES            16      /* 16KB */

// Lower-level but standard options
#define FAT_BUFFER_SECTORS              8
#define FAT_BUFFERS                     4       /* 16KB */
#define FAT_CLUSTER_CACHE_ENTRIES       128     /* 1KB */

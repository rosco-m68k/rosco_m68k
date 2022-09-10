/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Custom configuration for ultraembedded fat_io_lib
 * ------------------------------------------------------------
 */

// Don't do any output, thank you very much.
#define FAT_PRINTF(whatever)

// Standard stuff to exclude
#define FATFS_IS_LITTLE_ENDIAN          0
#define FATFS_INC_WRITE_SUPPORT         0
#define FATFS_INC_FORMAT_SUPPORT        0
#define FATFS_INC_TIME_DATE_SUPPORT     0
#define FATFS_INC_LFN_SUPPORT           0
#define FATFS_DIR_LIST_SUPPORT          0
#define FATFS_INC_FORMAT_SUPPORT        0

// Lower-level but standard options
#define FAT_CLUSTER_CACHE_ENTRIES       1

// Added by us
#define FATFS_INC_LOCKING               0
#define FATFS_INC_USELESS_STUFF         0
#define FATFS_MINIMAL_API               0
#define FATFS_INC_WRITE_SUPPORT         0


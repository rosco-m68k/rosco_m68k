/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2023 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Interface for loading programs from storage
 * ------------------------------------------------------------
 */

#ifndef __ROSCO_M68K_LOAD_H
#define __ROSCO_M68K_LOAD_H

#include <stdbool.h>
#include <rosco_m68k/part.h>
#include "system.h"

/*
 * This is what a Kernel entry point should look like.
 */
typedef void (*KMain)(volatile SystemDataBlock * const);

bool load_kernel(PartHandle *part);

#ifdef KERMIT_LOADER
// This is provided by Kermit
extern int receive_kernel();
#endif
#ifdef SDFAT_LOADER
// This is provided by the SD/FAT loader
extern bool sd_load_kernel();
#endif
#ifdef IDE_LOADER
// This is provided by the IDE/FAT loader
extern bool ide_load_kernel();
#endif
#ifdef ROMFS_LOADER
// This is provided by the ROMFS/FAT loader
extern bool romfs_load_kernel();
#endif

#endif  //__ROSCO_M68K_LOAD_H

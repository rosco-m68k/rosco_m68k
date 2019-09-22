/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2019 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Spinlocks!
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_SPINLOCK_H
#define _ROSCOM68K_SPINLOCK_H

#include <stdint.h>

typedef uint8_t Spinlock;

#define spinlock_acquire(lock) SPINLOCK_ACQUIRE_C(lock)
#define spinlock_release(lock) SPINLOCK_RELEASE_C(lock)

void SPINLOCK_ACQUIRE_C(Spinlock *lock);
void SPINLOCK_RELEASE_C(Spinlock *lock);

#endif


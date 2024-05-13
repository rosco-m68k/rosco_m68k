/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|            kernel
 * ------------------------------------------------------------
 * Copyright (c)2023 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Machine-related routines
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_KERNEL_MACHINE_H
#define _ROSCOM68K_KERNEL_MACHINE_H

#include <stdnoreturn.h>
#include <stdbool.h>

typedef bool        (*interrupt_service_f)(uint8_t, void*);

typedef struct {
    void*                   next;
    void*                   prev;
    void*                   data;
    interrupt_service_f     handler;    
} IrqHandler;

#ifdef ROSCO_M68K_KERNEL_BUILD
noreturn void halt(void);

noreturn void halt_and_catch_fire(void);

void disable_interrupts(void);

void enable_interrupts(void);

void irq_init(void);

void irq_register_c(uint8_t vec, IrqHandler *handler);

void irq_remove_c(IrqHandler *handler);

#endif//ROSCO_M68K_KERNEL_BUILD

#endif//_ROSCOM68K_KERNEL_MACHINE_H



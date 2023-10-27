/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|    kernel example
 * ------------------------------------------------------------
 * Copyright (c)2023 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * Example program for preemptive multitasking
 * ------------------------------------------------------------
 */
#include <stdint.h>
#include <stdio.h>
#include <stdnoreturn.h>
#include <machine.h>
#include <kernelapi.h>
#include <stdlib.h>

#define SYS_STACK_SIZE      0x800
#define USER_STACK_SIZE     0x1000

// Change these to test the different behaviours with schedule and signalling
#define TASK_1_PRIORITY     0x02
#define TASK_2_PRIORITY     0x02
#define TASK_3_PRIORITY     0x02

#define BUSYWAIT_NOPS       50000

// This isn't ideal, but works well enough for this test...
#define syncprintf(...)                     \
    do {                                    \
        Kernel->disable_interrupts();       \
        printf(__VA_ARGS__);                \
        Kernel->enable_interrupts();        \
    } while (0)

static uint32_t tinit_stack;
static uint32_t tidle_stack;

extern void* _end;

// "User" task structs for playing with
static Task *t1;
static uint32_t t1_stack;
static Task *t2;
static uint32_t t2_stack;
static Task *t3;
static uint32_t t3_stack;

IKernel *Kernel;

#ifdef DEBUG
#define dump_task(t)    debug_dump_task(t)
#else
#define dump_task(t)
#endif

void debug_dump_task(Task *t) {
    syncprintf("t           @ 0x%08lx\n", (uint32_t)t);
    syncprintf(" -> stack   @ 0x%08lx\n", (uint32_t)t->stack_addr);
    syncprintf(" -> tid     @ 0x%08lx\n", (uint32_t)t->tid);
    syncprintf(" -> sig_w   @ 0x%08lx\n", (uint32_t)t->sig_wait);
    syncprintf(" -> ssize   @ 0x%08lx\n", (uint32_t)t->stack_size);
    syncprintf(" -> sbott   @ 0x%08lx\n", (uint32_t)t->stack_bottom);
    syncprintf(" -> prio    @ 0x%08lx\n", (uint32_t)t->priority);
}

/////////////////////////////////////////////
// "User" tasks
//
// Just some noisy tasks to play around with...
//
static void task1(void) {
    dump_task(Kernel->task_current());

    syncprintf("[1] starts, and sleeps on signal 0x04...\n");
    uint32_t sigs = Kernel->task_wait(0x04);

    syncprintf("[1] (%ld) awakened by signals 0x%08lx\n", Kernel->task_current()->tid, sigs);
    for (int i = 0; i < 3; i++) {
        syncprintf("[1] (%ld) - num is %d\n", Kernel->task_current()->tid, i);
        mcBusywait(BUSYWAIT_NOPS);
    }
}

static void task3(void);

static void task2() {
    for (int i = 0; i < 10; i++) {
        dump_task(Kernel->task_current());
        syncprintf("[2] (%ld) - num is %d\n", Kernel->task_current()->tid, i);

        if (i == 2) {
            syncprintf("[2]   Sending incorrect signals to task 1 - should not wake\n");
            Kernel->task_signal(t1, 0x01);
        } else if (i == 4) {
            syncprintf("[2]   Waking task 1!\n");
            Kernel->task_signal(t1, 0x24);
        } else if (i == 8) {
            syncprintf("[2]   Waking task 3!\n");
            Kernel->task_signal(t3, 0x01);
        } else {
            if (i == 3) {
                syncprintf("[2]   Scheduling task 3!\n");

                t3 = (Task*)Kernel->alloc_sys_object(TASK_SLAB_BLOCKS);
                t3_stack = Kernel->mem_alloc(USER_STACK_SIZE);

                if (t3 == NULL || t3_stack == 0) {
                    syncprintf("[2] Failed to allocate memory for task 3\n");
                    mcHalt();
                }

                Kernel->task_init(t3, 0x03, TASK_3_PRIORITY);
                Kernel->task_schedule(t3, t3_stack, USER_STACK_SIZE, task3);
            }
        }
        mcBusywait(BUSYWAIT_NOPS);
    }
}

static void task3(void) {
    for (int i = 0; i < 4; i++) {
        syncprintf("[3] (%ld) - num is %d\n", Kernel->task_current()->tid, i);

        if (i == 1) {
            syncprintf("[3]  => Sleeping for signal 0x1\n");
            uint32_t signals = Kernel->task_wait(0x01);
            syncprintf("[3]  => Task 3 awoken by signals 0x%08lx\n", signals);
        } else if (i == 2) {
            syncprintf("[3]  => Sleeping for signal 0x2\n");
            uint32_t signals = Kernel->task_wait(0x02);
            syncprintf("[3]  => Task 3 awoken by signals 0x%08lx\n", signals);
        }
        
        mcBusywait(BUSYWAIT_NOPS);
    }
}

/////////////////////////////////////////////
// System tasks
//
// Idle just wastes some time - it will be automatically scheduled
// only when nothing else is runnable.
//
// (At least, normally that's what it would do - here it's doing
// various things, just to test that it actually can...)
//
static void idle(void) {
    int i = 0;
    while (1) {

        syncprintf("[%ld] <idle>\n", Kernel->task_current()->tid);

        if (i++ == 10) {
            syncprintf("  Signalling task 3 with 0x02\n");
            Kernel->task_signal(t3, 0x02);
        } else if (i == 15) {
            syncprintf("Stopping machine\n");

            __asm__ volatile (
                "stop   #0x2700\n\t"
            );
        } else {
            __asm__ volatile (
                "stop   #0x2000\n\t"
            );
        }

#       ifndef INSTANT_IDLE
        mcBusywait(BUSYWAIT_NOPS);        
#       endif
    }
}

// Init is the first task that gets kicked off. It just schedules other tasks
// (which would be from a dynamic list or something in the real world) and then
// exits.
//
static void init(void) {
    // initialize things
    syncprintf("Init task: Schedule initial tasks\n");
    
    Kernel->task_schedule(t2, t2_stack, USER_STACK_SIZE, task2);
    Kernel->task_schedule(t1, t1_stack, USER_STACK_SIZE, task1);
}
 

// Just sets up the system tasks, plus a few tasks to play with...
//
static void set_up_tasks(void) {
    // Stacks for sys tasks
    syncprintf("Set up tasks\n");
    tinit_stack = Kernel->mem_alloc(SYS_STACK_SIZE);
    tidle_stack = Kernel->mem_alloc(SYS_STACK_SIZE);

    syncprintf("  ==> Allocate stuff...\n");
    // Toy tasks, scheduled by init
    t1 = (Task*)Kernel->alloc_sys_object(TASK_SLAB_BLOCKS);
    t1_stack = Kernel->mem_alloc(USER_STACK_SIZE);    

    if (t1 == NULL || t1_stack == 0) {
        syncprintf("  ==! Failed to allocate memory for task 1\n");
        mcHalt();
    }

    syncprintf("  ==> t1 is at 0x%08lx\n", (uint32_t)t1);

    Kernel->task_init(t1, 0x01, TASK_1_PRIORITY);

    t2 = (Task*)Kernel->alloc_sys_object(TASK_SLAB_BLOCKS);
    t2_stack = Kernel->mem_alloc(USER_STACK_SIZE);

    if (t2 == NULL || t2_stack == 0) {
        syncprintf("  ==! Failed to allocate memory for task 2\n");
        mcHalt();
    }

    syncprintf("  ==> t2 is at 0x%08lx\n", (uint32_t)t2);

    Kernel->task_init(t2, 0x02, TASK_2_PRIORITY);

    syncprintf("  <== Tasks are initialized...\n");

    // t3 struct and stack are allocated on the fly by t2...
}

// Give the PMM some memory to work with - ultimately this would
// be handled in ROM, but for now it's the program's responsibility...
static void init_pmm() {
    uint32_t free_start = (uint32_t)&_end;
    uint32_t free_aligned = free_start & 0xfffff000;

    // Ensure aligned
    if (free_aligned < free_start) {
        free_aligned = free_aligned + 1024;
    }

    // Need at least a 1KiB block
    if (free_aligned >= 0xefc00) {
        printf("Out of memory\n");
        abort();
    }

    Kernel->mem_free(free_aligned, 0xf0000);
}

noreturn void kmain() {
    Kernel = get_kernel_api();

    init_pmm();
    set_up_tasks();

    printf("tinit_stack @ 0x%08lx\n", (uint32_t)tinit_stack);
    printf("tidle_stack @ 0x%08lx\n", (uint32_t)tidle_stack);

    dump_task(t1);
    dump_task(t2);

    Kernel->start(tinit_stack, SYS_STACK_SIZE, init, tidle_stack, SYS_STACK_SIZE, idle);
    __builtin_unreachable();
}


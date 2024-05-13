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
 * C structs & prototypes for multitasking.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_KERNEL_TASK_H
#define _ROSCOM68K_KERNEL_TASK_H

#include <stdint.h>
#include <stdnoreturn.h>

#include "list.h"

typedef uint32_t signals_t;

typedef uint32_t tid_t;

typedef void (*task_handler_f)(void);

typedef uint8_t priority_t;

/**
 * A task is an individual thread of execution.
 * 
 */
typedef struct {
    struct _ListNode        node;
    uint32_t                stack_addr;
    tid_t                   tid;
    signals_t               sig_wait;
    uint32_t                stack_size;
    uint32_t                stack_bottom;
    priority_t              priority;
    uint8_t                 pad[3];
} Task;

#ifdef ROSCO_M68K_KERNEL_BUILD
/**
 * Initialise the task subsystem.
 *
 * Must be called before any of the other task functions.
 */
void task_init(void);

/**
 * Generic type for ListNodes that are Tasks.
 * 
 */
#define NODE_TYPE_TASK      0x100

/**
 * Number of slab slots required by a Task structure.
 * 
 */
#define TASK_SLAB_BLOCKS    2

/**
 * Start the tasking subsystem with the given init task.
 * 
 * The expectation is that the init task will kick off whatever
 * else it needs to, and then either exit, or become the idle
 * task...
 * 
 * The init task _should not_ disable or enable interrupts, 
 * or do anything odd. It will be entered with interrupts 
 * disabled and a carefully-crafted stack below its return
 * address, don't mess with that.
 * 
 * You must provide an idle task as part of this, which will be
 * scheduled whenever there's nothing else to do. The rules for
 * this task are:
 * 
 *   * You do not talk about the idle task
 *   * YOU DO NOT TALK ABOUT THE IDLE TASK
 *   * It **must** always be runnable - i.e. must not signal / wait etc
 *   * It **must not** return, or otherwise exit
 * 
 * Does not return.
 * 
 * @param init_stack The address of the stack (bottom) for the init task
 * @param init_stack_size Size of the init stack in bytes
 * @param init_task The init task entrypoint
 * @param idle_stack The address of the stack (bottom) for the idle task
 * @param idle_stack_size Size of the idle stack in bytes
 * @param idle_task The idle task entrypoint
 */
noreturn void start_tasking(
    uintptr_t init_stack,
    size_t init_stack_size,
    task_handler_f init_task,
    uintptr_t idle_stack,
    size_t idle_stack_size,
    task_handler_f idle_task
);

/**
 * Initialise a new Task struct. Just clears it out and sets the PID.
 * 
 * @param task The Task struct
 * @param pid The PID you desire
 * @param priority Priority for the new task (0..3)
 */
void task_new(Task *task, tid_t tid, priority_t priority);

/**
 * Schedule a new task. It will be run next.
 * 
 * @param task The Task to schedule
 * @param stack_addr The address of the stack (bottom)
 * @param stack_size The size of the stack in bytes
 * @param entrypoint The entrypoint for this task
 */
void task_schedule(Task *task, uintptr_t stack_addr, size_t stack_size, task_handler_f entrypoint);

/**
 * Get the currently-running Task struct.
 * 
 * @return Task* The current Task
 */
Task* task_current(void);

/**
 * Increasingly inaptly-named "schedule next task" function.
 * 
 * Finds the next task to run, and sets everything up in readiness for
 * it. Switches into the tasks context, but the actual return to the 
 * task's code is done later by the rte at the end of the tick 
 * handler.
 * 
 * (I did mention you can currently only call this from the tick 
 * handler, right?)
 */
void task_yield(void);

/**
 * Suspend the current task until one or more of the
 * given signals are received.
 * 
 * @param sig_mask The mask of signals to wait for
 * @return uint32_t The mask of signals that were actually received
 */
uint32_t task_wait(uint32_t sig_mask);

/**
 * Send the given signal(s) to the given task.
 * 
 * Currently, if the given task is not waiting for any of the
 * given signals, nothing will happen (i.e. this does not 
 * function as a generic "interrupt" mechanism right now).
 * 
 * @param task The task to signal
 * @param sig_mask The mask of signals to send.
 */
void task_signal(Task *task, uint32_t sig_mask);


#ifdef DEBUG_SCHED
#   include <stdio.h>
#   define debugf(...)              printf(__VA_ARGS__)
#   define debug_task(...)          debug_print_task(__VA_ARGS__)
#   define debug_current_task(...)  debug_print_task_current()
    void debug_print_task(Task *current);
    void debug_print_task_current(void);
#   ifdef TRACE_SCHED
#       define tracef(...)          printf(__VA_ARGS__)
#       define trace_tasks(...)     debug_trace_tasks()
#       define trace_switch(...)    debug_trace_task_switch()
        void debug_trace_tasks();
        void debug_trace_task_switch();
#   else
#       define tracef(...)
#       define trace_tasks(...)
#       define trace_switch(...)
#   endif
#else
#   define debugf(...)
#   define debug_task(...)
#   define debug_current_task(...)
#   define tracef(...)
#   define trace_tasks(...)
#   define trace_switch(...)
#endif

#endif//ROSCO_M68K_KERNEL_BUILD

#endif//_ROSCOM68K_KERNEL_TASK_H

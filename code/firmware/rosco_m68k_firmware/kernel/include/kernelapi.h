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
 * Core kernel public API
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_KERNEL_API_H
#define _ROSCOM68K_KERNEL_API_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include "list.h"
#include "task.h"
#include "kmachine.h"

#define KERNEL_API_ADDRESS      0x400

typedef uintptr_t   (*mem_alloc_f)(size_t);
typedef void        (*mem_free_f)(uintptr_t, size_t);

typedef void*       (*alloc_sys_object_f)(uint8_t);
typedef void        (*free_sys_object_f)(void*, uint8_t);

typedef Task*       (*task_current_f)(void);
typedef void        (*task_init_f)(Task*, tid_t, priority_t);
typedef void        (*task_schedule_f)(Task*, uintptr_t, uintptr_t, task_handler_f);

typedef signals_t   (*task_wait_f)(signals_t);
typedef void        (*task_signal_f)(Task*, signals_t);

typedef void        (*enable_interrupts_f)(void);
typedef void        (*disable_interrupts_f)(void);

typedef void        (*register_irq_f)(uint8_t, IrqHandler*);
typedef void        (*remove_irq_f)(IrqHandler*);

typedef List*       (*list_init_f)(List*);
typedef ListNode*   (*list_add_head_f)(List*, ListNode*);
typedef ListNode*   (*list_delete_head_f)(List*);
typedef ListNode*   (*list_add_tail_f)(List*, ListNode*);
typedef ListNode*   (*list_delete_tail_f)(List*);
typedef ListNode*   (*list_node_insert_after_f)(ListNode*, ListNode*);
typedef ListNode*   (*list_node_delete_f)(ListNode*);

// This is not here long term, it's a hack to get us started...
typedef void (*start_f)(
    uintptr_t init_stack,
    size_t init_stack_size,
    task_handler_f init_task,
    uintptr_t idle_stack,
    size_t idle_stack_size,
    task_handler_f idle_task
);

typedef struct {
    // Memory management
    mem_alloc_f                 mem_alloc;
    mem_free_f                  mem_free;

    alloc_sys_object_f          alloc_sys_object;
    free_sys_object_f           free_sys_object;

    // Multitasking
    task_current_f              task_current;
    task_init_f                 task_init;
    task_schedule_f             task_schedule;

    // Signals / IPC
    task_wait_f                 task_wait;
    task_signal_f               task_signal;

    // Interrupts
    enable_interrupts_f         enable_interrupts;
    disable_interrupts_f        disable_interrupts;
    register_irq_f              register_irq;
    remove_irq_f                remove_irq;

    // Linked lists
    list_init_f                 list_init;
    list_add_head_f             list_add_head;
    list_delete_head_f          list_delete_head;
    list_add_tail_f             list_add_tail;
    list_delete_tail_f          list_delete_tail;
    list_node_insert_after_f    list_insert_after;
    list_node_delete_f          list_delete;

    // start doing the thing
    start_f                     start;
} IKernel;

static inline IKernel* get_kernel_api() {
    return *(IKernel**)KERNEL_API_ADDRESS;
}

#ifdef ROSCO_M68K_KERNEL_BUILD
void api_init(void);
#endif//ROSCO_M68K_KERNEL_BUILD

#endif//_ROSCOM68K_KERNEL_API_H



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
 * Kernel public API
 * ------------------------------------------------------------
 */

#ifndef _ROSCOM68K_KERNEL_API_H
#define _ROSCOM68K_KERNEL_API_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#define KERNEL_API_ADDRESS      0x400

/**
 * Number of slab slots required by a Task structure.
 * 
 */
#define TASK_SLAB_BLOCKS    2

/**
 * A ListNode is the basic structure for, well, a list node.
 */
typedef volatile struct _ListNode {
    struct _ListNode*       next;
    struct _ListNode*       prev;
    uint32_t                size;       // N.B the list implementation **must** not
    uint32_t                type;       // use these - they are for users of the nodes!
} ListNode;

/**
 * A List is a double-ended list header, for efficient operations
 * at either end.
 * 
 * The layout is slightly odd - it's modelled after Amiga Exec
 * lists, and uses a similar optimisation - the header is actually
 * two overlapping nodes, representing the (logical) head and tail of
 * the list.
 */
typedef volatile struct {
    ListNode*                   head;
    ListNode*                   tail;
    ListNode*                   tprev;
} List;

typedef uint32_t signals_t;

typedef uint32_t tid_t;

typedef void (*task_handler_f)(void);

typedef uint8_t priority_t;

/**
 * A task is an individual thread of execution.
 * 
 */
typedef struct {
    struct _ListNode            node;
    uint32_t                    stack_addr;
    tid_t                       tid;
    signals_t                   sig_wait;
    uint32_t                    stack_size;
    uint32_t                    stack_bottom;
    priority_t                  priority;
    uint8_t                     pad[3];
} Task;

typedef bool        (*interrupt_service_f)(uint8_t, void*);

typedef struct {
    void*                       next;
    void*                       prev;
    void*                       data;
    interrupt_service_f         handler;    
} IrqHandler;

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
    IKernel *result = *(IKernel**)KERNEL_API_ADDRESS;
    if (result == (IKernel*)0xb105d47a) {
        // No kernel in ROM
        return NULL;
    } else {
        return result;
    }
}

static inline IKernel* ensure_kernel_api() {
    void mcPrintln(char *str);
    void abort(void);

    IKernel *result = *(IKernel**)KERNEL_API_ADDRESS;
    if (result == (IKernel*)0xb105d47a) {
        // No kernel in ROM
        mcPrintln("PANIC: No ROM kernel available");
        abort();

        __builtin_unreachable();
    }

    return result;
}

#endif//_ROSCOM68K_KERNEL_API_H



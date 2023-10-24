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
 * Example program for preemptive multitasking
 * ------------------------------------------------------------
 */

#include "kernelapi.h"

#include "list.h"
#include "pmm.h"
#include "slab.h"
#include "task.h"
#include "kmachine.h"

IKernel api;

void api_init() {
    api.mem_alloc = pmm_alloc;
    api.mem_free = pmm_free;
    api.alloc_sys_object = slab_alloc_c;
    api.free_sys_object = slab_free_c;
    api.task_current = task_current;
    api.task_init = task_new;
    api.task_schedule = task_schedule;
    api.task_signal = task_signal;
    api.task_wait = task_wait;
    api.enable_interrupts = enable_interrupts;
    api.disable_interrupts = disable_interrupts;
    api.register_irq = irq_register_c;
    api.remove_irq = irq_remove_c;
    api.list_init = list_init_c;
    api.list_add_head = list_add_head_c;
    api.list_delete_head = list_delete_head_c;
    api.list_add_tail = list_add_tail_c;
    api.list_delete_tail = list_delete_tail_c;
    api.list_insert_after = list_node_insert_after_c;
    api.list_delete = list_node_delete_c;
    api.start = start_tasking;

    IKernel** ptr = (IKernel**)KERNEL_API_ADDRESS;
    *ptr = &api;
}
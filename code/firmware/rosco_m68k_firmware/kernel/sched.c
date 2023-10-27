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
 * C bits of the multitasking stuff
 * ------------------------------------------------------------
 */
#include <stdint.h>
#include <stdnoreturn.h>
#include <stddef.h>

#include "machine.h"
#include "pmm.h"
#include "slab.h"
#include "kmachine.h"
#include "list.h"
#include "task.h"

Task tidle;
static Task *tinit;

extern List runnable_list_3;
extern List runnable_list_2;
extern List runnable_list_1;
extern List runnable_list_0;

extern List sleeping_list;
extern Task *current_task_var;

// Internal API - set up a task to be runnable (just makes the stack right)
//
void task_tee(
    Task *task, 
    uintptr_t stack_addr, 
    task_handler_f entryhandler, 
    task_handler_f entrypoint, 
    task_handler_f exithandler
);

// Internal API - Kick off the tee'd-up init task to get the show on the road
//
noreturn void task_kick_off(Task *init);

// These trampolines are weird, and coupled to task_tee. 
// See the comments in task.asm for a full explanation.
//
void task_trampoline(void);
void init_trampoline(void);
void idle_trampoline(void);

void task_new(Task *task, tid_t tid, priority_t priority) {
    task->node.next = NULL;
    task->node.prev = NULL;
    task->node.type = NODE_TYPE_TASK;
    task->node.size = sizeof(Task);
    task->priority = priority & 3;
    task->tid = tid;
}

// This gets set up as the return for tasks. It's responsible for
// cleaning up tasks resources, and removing them from the list,
// if they return.
//
static noreturn void task_done(void) {
    Task *this = task_current();

    current_task_var = NULL;

    // Disable interrupts for a sec, since we're doing some slightly iffy 
    // memory ordering (freeing our stack, then using it for one call to free the task).
    disable_interrupts();
    pmm_free(this->stack_bottom, this->stack_size);
    slab_free_c(this, TASK_SLAB_BLOCKS);
    enable_interrupts();

    // Do this as a jump to stop the compiler pushing a return address to the
    // stack we freed 👆
    __asm__ volatile (
        "jmp    task_yield\n\t"
    );

    __builtin_unreachable();
}

// This gets set up as a last-resort exit handler for the idle task.
// It just panics and stops the world.
static void panic_idle_done(void) {
    FW_PRINT_C("\033[1;31;41mPANIC:\033[1;31;40m Idle task is exiting; Halting.\033[0m\n\n");
    halt_and_catch_fire();
}

// Public API: Schedule a new task
void task_schedule(Task *task, uintptr_t stack_addr, size_t stack_size, task_handler_f entrypoint) {
    debugf("Schedule: 0x%08x", task);
    task->stack_size = stack_size;
    task->stack_bottom = stack_addr;
    task_tee(task, stack_addr + stack_size, task_trampoline, entrypoint, task_done);

    uint8_t priority = task->priority & 3;
    List *target_list;
    if (priority == 3) {
        target_list = &runnable_list_3;
    } else if (priority == 2) {
        target_list = &runnable_list_2;
    } else if (priority == 1) {
        target_list = &runnable_list_1;
    } else {
        target_list = &runnable_list_0;
    }

    disable_interrupts();
    list_add_head_c(target_list, (ListNode*)task);
    enable_interrupts();

    debug_task(task);
}

// Set up the init task
//
static void setup_init_task(Task *task, tid_t tid) {
    task->node.type = NODE_TYPE_TASK;
    task->node.size = sizeof(Task);
    task->tid = tid;
    task->priority = 4;
}

// Set up the idle task
//
static void setup_idle_task(Task *task, tid_t tid) {
    task->node.type = NODE_TYPE_TASK;
    task->node.size = sizeof(Task);
    task->tid = tid;
    task->priority = 0;
}

noreturn void start_tasking(
    uintptr_t init_stack,
    size_t init_stack_size,
    task_handler_f init_task,
    uintptr_t idle_stack,
    size_t idle_stack_size,
    task_handler_f idle_task
) {
    debugf("Set up init task...\n");
    tinit = (Task*)pmm_alloc(sizeof(Task));
    setup_init_task(tinit, 0);
    tinit->stack_size = init_stack_size;
    tinit->stack_bottom = init_stack;
    task_tee(tinit, init_stack + init_stack_size, init_trampoline, init_task, task_done);

    tracef("Set up idle task...\n");
    setup_idle_task(&tidle, 0xff);
    tidle.stack_size = idle_stack_size;
    tidle.stack_bottom = idle_stack;
    task_tee(&tidle, idle_stack + idle_stack_size, idle_trampoline, idle_task, panic_idle_done);

    tracef("Init @ 0x%08x, stack: 0x%08x\n", tinit, tinit->stack_addr);
    tracef("Idle @ 0x%08x, stack: 0x%08x\n", &tidle, tidle.stack_addr);

    debugf("Kicking off...\n");    
    task_kick_off(tinit);
}

#ifdef DEBUG_SCHED
uint32_t volatile *upticks = (uint32_t*)0x40c;
#ifdef TRACE_SCHED
// Just print the task list for debugging
void debug_trace_tasks() {
    // runnable list
    tracef("    RUNNABLE [tail @ 0x%08x]: ", &runnable_list.tail);
    for (Task *current = (Task*)runnable_list.head; current != (Task*)&runnable_list.tail; current = (Task*)current->node.next) {
        tracef("0x%08x[0x%08x]:(%3d) -> ", (uint32_t)current, current->node.next, current->tid);
    }
    tracef("\n    SLEEPING [tail @ 0x%08x]: ", &runnable_list.tail);
    // sleeping list
    for (Task *current = (Task*)sleeping_list.head; current != (Task*)&sleeping_list.tail; current = (Task*)current->node.next) {
        tracef("0x%08x:(%3d) -> ", (uint32_t)current, current->tid);
    }
    tracef("\n");
}

void debug_trace_task_switch() {
    tracef("SWITCH TRACE:\n");
    debug_trace_tasks();
}
#endif

// Just print some info about the given task for debugging
void debug_print_task(Task *current) {
    debugf("    => PID %d : stack at 0x%08x\n", current->tid, current->stack_addr + 4);
}

// Just print some info about the current task for debugging
void debug_print_task_current(void) {
    debug_print_task(task_current());
}
#endif

#ifdef DEBUG_INTEN
void report_enable(volatile uint16_t num, uint32_t ret_addr) {
    debugf("    <%d> [%d:0x%08x] -> ENA_INTR: 0x%04x [from 0x%08x]", *upticks, task_current()->tid, task_current(), num, ret_addr);
}

void report_disable(volatile uint16_t num, uint32_t ret_addr) {
    debugf("    <%d> [%d:0x%08x] -> DIS_INTR: 0x%04x [from 0x%08x]", *upticks, task_current()->tid, task_current(), num, ret_addr);
}
void report_enable2(volatile uint16_t num) {
    debugf("    <%d> => 0x%04x\n", *upticks, num);
}

void report_disable2(volatile uint16_t num) {
    debugf("    <%d> => 0x%04x\n", *upticks, num);
}

void report_enabled() {
    debugf(" [ENABLED]  ");
}

void report_disabled() {
    debugf(" [DISABLED] ");
}
#endif

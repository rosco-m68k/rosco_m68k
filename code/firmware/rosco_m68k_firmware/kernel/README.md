## ROM kernel for rosco_m68k

You need https://github.com/roscopeco/r68k installed if you want
to run on your modern machine. You can also upload the binaries
to your rosco_m68k (or put them on your SD) if you like.

By default, r68k is expected to be in `../../../../tools/r68k` - you can change
this with `R68K_DIR`, e.g. `R68K_DIR=/whatever make ...`.

```shell
make clean test
```

The kernel itself is built as part of the main ROM build, but you
can build just the static library in this directory if you want:

```shell
make clean all
```

You can change the defines in the Makefile to see more debugging info:

* `-DDEBUG_PMM` - See memory manager debugging output (noisy)
* `-DDEBUG_SCHED` - See scheduler debugging output (noisy)
    * `-DTRACE_SCHED` - See scheduler trace output (very noisy)
* `-DEEBUG_INTEN` - Debug interrupt enable / disable (extremely noisy)


### Memory Management

Obviously with no MMU there is no virtual memory, and no memory protection.
The kernel implements two interfaces for memory managament - an optimised
low-overhead free-list based coalescing first-fit physical allocator with 
a block size of 1KiB, and a simple bitmap-based slab allocator layered
on top, which automatically manages 1KiB slabs, with a fixed block size
of 32-bytes.

The slab allocator is primarily intended for system structures, and does
support allocation/free of multiple contiguous blocks from a given slab
where a struct needs more than 32-bytes.

The intention is that user code would directly use neither of these - 
instead, the physical allocator would supply blocks that would then be
managed by some library `malloc` implementation. 

They are both exposed via the `IKernel` API, however, so can be used.

In order for everything to work nicely, all memory management must 
(ultimately) go through the pmm, or the system won't be able to track
what memory is in use vs not, and sadness will most likely ensue.


### Scheduling

The scheduler here is a pre-emptive, priority-based round robin, with four
priority levels (0 = lowest, 3 = highest).

The scheduler is run once per quantum, driven from the 100Hz system timer,
so it'll run 100 times per second, adjusted by the divisor in the 
`QUANTUM_TICKS` variable in `task.asm`. We'll want to play around with
this to find a value that works well in the general case (and can make 
it configurable if we like). 

In testing so far the scheduler is quite capable of 100 switches a second,
without swamping the system - however, it might not be best for performance,
we might want to take a (small) hit on latency to trade off for raw perf.

Obviously once interrupt sources and devices are implemented, that'll also 
change the complexion of that tradeoff - so we can revisit regularly 
as dev progresses.

The priority rules are:

* A runnable process of a given priority will only be given time if no 
  higher-priority process is runnable
* A newly-scheduled process will **never** preempt the scheduling process
* A newly-scheduled process will **always** be scheduled next, _within_
  _it's priority group_
* Where a newly-scheduled process has the same priority, or higher priority
  than the scheduling process, it will **always** run on the next schedule
* A sleeping process, when woken, will **always** preempt the running 
  process _on the next timeslice_, _if it has the same or higher priority_.

### Initialisation

To initialize the kernel, you'll need to call a few things. This is the 
recommended order for doing so:

```c
    /* Initialise the API pointers */
    api_init();
    Kernel = get_kernel_api();

    /* Initialise the PMM. The free should be changed to cover your chosen managed memory region */
    pmm_init();
    pmm_free(0x20000, 0x30000);
    
    /* Initalise the slab allocator */
    slab_init();
    
    /* Initialise IRQs */
    irq_init();

    /* Initialise the multitasking system */
    task_init();

    /* Start the multitasking system. This never returns */
    start_tasking(tinit_stack, SYS_STACK_SIZE, init, tidle_stack, SYS_STACK_SIZE, idle);
```

To set up tasks, the following general pattern is recommended:

```c
    Task* t1 = (Task*)Kernel->alloc_sys_object(TASK_SLAB_BLOCKS);
    uint32_t t1_stack = Kernel->mem_alloc(USER_STACK_SIZE);    

    if (t1 == NULL || t1_stack == 0) {
        syncprintf("  ==! Failed to allocate memory for task\n");
        halt_and_catch_fire();
    }

    Kernel->task_init(t1, 0x01, TASK_1_PRIORITY);
```

This would later be scheduled (e.g. by your `init` task):

```c
    Kernel->task_schedule(t1, t1_stack, USER_STACK_SIZE, task1_function);
```

### Kernel API

All access to the Kernel API should be done through an `IKernel` pointer,
which can be obtained with the `get_kernel_api` function in `kernelapi.h`.

This provides the following functions. Take note of those marked as 
"not interrupt safe" - these **must** not be called from interrupt context!

You can find (a bit) more detail about the functions in the respective 
header files (under `include`).

#### Physical Memory Management
* `Kernel->mem_alloc(uintptr_t size)` - Allocate 1KiB "pages" to cover `size` bytes
* `Kernel->mem_free(uintptr_t addr, uintptr_t size)` - Free 1KiB "pages" to cover `size` bytes

#### Slab Memory Management

* `Kernel->alloc_sys_object(uint8_t block_count)` - Allocate up to 31 blocks (32bytes each)
* `Kernel->free_sys_object(void* addr, uint8_t block_count)` - Free slabs starting at at `addr`

#### Multitasking

* `Kernel->task_current()` - Obtain a pointer to the currently-running `Task*`
* `Kernel->task_init(Task *task, tid_t tid, priority_t priority)` - Initialise a new task struct
  * This **must** be called on new `Task*` structs before they are used!
  * If allocating task structs, be aware they need two slab blocks!
* `Kernel->task_schedule(Task *task, uintptr_t stack_addr, size_t stack_size, task_handler_f entrypoint)` - Schedule a task to run (next, within its priority level)
* `Kernel->task_wait(uint32_t sig_mask)` - Suspend the current task until another task sends one of the specified signals
  * **Not interrupt safe**
  * Currently, does not unblock if the task is _already_ signalled - this is prone to race conditions and will likely be changed
* `Kernel->task_signal(Task *task, uint32_t sig_mask)` - Signal the given task with the specified signals
  * Does **not** immediately wake the task - it is just scheduled next _within it's priority level_.
  * For this reason, high-priority signalling (e.g. for interrupt handling) should be done in high-priority tasks

#### Interrupt Handling

* `Kernel->enable_interrupts()` - Enable interrupts
  * This is re-entrant, a counter of disables is kept, and only when this is zero are interrupts actually enabled
* `Kernel->disable_interrupts()` - Disable interrupts
  * This is re-entrant, a counter of disables is kept, and used by `enable_interrupts`
* `Kernel->register_irq(uint8_t vec, IrqHandler *handler)` - Register an IRQ chain handler for the given vector
* `Kernel->remove_irq(IrqHandler *handler)` - Remove the specified IRQ chain handler

#### Utilities

Despite being quite strict about being a microkernel, the API _does_ include some utility functions where the
Kernel can usefully export efficient functions for working with kernel structures. 

These may also be useful in your own code.

* `Kernel->list_init(List* the_list)` - Initialize a kernel doubly-linked list
* `Kernel->list_add_head(List* target, ListNode *subject)` - Add the specified node at the head of the list
* `Kernel->list_delete_head(List* target)` - Delete (and return) the head node from the list
* `Kernel->list_add_tail(List* target, ListNode *subject)` - Add the specified node at the tail of the list
* `Kernel->list_delete_tail(List* target)` - Delete (and return) the head node from the list
* `Kernel->list_insert_after(ListNode *target, ListNode *subject)` - Insert the specified subject node after the specified target node
* `Kernel->list_delete(ListNode *subject)` - Delete the specified node from the list that contains it

### Legal Mumbo-Jumbo

**Copyright 2023 Ross Bamford & Contributors**
MIT License


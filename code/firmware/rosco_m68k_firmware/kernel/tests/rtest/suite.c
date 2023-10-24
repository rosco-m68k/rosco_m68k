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
 * Unit tests: all test suite
 * ------------------------------------------------------------
 */

void list_suite();
void pmm_suite();
void bitmap_suite();
void slab_suite();
void interrupts_suite();

void kmain(void) {
    list_suite();
    pmm_suite();
    bitmap_suite();
    slab_suite();
    interrupts_suite();
}
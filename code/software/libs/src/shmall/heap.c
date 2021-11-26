/**
 * MIT License
 * 
 * Copyright (c) 2017 Chris Careaga
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include "include/heap.h"
#include "include/llist.h"

static const uint overhead = sizeof(footer_t) + sizeof(node_t);
static const uint offset = 8;

static uint get_bin_index(size_t sz) {
    uint index = 0;
    sz = sz < 4 ? 4 : sz;

    while (sz >>= 1) index++; 
    index -= 2; 
    
    if (index > BIN_MAX_IDX) index = BIN_MAX_IDX; 
    return index;
}

static footer_t *get_foot(node_t *node) {
    return (footer_t *) ((char *) node + sizeof(node_t) + node->size);
}

static void create_foot(node_t *head) {
    footer_t *foot = get_foot(head);
    foot->header = head;
}

void init_heap(heap_t *heap, long start, long size) {
    node_t *init_region = (node_t *) start;
    init_region->hole = 1;
    init_region->size = (HEAP_INIT_SIZE) - sizeof(node_t) - sizeof(footer_t);

    create_foot(init_region);

    add_node(heap->bins[get_bin_index(init_region->size)], init_region);

    heap->start = (long) start;
    heap->end   = (long) (start + size);
}

void *heap_alloc(heap_t *heap, size_t size) {
    // Round up odd sizes...
    if ((size & 1) == 1) {
        size += 1;
    }

    uint index = get_bin_index(size);
    bin_t *temp = (bin_t *) heap->bins[index];
    node_t *found = get_best_fit(temp, size);

    while (found == NULL) {
        if (index + 1 >= BIN_COUNT)
            return NULL;

        temp = heap->bins[++index];
        found = get_best_fit(temp, size);
    }

    if ((found->size - size) > (overhead + MIN_ALLOC_SZ)) {
        node_t *split = (node_t *) (((char *) found + sizeof(node_t) + sizeof(footer_t)) + size);
        split->size = found->size - size - sizeof(node_t) - sizeof(footer_t);
        split->hole = 1;
   
        create_foot(split);

        uint new_idx = get_bin_index(split->size);

        add_node(heap->bins[new_idx], split); 

        found->size = size; 
        create_foot(found); 
    }

    found->hole = 0; 
    remove_node(heap->bins[index], found); 
    
    found->prev = NULL;
    found->next = NULL;
    return &found->next; 
}

void heap_free(heap_t *heap, void *p) {
    bin_t *list;
    footer_t *new_foot, *old_foot;

    node_t *head = get_head(p);
    if (head == (node_t *) (uintptr_t) heap->start) {
        head->hole = 1; 
        add_node(heap->bins[get_bin_index(head->size)], head);
        return;
    }

    node_t *next = (node_t *) ((char *) get_foot(head) + sizeof(footer_t));
    footer_t *f = (footer_t *) ((char *) head - sizeof(footer_t));
    node_t *prev = f->header;
    
    if (prev->hole) {
        list = heap->bins[get_bin_index(prev->size)];
        remove_node(list, prev);

        prev->size += overhead + head->size;
        new_foot = get_foot(head);
        new_foot->header = prev;

        head = prev;
    }

    if (next->hole) {
        list = heap->bins[get_bin_index(next->size)];
        remove_node(list, next);

        head->size += overhead + next->size;

        old_foot = get_foot(next);
        old_foot->header = 0;
        next->size = 0;
        next->hole = 0;
        
        new_foot = get_foot(head);
        new_foot->header = head;
    }

    head->hole = 1;
    add_node(heap->bins[get_bin_index(head->size)], head);
}

node_t *get_head(void *p) {
    return (node_t *) ((char *) p - offset);
}

/* *** HACK (needed when using C++ and libgcc) *** */
void _Unwind_Resume(void) {
    /* nothing */
}


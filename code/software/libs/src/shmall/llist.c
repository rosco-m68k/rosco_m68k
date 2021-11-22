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

#include "include/llist.h"

void add_node(bin_t *bin, node_t* node) {
    node->next = NULL;
    node->prev = NULL;

    // node_t *temp = bin->head;

    if (bin->head == NULL) {
        bin->head = node;
        return;
    }
    
    // we need to save next and prev while we iterate
    node_t *current = bin->head;
    node_t *previous = NULL;
    // iterate until we get the the end of the list or we find a 
    // node whose size is
    while (current != NULL && current->size <= node->size) {
        previous = current;
        current = current->next;
    }

    if (current == NULL) { // we reached the end of the list
        previous->next = node;
        node->prev = previous;
    }
    else {
        if (previous != NULL) { // middle of list, connect all links!
            node->next = current;
            previous->next = node;

            node->prev = previous;
            current->prev = node;
        }
        else { // head is the only element
            node->next = bin->head;
            bin->head->prev = node;
            bin->head = node;
        }
    }
}

void remove_node(bin_t * bin, node_t *node) {
    if (bin->head == NULL) return; 
    if (bin->head == node) { 
        bin->head = bin->head->next;
        return;
    }
    
    node_t *temp = bin->head->next;
    while (temp != NULL) {
        if (temp == node) { // found the node
            if (temp->next == NULL) { // last item
                temp->prev->next = NULL;
            }
            else { // middle item
                temp->prev->next = temp->next;
                temp->next->prev = temp->prev;
            }
            // we dont worry about deleting the head here because we already checked that
            return;
        }
        temp = temp->next;
    }
}

node_t *get_best_fit(bin_t *bin, size_t size) {
    if (bin->head == NULL) return NULL; // empty list!

    node_t *temp = bin->head;

    while (temp != NULL) {
        if (temp->size >= size) {
            return temp; // found a fit!
        }
        temp = temp->next;
    }
    return NULL; // no fit!
}

node_t *get_last_node(bin_t *bin) {
    node_t *temp = bin->head;

    while (temp->next != NULL) {
        temp = temp->next;
    }
    return temp;
}

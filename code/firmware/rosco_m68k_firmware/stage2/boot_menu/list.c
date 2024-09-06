/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|          firmware
 * ------------------------------------------------------------
 * Copyright (c)2024 The rosco_m68k Open Source Project
 * See top-level LICENSE.md for licence information.
 *
 * Linked list for concept boot screen
 * ------------------------------------------------------------
 */

#include <stdlib.h>

#include "list.h"

ListNode* list_insert_after(ListNode *node, ListNode *after) {
    if (node == NULL || after == NULL) {
        return node;
    }

    node->next = after->next;        
    node->prev = after;
    after->next = node;

    if (node->next) {
        node->next->prev = node;
    }

    return node;
}

ListNode* list_delete(ListNode *node) {
    if (node == NULL) {
        return node;
    }

    ListNode *prev = node->prev;
    ListNode *next = node->next;

    if (prev) {
        prev->next = next;
    }

    if (next) {
        next->prev = prev;
    }

    // Don't null out the prev/next, so nodes can delete
    // themselves and holding code can still progress during
    // a list traversal.
    //
    return node;
}

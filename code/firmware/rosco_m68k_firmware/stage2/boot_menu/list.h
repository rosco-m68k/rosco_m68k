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

#ifndef __LIST_H
#define __LIST_H

typedef struct Node {
    struct Node *next;
    struct Node *prev;
} ListNode;

ListNode* list_insert_after(ListNode *node, ListNode *after);
ListNode* list_delete(ListNode *node);

#endif
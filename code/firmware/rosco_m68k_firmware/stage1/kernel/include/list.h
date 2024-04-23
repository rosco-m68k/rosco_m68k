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
 * C prototypes for linked list routines implemented in assembly.
 * 
 * Lists don't support cycles, don't create them.
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_KERNEL_LIST_H
#define _ROSCOM68K_KERNEL_LIST_H

#include <stdint.h>

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
    ListNode*               head;
    ListNode*               tail;
    ListNode*               tprev;
} List;

#ifdef ROSCO_M68K_KERNEL_BUILD
//// List specific stuff - Usually what you want to use
///
//

/**
 * Initialise a new List.
 * 
 * List keeps track of both head and tail with a dummy
 * node - all valid nodes within a list have both previous
 * and next pointers set non-NULL.
 * 
 * An empty list can be defined as a List where head->next->next == NULL.
 * 
 * @param the_list The list to be initialised
 * @return List* The initialised list
 */
List* list_init_c(List* the_list);

/**
 * Add a node at the head of the list. 
 * 
 * @param target The target List
 * @param subject The subject node to add 
 * @return ListNode* The added subject node
 */
ListNode* list_add_head_c(List* target, ListNode *subject);

/**
 * Delete the head node from the List. 
 * 
 * @param target The target List
 * @param subject The subject node to delete 
 * @return ListNode* The deleted subject node, or NULL if the List is empty
 */
ListNode* list_delete_head_c(List* target);

/**
 * Add a node at the tail of the list. 
 * 
 * @param target The target List
 * @param subject The subject node to add 
 * @return ListNode* The added subject node
 */
ListNode* list_add_tail_c(List* target, ListNode *subject);

/**
 * Delete the tail node from the List. 
 * 
 * @param target The target List
 * @param subject The subject node to delete 
 * @return ListNode* The deleted subject node, or NULL if the List is empty
 */
ListNode* list_delete_tail_c(List* target);


//// ListNode specific stuff - be careful with this, you usually
/// want the List functions rather than these lower-level ones...
//
/**
 * Insert a subject list node after the given target node.
 * 
 * Be careful with this with List tails, it's possible to 
 * break the semantics of List by adding after the logical
 * tail.
 * 
 * @param target The node to add the subject after
 * @param subject The subject node to add
 * @return ListNode* The added node
 */
ListNode* list_node_insert_after_c(ListNode *target, ListNode *subject);

/**
 * Insert a subject list at the end of a node list.
 * 
 * **Note** this is dangerous when used with List (rather than
 * just with lists of ListNode) - it's guaranteed to break them.
 * 
 * It predates the headed lists, and will probably be removed.
 * 
 * @param target The node that heads the list we want to add to
 * @param subject The subject node to add
 * @return ListNode* The added node
 */
ListNode* list_node_add_c(ListNode *head, ListNode *subject);

/**
 * Delete the given subject node.
 * 
 * Note that this **does not** modify the previous/next pointers
 * in the subject node itself, so it is still possible to continue
 * traversal from the node.
 * 
 * @param subject The node to delete
 * @return ListNode* The deleted node
 */
ListNode* list_node_delete_c(ListNode *subject);
#endif//ROSCO_M68K_KERNEL_BUILD

#endif//_ROSCOM68K_KERNEL_LIST_H

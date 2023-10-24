
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
 * Some ad-hoc tests of the list stuff
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdio.h>

#include "list.h"

#define TEST_FAILED = 1;
#define assert_true(expr)   if (!(( expr ))) { return TEST_FAILED; }

static void print_node_list(ListNode *current) {
    while (current) {
        printf("%d => ", current->type);
        current = current->next;
    }
    printf("NULL\n");
}

static void print_list(List *list) {
    ListNode *current = (ListNode*)list;
    while (current) {
        if (current->prev == NULL) {
            printf("<head> => ");
        } else if (current->next == NULL) {
            printf("<tail>\n");
        } else {
            printf("[0x%08x]: %d => ", (uint32_t)current, current->type);
        }
        current = current->next;
    }
}

static void debug_dump_list(List *list) {
    printf("list.head  is 0x%08x\n", (uint32_t)list->head);
    printf("list.tail  is 0x%08x\n", (uint32_t)list->tail);
    printf("list.tprev is 0x%08x\n", (uint32_t)list->tprev);
    printf("\n");

    print_list(list);
    printf("\n--------------------------------------------\n\n");
}

void kmain() {
    // NODES
    ListNode head  = { .next = NULL, .prev = NULL, .type = 0, .size = sizeof(ListNode) };
    ListNode one   = { .next = NULL, .prev = NULL, .type = 1, .size = sizeof(ListNode) };
    ListNode two   = { .next = NULL, .prev = NULL, .type = 2, .size = sizeof(ListNode) };
    ListNode three = { .next = NULL, .prev = NULL, .type = 3, .size = sizeof(ListNode) };

    printf("We have the list! - %d\n", head.size);

    ListNode *insert_one_result = list_node_insert_after_c(&head, &one);
    ListNode *insert_two_result = list_node_insert_after_c(&one, &two);

    ListNode *add_three_result = list_node_add_c(&head, &three);

    printf("Head    is at 0x%08x\n", (uint32_t)&head);
    printf("head.prev  is 0x%08x\n", (uint32_t)head.prev);
    printf("head.next  is 0x%08x\n", (uint32_t)head.next);
    printf("\n");
    printf("one     is at 0x%08x\n", (uint32_t)&one);
    printf("one.prev   is 0x%08x\n", (uint32_t)one.prev);
    printf("one.next   is 0x%08x\n", (uint32_t)one.next);
    printf("insert_one    0x%08x\n", (uint32_t)insert_one_result);
    printf("\n");
    printf("two     is at 0x%08x\n", (uint32_t)&two);
    printf("two.prev   is 0x%08x\n", (uint32_t)two.prev);
    printf("two.next   is 0x%08x\n", (uint32_t)two.next);
    printf("insert_two    0x%08x\n", (uint32_t)insert_two_result);
    printf("\n");
    printf("three   is at 0x%08x\n", (uint32_t)&three);
    printf("three.prev is 0x%08x\n", (uint32_t)three.prev);
    printf("three.next is 0x%08x\n", (uint32_t)three.next);
    printf("add_three     0x%08x\n", (uint32_t)add_three_result);
    printf("\n");

    print_node_list(&head);

    ListNode *delete_three_result = list_node_delete_c(&three);
    printf("\n");
    printf("delete_three  0x%08x\n", (uint32_t)delete_three_result);
    printf("\n");

    print_node_list(&head);

    printf("\n");
    printf("two     is at 0x%08x\n", (uint32_t)&two);
    printf("two.prev   is 0x%08x\n", (uint32_t)two.prev);
    printf("two.next   is 0x%08x\n", (uint32_t)two.next);
    printf("\n");
    printf("three   is at 0x%08x\n", (uint32_t)&three);
    printf("three.prev is 0x%08x\n", (uint32_t)three.prev);
    printf("three.next is 0x%08x\n", (uint32_t)three.next);
    printf("\n");

    ListNode *delete_one_result = list_node_delete_c(&one);
    printf("\n");
    printf("delete_one    0x%08x\n", (uint32_t)delete_one_result);
    printf("\n");

    print_node_list(&head);

    printf("\n");
    printf("Head    is at 0x%08x\n", (uint32_t)&head);
    printf("head.prev  is 0x%08x\n", (uint32_t)head.prev);
    printf("head.next  is 0x%08x\n", (uint32_t)head.next);
    printf("\n");
    printf("two is at     0x%08x\n", (uint32_t)&two);
    printf("two.prev   is 0x%08x\n", (uint32_t)two.prev);
    printf("two.next   is 0x%08x\n", (uint32_t)two.next);
    printf("\n");
    printf("three is at   0x%08x\n", (uint32_t)&three);
    printf("three.prev is 0x%08x\n", (uint32_t)three.prev);
    printf("three.next is 0x%08x\n", (uint32_t)three.next);
    printf("\n");


    // LIST
    List list_head;
    List *list = list_init_c(&list_head);
    printf("&list_head is 0x%08x\n", (uint32_t)&list_head);
    printf("list       is 0x%08x\n", (uint32_t)list);
    printf("list.head  is 0x%08x\n", (uint32_t)list->head);
    printf("list.tail  is 0x%08x\n", (uint32_t)list->tail);
    printf("list.tprev is 0x%08x\n", (uint32_t)list->tprev);
    printf("\n");

    list_add_head_c(list, &one);

    debug_dump_list(list);

    // should delete
    ListNode *deleted = list_delete_head_c(list);

    printf("deleted    is 0x%08x\n", (uint32_t)deleted);
    debug_dump_list(list);

    // should be no-op
    deleted = list_delete_head_c(list);

    printf("deleted    is 0x%08x\n", (uint32_t)deleted);
    debug_dump_list(list);

    list_add_head_c(list, &two);
    list_add_head_c(list, &one);

    print_list(list);
    printf("\n");

    deleted = list_delete_head_c(list);

    printf("deleted    is 0x%08x\n", (uint32_t)deleted);
    debug_dump_list(list);

    list_add_head_c(list, &one);

    printf("ADD TAIL\n===========\n");

    // Clear list
    list = list_init_c(list);
    debug_dump_list(list);

    ListNode *added = list_add_tail_c(list, &one);
    printf("added      is 0x%08x\n", (uint32_t)added);
    debug_dump_list(list);

    added = list_add_tail_c(list, &two);
    printf("added      is 0x%08x\n", (uint32_t)added);
    debug_dump_list(list);

    printf("DELETE TAIL\n===========\n");
    print_list(list);
    printf("\n");

    // should delete 2
    deleted = list_delete_tail_c(list);

    printf("deleted    is 0x%08x\n", (uint32_t)deleted);
    debug_dump_list(list);

    // should delete 1
    deleted = list_delete_tail_c(list);

    printf("deleted    is 0x%08x\n", (uint32_t)deleted);
    debug_dump_list(list);

    // should be no-op
    deleted = list_delete_tail_c(list);

    printf("deleted    is 0x%08x\n", (uint32_t)deleted);
    debug_dump_list(list);
}

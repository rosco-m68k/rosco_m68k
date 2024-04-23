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
 * Unit tests: list
 * ------------------------------------------------------------
 */

#include "roscotest.h"
#include "list.h"

ListNode head;
ListNode one;
ListNode two;
ListNode three;

List list;

static int test_node_add_insert() {
    assert_that(head.prev == NULL);
    assert_that(head.next == NULL);

    ListNode *insert_one_result = list_node_insert_after_c(&head, &one);

    assert_that(insert_one_result == &one);
    assert_that(head.next == &one);
    assert_that(one.prev == &head);
    assert_that(one.next == NULL);

    ListNode *insert_two_result = list_node_insert_after_c(&one, &two);

    assert_that(insert_two_result == &two);
    assert_that(head.next == &one);
    assert_that(one.prev == &head);
    assert_that(one.next == &two);
    assert_that(two.prev == &one);
    assert_that(two.next == NULL);

    ListNode *add_three_result = list_node_add_c(&head, &three);

    assert_that(add_three_result == &three);
    assert_that(head.next == &one);
    assert_that(one.prev == &head);
    assert_that(one.next == &two);
    assert_that(two.prev == &one);
    assert_that(two.next == &three);
    assert_that(three.prev == &two);
    assert_that(three.next == NULL);

    return RTEST_PASS;
}

static int test_node_delete() {
    ListNode *delete_three_result = list_node_delete_c(&three);

    assert_that(delete_three_result == &three);

    // **does not** clear deleted node links
    assert_that(delete_three_result->prev == &two);
    assert_that(delete_three_result->next == NULL);

    // Removed from list (end)
    assert_that(two.next == NULL);

    ListNode *delete_one_result = list_node_delete_c(&one);

    assert_that(delete_one_result == &one);

    // **does not** clear deleted node links
    assert_that(delete_one_result->prev == &head);
    assert_that(delete_one_result->next == &two);

    // Removed from list (end)
    assert_that(head.next == &two);

    return RTEST_PASS;
}

static int test_list_add_delete() {
    assert_that(list.head == (ListNode*)(&list.head + 1));
    assert_that(list.tail == 0);
    assert_that(list.tprev == (ListNode*)&list.head);

    list_add_head_c(&list, &one);

    assert_that(list.head == &one);
    assert_that(list.tail == 0);
    assert_that(list.tprev == &one);

    list_node_delete_c(&one);

    assert_that(list.head == (ListNode*)(&list.head + 1));
    assert_that(list.tail == 0);
    assert_that(list.tprev == (ListNode*)&list.head);

    list_add_head_c(&list, &one);

    assert_that(list.head == &one);
    assert_that(list.tail == 0);
    assert_that(list.tprev == &one);

    return RTEST_PASS;
}

void setup_empty() {
     head.next = NULL;   head.prev = NULL;   head.type = 0;  head.size = sizeof(ListNode);
      one.next = NULL;    one.prev = NULL;    one.type = 1;   one.size = sizeof(ListNode);
      two.next = NULL;    two.prev = NULL;    two.type = 2;   two.size = sizeof(ListNode);
    three.next = NULL;  three.prev = NULL;  three.type = 3; three.size = sizeof(ListNode);
}

void setup_three() {
    setup_empty();
    
    list_node_insert_after_c(&head, &one);
    list_node_insert_after_c(&one, &two);
    list_node_add_c(&head, &three);
}

void setup_list() {
    setup_empty();
    list_init_c(&list);
}

static RTest tests[] = {
    { "/list/node_add_insert", test_node_add_insert, setup_empty, NULL },
    { "/list/node_delete",     test_node_delete,     setup_three, NULL },
    { "/list/add_delete",      test_list_add_delete, setup_list,  NULL },
    { NULL, NULL, NULL, NULL },
};

void list_suite(void) {
    rtest_main(tests);
}
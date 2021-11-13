/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

extern void* _ctors;
extern void* _ctors_end;
extern void* _dtors;
extern void* _dtors_end;
extern int getAclNum();
extern int getBclNum();

__attribute__((constructor(101))) void gconstructor100() {
    printf("Global constructor, priority 101 (via attribute, call via .ctors list; should run first)\n");
}

__attribute__((constructor(200))) void gconstructor200() {
    printf("Global constructor, priority 200 (via attribute, call via .ctors list; should run second)\n");
}

__attribute__((constructor)) void gconstructorNP() {
    printf("Global constructor, No priority (via attribute, call via .ctors list; should run after C++ ctors)\n");
}

__attribute__((destructor(200))) void gdestructor200() {
    printf("Global destructor, priority 200 (via attribute, call via .dtors list, should run first [after C++ dtors])!\n");
}

__attribute__((destructor(101))) void gdestructor100() {
    printf("Global destructor, priority 101 (via attribute, call via .dtors list, should run second)!\n");
}

__attribute__((destructor)) void gdestructor() {
    printf("Global destructor, No priority (via attribute, call via .dtors list, should run last)!\n");
}

void printIn(const char *op, const char* id) {
    printf("In C++ %s (registered with global ctor, dtor via __cxa_atexit): %s\n", op, id);
}

void kmain() {
    printf("Now we're in main()\n");

    printf("Constructors at 0x%08lx - 0x%08lx (%ld entries)\n", 
            (uint32_t)&_ctors, (uint32_t)&_ctors_end, (((uint32_t)&_ctors_end) - ((uint32_t)&_ctors)) >> 2);
    
    printf("Destructors at 0x%08lx - 0x%08lx (%ld entries)\n",
            (uint32_t)&_dtors, (uint32_t)&_dtors_end, (((uint32_t)&_dtors_end) - ((uint32_t)&_dtors)) >> 2);

    printf("By now, global constructors have already been called, and C++ destructors are registered with __cxa_atexit...\n"); 
    
    printf("C++ constructor check for AClass: acl.num() returns %d (expect 42)\n", getAclNum());
    printf("C++ constructor check for BClass: bcl.num() returns %d (expect 64)\n", getBclNum());

    printf("Main will now exit, this should trigger C++ destructors followed by global ones...\n");
}


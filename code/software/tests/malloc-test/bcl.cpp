/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

#include <heap.h>

int bclass_count = 0;

class BClass {
    int i;

    public:
    BClass(const int i) {
        bclass_count++;
        this->i = i;
    }

    ~BClass() {
        bclass_count--;
    }

    int num() {
        return i;
    }
}; 

static BClass *b;

extern "C" int newB() {
    b = new BClass(9001);
    return bclass_count;
}

extern "C" int getBNum() {
    return b->num();
}

extern "C" int deleteB() {
    delete b;
    return bclass_count;
}


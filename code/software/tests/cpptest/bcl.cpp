/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

extern "C" void printIn(const char *op, const char* id);

class BClass {
    int i;

    public:
    BClass(const int i) {
        printIn("Constructor", "BClass");
        this->i = i;
    }

    ~BClass() {
        printIn("Destructor", "BClass");
    }

    int num() {
        return i;
    }
}; 

BClass bcl(64);

extern "C" int getBclNum() {
    return bcl.num();
}


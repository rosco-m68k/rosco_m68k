/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

extern "C" void printIn(const char *op, const char* id);

class AClass {
    int i;

    public:
    AClass(const int i) {
        printIn("Constructor", "AClass");
        this->i = i;
    }

    ~AClass() {
        printIn("Destructor", "AClass");
    }

    int num() {
        return i;
    }
}; 

AClass acl(42);

extern "C" int getAclNum() {
    return acl.num();
}


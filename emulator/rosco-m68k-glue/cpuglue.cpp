//
// Created by ross.bamford on 01/04/2019.
//

#include "AddressDecoder.h"

#ifdef __cplusplus
extern "C" {
#endif

extern rosco::m68k::emu::AddressDecoder __mem;

void resetMachineHandler() {
    __mem.reset();
}

#ifdef __cplusplus
}
#endif

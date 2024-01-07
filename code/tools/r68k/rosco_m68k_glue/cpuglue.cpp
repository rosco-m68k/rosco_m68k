//
// Created by ross.bamford on 01/04/2019.
//

#include <iostream>
#include "AddressDecoder.h"
#include "../musashi/m68kcpu.h"

#ifdef __cplusplus
extern "C" {
#endif

extern rosco::m68k::emu::AddressDecoder *sys_mem;

void resetMachineHandler() {
    sys_mem->reset();
}

void instructionHook() {
	m68ki_cpu_core ctx;
	m68k_get_context(&ctx);

	std::cout << "Execute instruction @ 0x" << std::hex << ctx.pc << " (Instruction word is 0x" << sys_mem->read16(ctx.pc) << ")" << std::endl;
}

#ifdef __cplusplus
}
#endif

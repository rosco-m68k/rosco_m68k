#include <iostream>
#include <stdint.h>
#include "musashi/m68k.h"
#include "musashi/m68kcpu.h"
#include "AddressDecoder.h"

extern "C" {
	rosco::m68k::emu::AddressDecoder* __mem;
}

int main(int argc, char** argv) {
	if (argc != 2) {
		std::cout << "Usage: rosco_m68k <ROM file>";
		return 1;
	} else {
		__mem = new rosco::m68k::emu::AddressDecoder(262144, 1048576, argv[1]);

		std::cout << "Starting..." << std::endl;

		m68k_set_cpu_type(M68K_CPU_TYPE_68010);
		m68k_init();
		m68k_pulse_reset();

		m68ki_cpu_core ctx;
		m68k_get_context(&ctx);

		std::cout << "Address mask: 0x" << std::hex << ctx.address_mask << std::endl;
		std::cout << "Cpu type    : 0x" << ctx.cpu_type << std::endl << std::endl;

		uint32_t memWord = m68k_read_memory_32(0xfc0000);
		uint32_t memWord2 = m68k_read_memory_32(0xfc0004);
		uint32_t memWord3 = m68k_read_memory_32(0);

		std::cout << "PC          : 0x" << m68k_get_reg(&ctx, M68K_REG_PC) << std::endl;
		std::cout << "mem[0]      : 0x" << memWord3 << std::endl;
		std::cout << "mem[fc0000] : 0x" << memWord << std::endl;
		std::cout << "mem[fc0004] : 0x" << memWord2 << std::endl;
		std::cout << "SR          : 0x" << m68k_get_reg(&ctx, M68K_REG_SR) << std::endl;
		std::cout << "D0          : 0x" << m68k_get_reg(&ctx, M68K_REG_D0) << std::endl;
		std::cout << "D7          : 0x" << m68k_get_reg(&ctx, M68K_REG_D7) << std::endl << std::endl;

		int cycles = 0;
		while (!ctx.stopped) {
			cycles += m68k_execute(1000000);
			m68k_get_context(&ctx);
		}

		std::cout << "Executed    : " << std::dec << cycles << " cycle(s)" << std::hex << std::endl << std::endl;

		memWord = m68k_read_memory_32(0xfc0000);
		memWord2 = m68k_read_memory_32(0xfc0004);
		memWord3 = m68k_read_memory_32(0);

		std::cout << "PC          : 0x" << m68k_get_reg(&ctx, M68K_REG_PC) << std::endl;
		std::cout << "mem[0]      : 0x" << memWord3 << std::endl;
		std::cout << "mem[fc0000] : 0x" << memWord << std::endl;
		std::cout << "mem[fc0004] : 0x" << memWord2 << std::endl;
		std::cout << "SR          : 0x" << m68k_get_reg(&ctx, M68K_REG_SR) << std::endl;
		std::cout << "D0          : 0x" << m68k_get_reg(&ctx, M68K_REG_D0) << std::endl;
		std::cout << "D7          : 0x" << m68k_get_reg(&ctx, M68K_REG_D7) << std::endl;

		delete(__mem);
		return 0;
	}
}

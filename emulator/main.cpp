#include <iostream>
#include <stdint.h>
#include "musashi/m68k.h"
#include "musashi/m68kcpu.h"

int main() {
    std::cout << "Starting..." << std::endl;

    m68k_write_memory_32(0xFC0000, 0xFFFFF);               // Stack at $FFFFF
    m68k_write_memory_32(0xFC0004, 0xFC0008);              // Initial PC at ROM start (0xFC00008)

    // Program
    m68k_write_memory_32(0xFC0008, 0xFACE303C);       // Move #$FACE to D0
    m68k_write_memory_32(0xFC000C, 0x000033FC);       // Move #0...
    m68k_write_memory_32(0xFC0010, 0x00FC000A);       // ...to mem[$FC000A] (where $FACE operand was in insn stream previously)
    m68k_write_memory_32(0xFC0014, 0x00040061);       // BSR to PC + 4
    m68k_write_memory_32(0xFC0018, 0x20004E72);       // Load SR $2000 (Supervisor bit only) and STOP

    m68k_set_cpu_type(M68K_CPU_TYPE_68010);
    m68k_init();
    m68k_pulse_reset();

    m68ki_cpu_core ctx;
    m68k_get_context(&ctx);

    std::cout << "Address mask: 0x" << std::hex << ctx.address_mask << std::endl;
    std::cout << "Cpu type    : 0x" << ctx.cpu_type << std::endl << std::endl;

    uint32_t memWord = m68k_read_memory_16(0xfc000a);
    std::cout << "PC          : 0x" << m68k_get_reg(&ctx, M68K_REG_PC) << std::endl;
    std::cout << "mem[fc000a] : 0x" << memWord << std::endl;
    std::cout << "SR          : 0x" << m68k_get_reg(&ctx, M68K_REG_SR) << std::endl;
    std::cout << "D0          : 0x" << m68k_get_reg(&ctx, M68K_REG_D0) << std::endl << std::endl;

    int r = m68k_execute(32);

    std::cout << "Executed    : " << std::dec << r << " cycle(s)" << std::hex << std::endl << std::endl;

    m68k_get_context(&ctx);

    memWord = m68k_read_memory_16(0xfc000a);
    std::cout << "PC          : 0x" << m68k_get_reg(&ctx, M68K_REG_PC) << std::endl;
    std::cout << "mem[fc000a] : 0x" << memWord << std::endl;
    std::cout << "SR          : 0x" << m68k_get_reg(&ctx, M68K_REG_SR) << std::endl;
    std::cout << "D0          : 0x" << m68k_get_reg(&ctx, M68K_REG_D0) << std::endl;

    return 0;
}

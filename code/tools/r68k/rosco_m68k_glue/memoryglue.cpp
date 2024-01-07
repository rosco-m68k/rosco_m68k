//
// Created by ross.bamford on 01/04/2019.
//

#include "AddressDecoder.h"

#ifdef __cplusplus
extern "C" {
#endif

extern rosco::m68k::emu::AddressDecoder *sys_mem;

/* Read from anywhere */
unsigned int  m68k_read_memory_8(unsigned int address) {
    return sys_mem->read8(address);
}

unsigned int  m68k_read_memory_16(unsigned int address) {
    return sys_mem->read16(address);
}

unsigned int  m68k_read_memory_32(unsigned int address) {
    return sys_mem->read32(address);
}

/* Read data immediately following the PC */
unsigned int  m68k_read_immediate_16(unsigned int address) {
    return sys_mem->read16(address);
}

unsigned int  m68k_read_immediate_32(unsigned int address) {
    return sys_mem->read32(address);
}

/* Read data relative to the PC */
unsigned int  m68k_read_pcrelative_8(unsigned int address) {
    return sys_mem->read8(address);
}

unsigned int  m68k_read_pcrelative_16(unsigned int address) {
    return sys_mem->read16(address);
}

unsigned int  m68k_read_pcrelative_32(unsigned int address) {
    return sys_mem->read32(address);
}

/* Memory access for the disassembler */
unsigned int m68k_read_disassembler_8  (unsigned int address) {
    return sys_mem->read8(address);
}

unsigned int m68k_read_disassembler_16 (unsigned int address) {
    return sys_mem->read16(address);
}

unsigned int m68k_read_disassembler_32 (unsigned int address) {
    return sys_mem->read32(address);
}

/* Write to anywhere */
void m68k_write_memory_8(unsigned int address, unsigned int value) {
    sys_mem->write8(address, static_cast<uint8_t>(value & 0xFF));

}

void m68k_write_memory_16(unsigned int address, unsigned int value) {
    sys_mem->write16(address, static_cast<uint16_t>(value & 0xFFFF));

}

void m68k_write_memory_32(unsigned int address, unsigned int value) {
    sys_mem->write32(address, value);
}

#ifdef __cplusplus
}
#endif

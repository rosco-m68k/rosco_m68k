//
// Created by ross.bamford on 01/04/2019.
//

#include <iostream>
#include <intrin.h> // NOTE MSVC-specific!
#include "Memory.h"

namespace rosco {
    namespace m68k {
        namespace emu {
            Memory::Memory(const uint32_t size) {
                this->size = size;
                this->store = new uint8_t[size];
            }

            Memory::~Memory() {
                delete(this->store);
            }

            uint32_t Memory::read32(const uint32_t address) {
#ifdef MEM_TRACE
                uint32_t *addr = ((uint32_t*)(this->store + address));
                std::cout << "read32 : " << std::hex << addr << "; Base: " << (uint32_t*)this->store << "; relative: " << address << std::endl;
#endif

                if (address < this->size) {
                    return _byteswap_ulong(*((uint32_t*)(this->store + address)));
                } else {
                    return 0xFFFFFFFF;
                }
            }

            uint16_t Memory::read16(const uint32_t address) {
#ifdef MEM_TRACE
                uint16_t *addr = ((uint16_t*)(this->store + address));
                std::cout << "read16 : " << std::hex << addr << "; Base: " << (uint32_t*)this->store << "; relative: " << address << std::endl;
#endif

                if (address < this->size) {
                    return _byteswap_ushort(*((uint16_t*)(this->store + address)));
                } else {
                    return 0xFFFF;
                }
            }

            uint8_t Memory::read8(const uint32_t address) {
#ifdef MEM_TRACE
                uint8_t *addr = ((uint8_t*)(this->store + address));
                std::cout << "read8 : " << std::hex << addr << "; Base: " << (uint32_t*)this->store << "; relative: " << address << std::endl;
#endif

                if (address < this->size) {
                    return *(this->store + address);
                } else {
                    return 0xFF;
                }
            }

            void Memory::write32(const uint32_t address, uint32_t data) {
#ifdef MEM_TRACE
                uint32_t *addr = ((uint32_t*)(this->store + address));
                std::cout << "write32: " << std::hex << addr << "; Base: " << (uint32_t*)this->store << "; relative: " << address << std::endl;
#endif

                if (address < this->size) {
                    *((uint32_t*)(this->store + address)) = _byteswap_ulong(data);
                }
            }

            void Memory::write16(const uint32_t address, uint16_t data) {
#ifdef MEM_TRACE
                uint16_t *addr = ((uint16_t*)(this->store + address));
                std::cout << "write16: " << std::hex << addr << "; Base: " << (uint32_t*)this->store << "; relative: " << address << std::endl;
#endif

                if (address < this->size) {
                    *((uint16_t*)(this->store + address)) = _byteswap_ushort(data);
                }
            }

            void Memory::write8(const uint32_t address, uint8_t data) {
#ifdef MEM_TRACE
                uint8_t *addr = this->store + address;
                std::cout << "write8: " << std::hex << addr << "; Base: " << (uint32_t*)this->store << "; relative: " << address << std::endl;
#endif

                if (address < this->size) {
                    *(this->store + address) = data;
                }
            }
        }
    }
}

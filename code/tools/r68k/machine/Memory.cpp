//
// Created by ross.bamford on 01/04/2019.
//

#include <iostream>
#include <fstream>
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
                    return bswap_32(*((uint32_t*)(this->store + address)));
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
                    return bswap_16(*((uint16_t*)(this->store + address)));
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
                    *((uint32_t*)(this->store + address)) = bswap_32(data);
                }
            }

            void Memory::write16(const uint32_t address, uint16_t data) {
#ifdef MEM_TRACE
                uint16_t *addr = ((uint16_t*)(this->store + address));
                std::cout << "write16: " << std::hex << addr << "; Base: " << (uint32_t*)this->store << "; relative: " << address << std::endl;
#endif

                if (address < this->size) {
                    *((uint16_t*)(this->store + address)) = bswap_16(data);
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

            void Memory::LoadData(std::uint32_t baseAddr, char const* filename) {
                std::ifstream ifs(filename, std::ios::binary | std::ios::ate);

                if (!ifs) {
                    throw std::runtime_error("Failed to open ROM");
                }

                std::ifstream::pos_type pos = ifs.tellg();

                if (pos > this->size) {
                    throw std::exception();
                } else {
                    ifs.seekg(0, std::ios::beg);
                    ifs.read((char*)&this->store[baseAddr], pos);
                }

            }

        }
    }
}

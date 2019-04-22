//
// Created by ross.bamford on 01/04/2019.
//

#ifndef ROSCOM68K_EMU_MEMORY_H
#define ROSCOM68K_EMU_MEMORY_H

#define MEM_TRACE

#include <cstdint>
#include <memory>

namespace rosco {
    namespace m68k {
        namespace emu {
            class Memory {
            public:
                explicit Memory(std::uint32_t size);
                ~Memory();

                std::uint32_t read32(std::uint32_t address);
                std::uint16_t read16(std::uint32_t address);
                std::uint8_t read8(std::uint32_t address);

                void write32(std::uint32_t address, std::uint32_t data);
                void write16(std::uint32_t address, std::uint16_t data);
                void write8(std::uint32_t address, std::uint8_t data);

            private:
                std::uint8_t *store;
                std::uint32_t size;

                friend class AddressDecoder;
            };
        }
    }
}

#endif //ROSCOM68K_EMU_MEMORY_H

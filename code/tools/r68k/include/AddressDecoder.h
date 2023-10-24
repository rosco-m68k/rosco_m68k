//
// Created by ross.bamford on 22/04/2019.
//

#ifndef ROSCOM68K_EMU_ADDRESS_DECODER_H
#define ROSCOM68K_EMU_ADDRESS_DECODER_H

#include <cstdint>
#include <fstream>
#include <memory>
#include "Memory.h"

namespace rosco {
    namespace m68k {
        namespace emu {
            class AddressDecoder {
            public:
                explicit AddressDecoder(std::uint32_t romsize, std::uint32_t ramsize, char const* filename);

                Memory* getMemoryForAddress(std::uint32_t address);
                std::uint32_t makeRelativeAddress(std::uint32_t address);

                void reset();

                std::uint32_t read32(std::uint32_t address);
                std::uint16_t read16(std::uint32_t address);
                std::uint8_t read8(std::uint32_t address);

                void write32(std::uint32_t address, std::uint32_t data);
                void write16(std::uint32_t address, std::uint16_t data);
                void write8(std::uint32_t address, std::uint8_t data);

                void LoadMemoryFile(const uint32_t baseAddr, char const* filename);

            private:
                std::unique_ptr<Memory> rom;
                std::unique_ptr<Memory> ram;
                bool bootLineActive;
                uint32_t bootReadCount;

                void ReadRomData(char const* filename);
            };
        }
    }
}

#endif //ROSCOM68K_EMU_ADDRESS_DECODER_H

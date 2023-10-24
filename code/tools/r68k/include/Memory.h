//
// Created by ross.bamford on 01/04/2019.
//

#ifndef ROSCOM68K_EMU_MEMORY_H
#define ROSCOM68K_EMU_MEMORY_H

// #define MEM_TRACE

#include <cstdint>
#include <memory>

namespace rosco {
    namespace m68k {
        namespace emu {
#ifdef _MSC_VER

#include <stdlib.h>
#define bswap_16(x) _byteswap_ushort(x)
#define bswap_32(x) _byteswap_ulong(x)

#elif defined(__APPLE__)

// Mac OS X / Darwin features
#include <libkern/OSByteOrder.h>
#define bswap_16(x) OSSwapInt16(x)
#define bswap_32(x) OSSwapInt32(x)

#elif defined(__sun) || defined(sun)

#include <sys/byteorder.h>
#define bswap_16(x) BSWAP_16(x)
#define bswap_32(x) BSWAP_32(x)

#elif defined(__FreeBSD__)

#include <sys/endian.h>
#define bswap_16(x) bswap16(x)
#define bswap_32(x) bswap32(x)

#elif defined(__OpenBSD__)

#include <sys/types.h>
#define bswap_16(x) swap16(x)
#define bswap_32(x) swap32(x)

#elif defined(__NetBSD__)

#include <sys/types.h>
#include <machine/bswap.h>
#if defined(__BSWAP_RENAME) && !defined(__bswap_32)
#define bswap_16(x) bswap16(x)
#define bswap_32(x) bswap32(x)
#endif

#else

#include <byteswap.h>

#endif
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

                void LoadData(std::uint32_t baseAddr, const char* filename);

            private:
                std::uint8_t *store;
                std::uint32_t size;

                friend class AddressDecoder;
            };
        }
    }
}

#endif //ROSCOM68K_EMU_MEMORY_H

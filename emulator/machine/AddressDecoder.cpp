//
// Created by ross.bamford on 22/04/2019.
//

#include <iostream>
#include <fstream>
#include "AddressDecoder.h"

namespace rosco {
    namespace m68k {
        namespace emu {
            AddressDecoder::AddressDecoder(std::uint32_t romsize, std::uint32_t ramsize, char const* filename) {
                this->rom = std::unique_ptr<Memory>(new Memory(romsize));
                this->ram = std::unique_ptr<Memory>(new Memory(ramsize));
                this->bootLineActive = true;
                this->bootReadCount = 0;

#ifdef MEM_TRACE
                std::cout << "Initialized with " << this->ram->size << " bytes RAM and " << this->rom->size << " bytes ROM" << std::endl;
#endif

                ReadRomData("C:\\Users\\rosco\\devel\\retro\\rosco_m68k\\firmware\\memcount_single.bin");
            }

            Memory* AddressDecoder::getMemoryForAddress(std::uint32_t address) {
                if (address < this->ram->size) {
#ifdef MEM_TRACE
                    std::cout << "Read RAM @ " << std::hex << address << std::endl;
#endif
                    return this->ram.get();
                } else if (address >= 0xFFFFFF - this->rom->size) {
#ifdef MEM_TRACE
                    std::cout << "Read ROM @ " << std::hex << address << std::endl;
#endif
                    return this->rom.get();
                } else {
                    // /BERR?
#ifdef MEM_TRACE
                    std::cout << "BusError @ " << std::hex << address << std::endl;
#endif
                    return NULL;
                }
            }

            std::uint32_t AddressDecoder::makeRelativeAddress(std::uint32_t address) {
                if (address < this->ram->size) {
#ifdef MEM_TRACE
                    std::cout << "RAM Relative address is: 0x" << std::hex << address << std::endl;
#endif
                    return address;
                } else if (address >= 0xFFFFFF - this->rom->size) {
#ifdef MEM_TRACE
                    std::cout << "ROM Relative address is: 0x" << std::hex << address - 1 - (0xFFFFFF - this->rom->size) << std::endl;
#endif
                    return address - 1 - (0xFFFFFF - this->rom->size);
                } else {
                    // /BERR?
#ifdef MEM_TRACE
                    std::cout << "BUSERROR Relative address is 0x0" << std::endl;
#endif
                    return 0;
                }
            }

            void AddressDecoder::reset() {
                this->bootLineActive = true;
                this->bootReadCount = 0;
            }

            std::uint32_t AddressDecoder::read32(std::uint32_t address) {
                Memory *mem;

                if (this->bootLineActive && address < this->rom->size) {
                    if (this->bootReadCount++ < 1) {
#ifdef MEM_TRACE
                        std::cout << "Read /BOOT-shadowed ROM @ " << std::hex << address << std::endl;
#endif
                        mem = this->rom.get();
                    } else {
#ifdef MEM_TRACE
                        std::cout << "Deassert /BOOT and read ROM @ " << std::hex << address << std::endl;
#endif
                        this->bootLineActive = false;
                        mem = this->rom.get();
                    }
                } else {
                    mem = this->getMemoryForAddress(address);
                }

                if (mem != NULL) {
                    return mem->read32(makeRelativeAddress(address));
                } else {
                    // /BERR!
                    return 0;
                }
            }

            std::uint16_t AddressDecoder::read16(std::uint32_t address) {
                Memory *mem = this->getMemoryForAddress(address);

                if (mem != NULL) {
                    return mem->read16(makeRelativeAddress(address));
                } else {
                    // /BERR!
                    return 0;
                }
            }

            std::uint8_t AddressDecoder::read8(std::uint32_t address) {
                Memory *mem = this->getMemoryForAddress(address);

                if (mem != NULL) {
                    return mem->read8(makeRelativeAddress(address));
                } else {
                    // /BERR!
                    return 0;
                }
            }

            void AddressDecoder::write32(std::uint32_t address, std::uint32_t data) {
                Memory *mem = this->getMemoryForAddress(address);

                if (mem != NULL) {
                    mem->write32(makeRelativeAddress(address), data);
                } else {
                    // /BERR!
                }
            }

            void AddressDecoder::write16(std::uint32_t address, std::uint16_t data) {
                Memory *mem = this->getMemoryForAddress(address);

                if (mem != NULL) {
                    mem->write16(makeRelativeAddress(address), data);
                } else {
                    // /BERR!
                }
            }

            void AddressDecoder::write8(std::uint32_t address, std::uint8_t data) {
                Memory *mem = this->getMemoryForAddress(address);

                if (mem != NULL) {
                    mem->write8(makeRelativeAddress(address), data);
                } else {
                    // /BERR!
                }
            }

            void AddressDecoder::ReadRomData(char const* filename) {
                std::ifstream ifs(filename, std::ios::binary | std::ios::ate);
                std::ifstream::pos_type pos = ifs.tellg();

                if (pos > this->rom->size) {
                    throw std::exception();
                } else {
                    ifs.seekg(0, std::ios::beg);
                    ifs.read((char*)this->rom->store, pos);
                }
            }
        }
    }
};

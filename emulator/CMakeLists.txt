cmake_minimum_required(VERSION 3.6)
project(roscom68k_emu)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_FLAGS_DEBUG "-g")

link_directories(machine musashi rosco-m68k-glue)

add_executable(
        roscom68k_emu
        main.cpp
        musashi/m68k.h
        musashi/m68kconf.h
        musashi/m68kcpu.c
        musashi/m68kcpu.h
        musashi/m68kdasm.c
        musashi/m68kopac.c
        musashi/m68kopdm.c
        musashi/m68kopnz.c
        musashi/m68kops.c
        musashi/m68kops.h
        rosco-m68k-glue/memoryglue.cpp
        machine/Memory.cpp
        machine/AddressDecoder.cpp
        include/Memory.h
        include/AddressDecoder.h
)

target_include_directories(roscom68k_emu PUBLIC include)


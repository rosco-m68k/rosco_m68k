set arch m68k
file gdbtest.elf
add-symbol-file ../../firmware/rosco_m68k_firmware/rosco_m68k.elf 
# set debug remote 1
target remote /dev/cu.usbserial-5


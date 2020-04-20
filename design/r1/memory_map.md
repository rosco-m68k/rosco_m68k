# Memory Map

With the standard address decoder (IC2), the machine has the following memory map:

| Region     | Start      | End        | Type                        |
|------------|------------|------------|-----------------------------|
| 00         | 0x00000000 | 0x000fffff | Onboard RAM (See note 1)    |
| 01         | 0x00100000 | 0x00efffff | Expansion RAM               |
| 02         | 0x00f00000 | 0x00f3ffff | Memory hole (See issue #32) |
| 03         | 0x00f40000 | 0x00f7ffff | Expansion RAM               |
| 04         | 0x00f80000 | 0x00fbffff | IO (See note 2, below)      |
| 05         | 0x00fc0000 | 0x00ffffff | Onboard ROM (See note 3)    |

## Note 1 - Onboard RAM layout with standard firmware

00: 0x00000000-0x000003ff - Exception vectors
01: 0x00000400-0x000004ff - System data area
02: 0x00000500-0x00000fff - Reserved for Kernel, can be re-used 
03: 0x00001000-0x000fffff - User

When using the serial firmware, the firmware loads code at 0x28000. On
entry to that code:

* PC will be at 0x28000
* VBR will point to 0x0
* Supervisor stack will be at 0x100000, SSP could be anywhere and can be reset

There is a more complete description of the environment at entry to your
code here: https://github.com/rosco-m68k/rosco_m68k/tree/master/code/firmware/rosco_m68k_v1

When the standard `start_serial` library is compiled into your program,
this library will take care of linking your program correctly and relocating
it to 0x1000 before passing control to your `kmain` function.
For a complete description of the environment on entry, 
see https://github.com/rosco-m68k/rosco_m68k/tree/master/code/software/libs/src/start_serial

## Note 2 - IO Space

As standard, the MFP is mapped to all odd addresses in IO space (IC5 handles
this). It has to be mapped to odd addresses in order to work with the 
CPUs vectored interrupts.

The MFP registers are mapped repeatedly through the whole of IO space,
which leaves only even addresses available for IO expansion (unless the
glue code in IC5 is modified to support).

### MFP Registers

The MFP registers are mapped at the following base addresses and then 
repeat at odd addresses throughout IO space.

| Name (from `machine.h`)   | Address     | Description                       |
|---------------------------|-------------|-----------------------------------|
| MFP_GPDR                  | 0xf80001    | GPIO Data Register                |
| MFP_AER                   | 0xf80003    | Active Edge Register              |
| MFP_DDR                   | 0xf80005    | GPIO Data Direction Register      |
| MFP_IERA                  | 0xf80007    | Interrupt Enable 'A'              |
| MFP_IERB                  | 0xf80009    | Interrupt Enable 'B'              |
| MFP_IPRA                  | 0xf8000B    | Interrupt Pending 'A'             |
| MFP_IPRB                  | 0xf8000D    | Interrupt Pending 'B'             |
| MFP_ISRA                  | 0xf8000F    | Interrupt In-service 'A'          |
| MFP_ISRB                  | 0xf80011    | Interrupt In-service 'B'          |
| MFP_IMRA                  | 0xf80013    | Interrupt Mask 'A'                |
| MFP_IMRB                  | 0xf80015    | Interrupt Mask 'B'                |
| MFP_VR                    | 0xf80017    | Vector Register                   |
| MFP_TACR                  | 0xf80019    | Timer 'A' Control Register        | 
| MFP_TBCR                  | 0xf8001B    | Timer 'B' Control Register        |
| MFP_TCDCR                 | 0xf8001D    | Timers 'C' & 'D' Control          |
| MFP_TADR                  | 0xf8001F    | Timer 'A' Data Register           |
| MFP_TBDR                  | 0xf80021    | Timer 'B' Data Register           |
| MFP_TCDR                  | 0xf80023    | Timer 'C' Data Register           |
| MFP_TDDR                  | 0xf80025    | Timer 'D' Data Register           |
| MFP_SCR                   | 0xf80027    | USART Sync Char Register          |
| MFP_UCR                   | 0xf80029    | USART Control Register            |
| MFP_RSR                   | 0xf8002B    | USART Receiver Status Register    |
| MFP_TSR                   | 0xf8002D    | USART Transmitter Status Register |
| MFP_UDR                   | 0xf8002F    | USART Data Register               |

## Note 3 - Onboard ROM

Although 256KB is set aside for ROM, in the standard configuration only 16KB of 
on-board ROM is provided; This is simply striped through the whole of the
space reserved for ROM.

It's also worth noting that, for the first four memory cycles after power-on
or reset, ROM is duplicated low (at 0x0) to allow the CPU to read the reset
vector.


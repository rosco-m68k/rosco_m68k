# rosco_m68k JP3 (Expansion) Pinout

JP3 (split into JP3 and JP4 in the schematic but joined as a single 2x32 pin header on the PCB)
provides peripheral access to the full address, data and control buses in the system, plus
VCC (5V) and GND. These signals are unbuffered, however many of the MC68010 lines are 
tri-state when used in conjunction with the bus-mastering support.

It should be noted that most of these signals have very low output current capabilities,
and should not be used to directly drive e.g. LEDs. If LEDs are to be driven, then either
a transistor must be used, or the circuit set up such that the pins sink current.

In all cases, see the datasheets for the relevant IC driving a given line (either the
MC68010 or, for the decoder signals, the ATF16V8BQL) for the absolute maximum ratings.

The recommended maximum current draw on the VCC line is 250mA. The board _should_ be
able to supply more than this, but as power supplies are so variable you should take
care if drawing more than this from this pin. A better solution should you need might
be to separately power your peripheral from the supply and share common ground.

Although it is possible with the current design to power the board by the VCC and GND
pins, this is not recommended. If you do decide to do this you might consider additional
filtering.

| Pin | Signal | Description                                  | Active | I/O |
|-----|--------|----------------------------------------------|--------|-----|
| 1   | A1     | MC68010 Address line 1                       | High   | O   |
| 2   | VCC    | +5V (Recommend 250mA max depending on PSU)   | N/A    | O   |
| 3   | A2     | MC68010 Address line 2                       | High   | O   |
| 4   | CLK    | Main system clock (8MHz, 50% duty cycle)     | N/A    | O   |
| 5   | A3     | MC68010 Address line 3                       | High   | O   |
| 6   | GND    | Ground                                       | N/A    | O   |
| 7   | A4     | MC68010 Address line 4                       | High   | O   |
| 8   | ERAM   | EVENRAMSEL line from decoder (*1)            | Low    | O   |
| 9   | A5     | MC68010 Address line 5                       | High   | O   |
| 10  | EROM   | EVENROMSEL line from decoder (*1)            | Low    | O   |
| 11  | A6     | MC68010 Address line 6                       | High   | O   |
| 12  | ORAM   | ODDRAMSEL line from decoder (*1)             | Low    | O   |
| 13  | A7     | MC68010 Address line 7                       | High   | O   |
| 14  | OROM   | ODDROMSEL line from decoder (*1)             | Low    | O   |
| 15  | A8     | MC68010 Address line 8                       | High   | O   |
| 16  | IOS    | IOSEL line from decoder (*1)                 | Low    | O   |
| 17  | A9     | MC68010 Address line 9                       | High   | O   |
| 18  | EXPS   | EXPSEL line from decoder (*1)                | Low    | O   |
| 19  | A10    | MC68010 Address line 10                      | High   | O   |
| 20  | FC0    | MC68010 Function Code 0 (*2)                 | High   | O   |
| 21  | A11    | MC68010 Address line 11                      | High   | O   |
| 22  | FC1    | MC68010 Function Code 1 (*2)                 | High   | O   |
| 23  | A12    | MC68010 Address line 12                      | High   | O   |
| 24  | FC2    | MC68010 Function Code 2 (*2)                 | High   | O   |
| 25  | A13    | MC68010 Address line 13                      | High   | O   |
| 26  | IPL0   | MC68010 Interrupt Priority Level Bit 0 (*3)  | Low    | I   |
| 27  | A14    | MC68010 Address line 14                      | High   | O   |
| 28  | IPL1   | MC68010 Interrupt Priority Level Bit 1 (*3)  | Low    | I   |
| 29  | A15    | MC68010 Address line 15                      | High   | O   |
| 30  | IPL2   | MC68010 Interrupt Priority Level Bit 2 (*3)  | Low    | I   |
| 31  | A16    | MC68010 Address line 16                      | High   | O   |
| 32  | LDS    | MC68010 Lower Data Strobe                    | Low    | O   |
| 33  | A17    | MC68010 Address line 17                      | High   | O   |
| 34  | UDS    | MC68901 Upper Data Strobe                    | Low    | O   |
| 35  | A18    | MC68010 Address line 18                      | High   | O   |
| 36  | RESET  | System Reset (4*)                            | Low    | I/O |
| 37  | A19    | MC68010 Address line 19                      | High   | O   |
| 38  | D15    | MC68010 Data line 15                         | High   | I/O |
| 39  | A20    | MC68010 Address line 20                      | High   | O   |
| 40  | D14    | MC68010 Data line 14                         | High   | I/O |
| 41  | A21    | MC68010 Address line 21                      | High   | O   |
| 42  | D13    | MC68010 Data line 13                         | High   | I/O |
| 43  | A22    | MC68010 Address line 22                      | High   | O   |
| 44  | D12    | MC68010 Data line 12                         | High   | I/O |
| 45  | A23    | MC68010 Address line 23                      | High   | O   |
| 46  | D11    | MC68010 Data line 11                         | High   | I/O |
| 47  | AS     | MC68010 Address Strobe                       | Low    | O   |
| 48  | D10    | MC68010 Data line 10                         | High   | I/O |
| 49  | BERR   | MC68010 Bus Error                            | Low    | I   |
| 50  | D9     | MC68010 Data line 9                          | High   | I/O |
| 51  | BG     | MC68010 Bus Grant                            | Low    | O   |
| 52  | D8     | MC68010 Data line 8                          | High   | I/O |
| 53  | BGACK  | MC68010 Bus Grant Acknowledge                | Low    | I   |
| 54  | D7     | MC68010 Data line 7                          | High   | I/O |
| 55  | BR     | MC68010 Bus Request                          | Low    | I   |
| 56  | D6     | MC68010 Data line 6                          | High   | I/O |
| 57  | DTACK  | MC68010 Data Transfer Acknowledge            | Low    | I   |
| 58  | D5     | MC68010 Data line 5                          | High   | I/O |
| 59  | R/W    | MC68010 Read/Not Write                       | N/A    | O   |
| 60  | D4     | MC68010 Data line 4                          | High   | I/O |
| 61  | D0     | MC68010 Data line 0                          | High   | I/O |
| 62  | D3     | MC68010 Data line 3                          | High   | I/O |
| 63  | D1     | MC68010 Data line 1                          | High   | I/O |
| 64  | D4     | MC68010 Data line 4                          | High   | I/O |
 
 ## Notes:
 
 1. If used to drive LEDs, the circuit should be configured such that these pins sink current.
 2. If all three function code pins are high the CPU is asserting IACK.
 3. Interrupt 4 (100b) is reserved for the MC68901.
 4. Wire-or, open-collector.


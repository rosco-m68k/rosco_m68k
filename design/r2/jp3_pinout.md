# rosco_m68k JP3 (Expansion) Pinout (revision 2)

> **Note** this applies to revision 2 (and higher, unless otherwise specified)
  boards **only**. This pinout has changed since the revision one boards (but 
  for most practical purposes it should be compatible - see the new IRQ pins 
  for the differences). This pinout is **not** compatible with earlier revision
  zero boards (which were never released to production anyway)!

JP3 provides peripheral access to the full address, data and control buses in the system, 
plus VCC (5V) and GND. These signals are unbuffered and have no built-in protection, so are
not suitable for direct use as a bus, but could be made so with a relativelty simple 
expansion-to-bus conversion board. 

Many of the MC68010 lines are tri-state when used in conjunction with the bus-mastering support.

It should be noted that most of these signals have very low output current capabilities,
and should not be used to directly drive e.g. LEDs. If LEDs are to be driven, then either
a transistor must be used, or the circuit set up such that the pins sink current.

In all cases, see the datasheets for the relevant IC driving a given line (either the
MC68010, MC68901 or, for the decoder signals, the ATF22V10Cs) for the absolute maximum ratings.

The absolute maximum current draw on the VCC line is 1A. Recommended maximum is 500mA.
The board _may_ be able to supply more than this, but as power supplies are so variable 
you should take care if drawing more than this from this pin. A better solution should 
you need might be to separately power your peripheral from the supply and share common ground.

| Pin | Signal | Description                                  | Active | I/O |
|-----|--------|----------------------------------------------|--------|-----|
| 1   | A1     | MC68010 Address line 1                       | High   | O   |
| 2   | VCC    | +5V (Recommend 1A max)                       | N/A    | O   |
| 3   | A2     | MC68010 Address line 2                       | High   | O   |
| 4   | CLK    | Main system clock (10MHz, 50% duty cycle)    | N/A    | O   |
| 5   | A3     | MC68010 Address line 3                       | High   | O   |
| 6   | GND    | Ground                                       | N/A    | O   |
| 7   | A4     | MC68010 Address line 4                       | High   | O   |
| 8   | VPA    | MC68010 Legacy peripheral VPA (*5)(6*)       | Low    | I   |
| 9   | A5     | MC68010 Address line 5                       | High   | O   |
| 10  | E      | MC68010 Legacy peripheral E (*5)             | Low    | O   |
| 11  | A6     | MC68010 Address line 6                       | High   | O   |
| 12  | VMA    | MC68010 Legacy peripheral VMA (*5)           | Low    | O   |
| 13  | A7     | MC68010 Address line 7                       | High   | O   |
| 14  | IRQ3   | IRQ3 line (*3)                               | Low    | I   |
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
| 26  | IPL0   | IRQ5 line (*3)                               | Low    | I   |
| 27  | A14    | MC68010 Address line 14                      | High   | O   |
| 28  | IPL1   | IRQ2 Line (*3)                               | Low    | I   |
| 29  | A15    | MC68010 Address line 15                      | High   | O   |
| 30  | IPL2   | IRQ6 Line *3)                                | Low    | I   |
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
| 64  | D2     | MC68010 Data line 2                          | High   | I/O |
 
 ## Notes:
 
 1. If used to drive LEDs, the circuit should be configured such that these pins sink current.
 2. If all three function code pins are high the CPU is asserting IACK.
 3. Active low, open-collector IRQ lines for peripherals (4K7 pullups included, do not add more). 
 4. Wire-or, open-collector. Pullup is already provided.
 5. See MC68010 user manual. Using these lines alters bus cycle timing.
 6. This line has a built-in 10k pull-up.


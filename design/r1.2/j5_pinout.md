# rosco_m68k J5 (IO & Panel) Pinout

J5 provides connection to five software-controlled digital GPIO pins with
vectored interrupt capability, two software-controlled timers 8-bit timers, 
and access to all six address-decoder outputs for display purposes.

## GPIO Pins

The general purpose interrupt input/output port provides five I/O lines (GPIO#1-#5)
that may be operated as either inputs or outputs under software control.

In addition, these lines may optionally generate an interrupt on either a positive
transition or a negative transition of the input signal. 

Since interrupts are enabled on a bit-by-bit basis, a subset of the GPIO port could 
be programmed as e.g. handshake lines or the port could be connected to as many as 
five external interrupt sources, which would be prioritized by the on-board interrupt
controller for interrupt service.

For full details, refer to the MC68901 Users Manual. When programming the GPIO port,
it should be noted that the GPIOs are connected to MFP GPIPs #2-6. GPIOs 0, 1 and 7
are used internally by the system.

> **Note**: The GPIO pins are intented for interfacing with other ICs and are **not** 
  suitable for directly driving LEDs or other such devices. If you want to drive LEDs
  from these pins please use transistors!

### Legacy peripheral support

While the MC68010's built-in legacy peripheral support lines are available on
JP3, utilising these lines will cause M6800-type peripherals to use the autovector 
which corresponds to their assigned interrupt level (determined by the state of
the IPL pins, also available on JP3) since they do not provide a vector number in
response to an IACK cycle. This means that polling will have to be performed in
software to determine the interrupting device.

However, by tying the IRQ output from an M6800-type device to the general purpose
IO port and configuring that GPIO as an interrupt line, a unique vector number will
be provided to the processor during an interrupt acknowledge cycle. 

This interrupt structure will significantly reduce interrupt latency for M6800-type
devices and other peripheral devices which do not support vector-by-device.

## Timers

The timers can generate periodic interrupts, measure elapsed time, and count 
signal transitions. In addition, the timers have waveform generation capability.
Both timers are prescaler/counter timers with a common 3.6864MHz clock and are 
independent of the system clock. 

Each timer's output signal toggles when the timer's main counter times out. 
Additionally, both have auxiliary input signals which are used in two of the operation 
modes. An interrupt channel is assigned to each timer and when the auxiliary control 
signals are used, a separate interrupt channel will respond to transitions on these 
inputs.

In addition to the delay mode, both timers can operate in pulse width measurement 
mode and event count mode. 

For full details of the timer modes and how the timers are programmed, refer to the 
MC68901 user manual. When programming the timers, it should be noted that the 
two timers provided are the full-featured timers, A and B. Timers C and D are
used internally by the system.

## Pin assignments

It should be noted that most of these signals have very low output current capabilities,
and should not be used to directly drive e.g. LEDs. If LEDs are to be driven, then either
a transistor must be used, or the circuit set up such that the pins sink current.

In all cases, see the datasheets for the relevant IC driving a given line (either the
MC68901 or, for the decoder signals, the ATF16V8BQL) for the absolute maximum ratings.

| Pin | Signal | Description                                  | Active | I/O |
|-----|--------|----------------------------------------------|--------|-----|
| 1   | GPIO1  | GPIO #1 (MFP GPIP #2) (*4)                   | H/L    | I/O |
| 2   | ERAM   | EVENRAMSEL line from decoder (*1)            | Low    | O   |
| 3   | GPIO2  | GPIO #2 (MFP GPIP #3) (*4)                   | H/L    | I/O |
| 4   | ORAM   | ODDRAMSEL line from decoder (*1)             | Low    | O   |
| 5   | GPIO3  | GPIO #3 (MFP GPIP #4) (*4)                   | H/L    | I/O |
| 6   | EROM   | EVENROMSEL line from decoder (*1)            | Low    | O   |
| 7   | GPIO4  | GPIO #4 (MFP GPIP #5) (*4)                   | H/L    | I/O |
| 8   | OROM   | ODDROMSEL line from decoder (*1)             | Low    | O   |
| 9   | GPIO5  | GPIO #5 (MFP GPIP #6) (*4)                   | H/L    | I/O |
| 10  | IOS    | IOSEL line from decoder (*1)                 | Low    | O   |
| 11  | TAO    | Timer A output                               | --     | O   |
| 12  | EXPS   | EXPSEL line from decoder (*1)                | Low    | O   |
| 13  | TBO    | Timer B output                               | --     | O   |
| 14  | TBI    | Timer B input (*2)                           | --     | I   |
| 15  | TAI    | Timer A input (*2)                           | --     | I   |
| 16  | N/C    | Unconnected (*3)                             | --     | --  |
 
 ## Notes:
 
 1. If used to drive LEDs, the circuit should be configured such that these pins sink current.
 2. These pins have an on-board 4K7 pull-up to VCC
 3. This pin can (via additional soldering) be used as either a GND or VCC to suit the configuration of the other pin connections. In the future an on-board jumper may be provided to accomplish this.
 4. If driving LEDs, it is **strongly** recommended that transistors be used as these pins have very low current ratings for both source and sink. Refer to the MC68901 datasheet for specific values.

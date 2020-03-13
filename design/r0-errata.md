# Errata for revision 0 PCB

* The MFP address lines are reversed (see [#7](https://github.com/roscopeco/rosco_m68k/issues/7) and [#11](https://github.com/roscopeco/rosco_m68k/issues/11))
* The top silkscreen incorrectly labels expansion pin 2 as pin 64 (see [#8](https://github.com/roscopeco/rosco_m68k/issues/8))
* It is recommended to replace the **Q1** 1.8432 MHz crystal with a 3.6864 MHz part to enable 9600 BPS from the UART
  * Farnell part [9712909](https://uk.farnell.com/iqd-frequency-products/lfxtal003263/crystal-3-686400mhz/dp/9712909?CMP=i-ddd7-00001003) is a suitable drop-in replacement
  * This is due to software now using the divide-by-16 mode on the UART to aid noise resiliency
  * Higher frequencies are **not recommended** as they exceed the maximums specified for the MC68901 MFP

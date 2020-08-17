/*
 * vim: set et ts=2 sw=2
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|                       
 * ------------------------------------------------------------
 * Copyright (c) 2020 Xark
 * MIT License
 * ------------------------------------------------------------
 */

#include <basicio.h>
#include <machine.h>
#include <gpio.h>

// macro for easier MFP register access (read or write)
#define MFP(reg) (*(volatile uint8_t *)MFP_ ## reg)

// rosco_m68k 100Hz loop_counter.  The MFP "timer C" interrupt handler
// in rosco's firmware increments this every 100th of a second.
volatile uint32_t *tick_100Hz = (uint32_t *)0x40C;

// Bit 6 in IREB, IPRB and ISRB corresponds to rosco GPIO3
// See page 3-4 in 1984 MC68901 MFP pdf
#define MFP_GPIP4_BIT 0x40

volatile int gpio3_interrupts;    // counter for number of GPIO3 interrupts

// GPIO3 interrupt handler.  The "interrupt" attribute "tells the compiler to save
// all the registers in this function and use the "rte" return from exception
// instruction at the end instead of the normal "rts" return from subroutine instruction.
// This allows the interrupt handler to be written in C.
void gpio3_handler(void) __attribute__ ((interrupt));
void gpio3_handler(void)
{
  MFP(GPDR) ^= 2;               // toggle red LED
  gpio3_interrupts += 1;        // increment interrupt counter
  print("<Interrupted!>");      // "interrupt" main printing
  MFP(ISRB) = ~MFP_GPIP4_BIT;   // clear interrupt in-service bit
}

noreturn void kmain()
{
  // clear BSS segment as C standard requires (so bss variables start zero'd)
  // Needed since rosco kmain is not quite like normal C main.
  {
    extern int _bss_start[], _bss_end[];
    for (int *bss = _bss_start; bss <= _bss_end; bss++)
      *bss = 0;
  }

  println("");
  println("*** MFP GPIO Interrupt Test ***");
  println("          by Xark");
  println("(built on " __DATE__ " at " __TIME__ ")");
  println("");
  print("rosco_m68k firmware version: ");
  printushort(*(uint16_t *)0xFC0400);
  print(".");
  printuchar(*(uint8_t *)0xFC0402);
  print(".");
  printuchar(*(uint8_t *)0xFC0403);
  println("");
  println("This will test interrupt generation on a negative");
  println("edge on rosco GPIO3 (J5-pin 5 aka MFP GPIP4).");

  println("Initializing MFP for GPIP4 interrupt...");

  // It is documented that if you are "unlucky" and touch the MFP interrupt
  // registers at "just the wrong time" (as another interrupt happens etc.)
  // the MFP can generate a "spurious interrupt" (which will lead to red LED
  // blinking, and sadness).  So we disable all interrupts for the short period
  // while we set the MFP interrupt registers (and re-enable them right after).
  mcDisableInterrupts();

  // NOTE: These use the normal GPIO bit values (from gpio.h)
  MFP(DDR)  &= ~GPIO3;     // clear GPIO3 data direction for input (0=in, 1=out)
  MFP(GPDR) &= ~GPIO3;     // clear GPIO3 data register (likely not necessary)
  MFP(AER)  &= ~GPIO3;     // set GPIO3 active edge to falling (0=falling, 1=rising)

  // NOTE: Since these are spread between two 8-bit registers, they use a different
  //       bit than the GPIO definition.  See page 3-4 in 1984 MC68901 MFP pdf
  MFP(IERB) |= MFP_GPIP4_BIT; // set MFP GPIP4 interrupt enable
  MFP(IPRB) = ~MFP_GPIP4_BIT; // clear MFP GPIP4 interrupt pending
  MFP(ISRB) = ~MFP_GPIP4_BIT; // clear interrupt in-service bit
  MFP(IMRB) |= MFP_GPIP4_BIT; // clear interrupt mask bit

  // Set vector #70 (MFP GPIP4 interrupt) to our interrupt handler.
  // GPIP4 is MFP interrupt source #6 (see page 3-1 in 1984 MC68901 MFP pdf)
  // and rosco assigns the MFP to the first 680x0 user interrupt vector #64.
  // So our interrupt vector is at address 0x118 = 0x100 (64*4 user interrupt vector
  // start) plus 6*4 (the sixth MFP interrupt).  Each address is 4 bytes.
  //
  // This _could_ be done in C, but since it would need an ugly cast along with
  // the "pedantic" compiler options restrictons making it more difficult, one
  // line of inline asm seemed prefereable.
  __asm__ __volatile__ ("move.l #%[fn],0x100+6*4\n" : : [fn] "m" (gpio3_handler) : );

  mcEnableInterrupts();   // re-enable interrupts

  println("Done.  Now ready for a GPIO3 interrupt.");
  println("");
  println("Mainline will keep loop_counting, waiting for interrupts.");
  println("");
  println("Press any key to exit.");
  println("");

  int loop_count = 0;
  do
  {
    print("loop #=");
    printuint(loop_count);
    print(" GPIO3 interrupts=");
    printuint(gpio3_interrupts);
    print(" 100Hz ticks=");
    printuint(*tick_100Hz);
    println("...");

    // delay for 1 1/2 of a second
    for (uint32_t delay = *tick_100Hz + 150; *tick_100Hz < delay;)
      ;
 
    loop_count++;

  } while (!(MFP(RSR)&0x80)); // loop until a char is waiting in UART buffer

  println("");
  println("Glad to be of service!");  // invoke Genuine Rosco Personality(TM) module
  println("Resetting...");

  mcReset();  // soft-reset back to loader
}

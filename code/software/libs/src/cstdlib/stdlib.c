// basic stdlib functions
#include <stdint.h>
#include <stdlib.h>

static volatile uint32_t * const upticks = (volatile uint32_t * const)0x40C;

void exit(int status)
{
  // Warm-reboot machine when quit
  __asm__ __volatile__ (
      "moveal 0xfc0004.l, %a0\n\t"
      "jmp %a0@\n\t"
  );
}

void abort(void)
{
  // Warm-reboot machine when quit (should this blink LED or something)
  __asm__ __volatile__ (
      "moveal 0xfc0004.l, %a0\n\t"
      "jmp %a0@\n\t"
  );
}

int rand(void) 
{
        long k;
        long s = *upticks;
        if (s == 0)
          s = 0x12345987;
        k = s / 127773;
        s = 16807 * (s - k * 127773) - 2836 * k;
        if (s < 0)
          s += 2147483647;
        //(*seed) = (unsigned int)s;
        return (int)(s & RAND_MAX);
}
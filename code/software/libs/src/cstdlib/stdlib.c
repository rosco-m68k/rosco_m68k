// basic stdlib functions

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

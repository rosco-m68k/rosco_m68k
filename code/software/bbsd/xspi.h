#include <stdint.h>
#include <machine.h>
// Xark's eXtreme SPI

static inline void xspi_send_byte(uint32_t b, void* gpdr_ptr, uint32_t lo_0, uint32_t lo_1, uint32_t hi_0, uint32_t hi_1)
{
  register long d0 __asm__ ("d0") = b;
  register void*a1 __asm__ ("a1") = gpdr_ptr;
  register long d2 __asm__ ("d2") = lo_0;
  register long d3 __asm__ ("d3") = lo_1;
  register long d4 __asm__ ("d4") = hi_0;
  register long d5 __asm__ ("d5") = hi_1;
   __asm__ __volatile__ (
    " lea 0f,%%a0\n"
    " jmp _xspi_send_byte.w\n"
    "0:\n"
    : 
    : "d" (d0), "a" (a1), "d" (d2), "d" (d3), "d" (d4), "d" (d5)
    : "a0", "d1"
  );
}

static inline void xspi_send_word(uint32_t w, void *gpdr_ptr, uint32_t lo_0, uint32_t lo_1, uint32_t hi_0, uint32_t hi_1)
{
  register long d0 __asm__ ("d0") = w;
  register void*a1 __asm__ ("a1") = gpdr_ptr;
  register long d2 __asm__ ("d2") = lo_0;
  register long d3 __asm__ ("d3") = lo_1;
  register long d4 __asm__ ("d4") = hi_0;
  register long d5 __asm__ ("d5") = hi_1;
   __asm__ __volatile__ (
    " lea 0f,%%a2\n"
    " jmp _xspi_send_word.w\n"
    "0:\n"
    : 
    : "d" (d0), "a" (a1), "d" (d2), "d" (d3), "d" (d4), "d" (d5)
    : "a0", "a2", "d1"
  );
}

static inline void xspi_send_word_count(uint32_t w, uint32_t count, void *gpdr_ptr, uint32_t lo_0, uint32_t lo_1, uint32_t hi_0, uint32_t hi_1)
{
  register long d0 __asm__ ("d0") = w;
  register void*a1 __asm__ ("a1") = gpdr_ptr;
  register long d2 __asm__ ("d2") = lo_0;
  register long d3 __asm__ ("d3") = lo_1;
  register long d4 __asm__ ("d4") = hi_0;
  register long d5 __asm__ ("d5") = hi_1;
  register long d6 __asm__ ("d6") = count;
   __asm__ __volatile__ (
    " lea 0f,%%a2\n"
    " jmp _xspi_send_word_count.w\n"
    "0:\n"
    : 
    : "d" (d0), "a" (a1), "d" (d2), "d" (d3), "d" (d4), "d" (d5), "d" (d6)
    : "a0", "a2", "d1"
  );
}

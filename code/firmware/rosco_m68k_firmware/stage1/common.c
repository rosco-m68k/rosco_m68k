#include <stdint.h>
#include <stddef.h>

void* memchr(const void *s, int c, int n) {
  const unsigned char *src = (const unsigned char *)s;

  while (n-- > 0) {
      if (*src == c) {
          return (char*)src;
      }
      src++;
  }
  return NULL;
}

void* memcpy(void *__restrict s1, const void *__restrict s2, int n) {
    // totally naive implementation, will do for now...
    uint8_t *fbuf = (uint8_t*) s2;
    uint8_t *tbuf = (uint8_t*) s1;

    for (uint8_t *end = fbuf + n; fbuf < end; *tbuf++ = *fbuf++)
        ;

    return tbuf;
}

unsigned long divmod(unsigned long num, unsigned long den, int mod) {
    unsigned long bit = 1;
    unsigned long res = 0;

    while (den < num && bit && !(den & (1L << 31))) {
        den <<= 1;
        bit <<= 1;
    }

    while (bit) {
        if (num >= den) {
            num -= den;
            res |= bit;
        }

        bit >>= 1;
        den >>= 1;
    }

    if (mod) {
        return num;
    } else {
        return res;
    }
}

uint32_t __divsi3(uint32_t dividend, uint32_t divisor) {
    return divmod(dividend, divisor, 0);
}
uint32_t __modsi3(uint32_t dividend, uint32_t divisor) {
    return divmod(dividend, divisor, 1);
}
uint32_t __udivsi3(uint32_t dividend, uint32_t divisor) {
    return divmod(dividend, divisor, 0);
}
uint32_t __umodsi3(uint32_t dividend, uint32_t divisor) {
    return divmod(dividend, divisor, 1);
}

unsigned int __mulsi3(unsigned int a, unsigned int b) {
    unsigned int r = 0;

    while (a) {
        if (a & 1) {
            r += b;
        }

        a >>= 1;
        b <<= 1;
    }

    return r;
}

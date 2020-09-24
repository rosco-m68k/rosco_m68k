/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

#include <stdio.h>

void kmain() {
  printf("Hello, world! 😃\r\n");

  unsigned int i = 42 % 5;

  printf("Result: %d\r\n", i);


  // When this function returns, the machine will reboot.
  //
  // In a real program, you probably wouldn't return from 
  // this function!
}


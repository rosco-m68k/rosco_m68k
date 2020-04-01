/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

#include <stdio.h>
#include <basicio.h>
#include <stdnoreturn.h>
#include <stdbool.h>

void kmain() {
  printf("Hello, world! 😃\r\n");

  // When this function returns, the machine will reboot.
  //
  // In a real program, you probably wouldn't return from 
  // this function!
}


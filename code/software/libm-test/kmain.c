/*
 * Copyright (c) 2020 You (you@youremail.com)
 */

#include <stdio.h>
#include <stdlib.h>
#include <machine.h>
#include <math.h>
#include <printf.h>

int err = 1;
int *__errno()
{
return &err;
}

void kmain() {

  float result = sin(35);
  double result2 = sqrt(4);
  printf("sin(35) =  %.02f \r\n", result);
  printf("sqrt(4) =  %.02f \r\n", result2);
  // When this function returns, the machine will reboot.
  //
  // In a real program, you probably wouldn't return from 
  // this function!
}


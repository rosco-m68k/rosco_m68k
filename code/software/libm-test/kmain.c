/*
 * Copyright (c) 2020 Matthew Pearce (mattpearce@me.com)
 */

#include <stdio.h>
#include <stdlib.h>
#include <machine.h>
#include <math.h>
#include <printf.h>

void kmain() {

  float result = sin(35);
  double result2 = sqrt(4);
  float result3 = cos(45);
  float result4 = log(20);
  float result5 = exp(20);
  printf("sin(35) =  %.02f \r\n", result);
  printf("sqrt(4) =  %.02f \r\n", result2);
  printf("cos(45)  =  %.02f \r\n", result3);
  printf("log(20) =  %.02f \r\n", result4);
  printf("exp(20) =  %.02f \r\n", result5);
}


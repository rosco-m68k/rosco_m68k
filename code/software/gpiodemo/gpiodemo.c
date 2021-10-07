/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2020 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * Extremely simple example of GPIO programming.
 * ------------------------------------------------------------
 */

#include <stdnoreturn.h>
#include <stdbool.h>
#include <basicio.h>
#include <gpio.h>

static void initGPIOs() {
  pinMode(GPIO1, OUTPUT);
  pinMode(GPIO2, OUTPUT);
  pinMode(GPIO3, OUTPUT);
  pinMode(GPIO4, OUTPUT);
  pinMode(GPIO5, OUTPUT);
}

static void setGPIOs(bool g1, bool g2, bool g3, bool g4, bool g5) {
  digitalWrite(GPIO1, g1);
  digitalWrite(GPIO2, g2);
  digitalWrite(GPIO3, g3);
  digitalWrite(GPIO4, g4);
  digitalWrite(GPIO5, g5);
}

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;

  print("\033[H\033[2J");
  println("GPIO Toggle Demo");
  println("(press a key to exit)");
  initGPIOs();

  while (!checkchar()) {
    print("💡 ");
    setGPIOs(true, false, false, false, false);
    delay(50000);

    print("💡 ");
    setGPIOs(true, true, false, false, false);
    delay(50000);

    print("💡 ");
    setGPIOs(true, true, true, false, false);
    delay(50000);

    print("💡 ");
    setGPIOs(true, true, true, true, false);
    delay(50000);

    print("💡");
    setGPIOs(true, true, true, true, true);
    delay(50000);
    
    print("\033[80D\033[K");
    setGPIOs(false, false, false, false, false);
    delay(50000);
  }

  readchar();

  return 0;
}


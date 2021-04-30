/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v2
 * ------------------------------------------------------------
 * Copyright (c)2020-2021 Ross Bamford and contributors
 * See top-level LICENSE.md for licence information.
 *
 * rosco_m68k GPIO interface
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdbool.h>
#include <machine.h>

#include "gpio.h"

static volatile uint8_t * const mfp_gpdr = (uint8_t * const)MFP_GPDR;
static volatile uint8_t * const mfp_ddr = (uint8_t * const)MFP_DDR;

void pinMode(GPIO pin, PINMODE mode) {
  if (mode == pin_mode_output) {
    *mfp_ddr |= pin;
  } else {
    *mfp_ddr &= ~pin;
  }
}

bool digitalRead(GPIO pin) {
  return (*mfp_gpdr & pin) == pin;
}

void digitalWrite(GPIO pin, bool value) {
  if (value) {
    *mfp_gpdr |= pin; 
  } else {
    *mfp_gpdr &= ~pin;
  }
}

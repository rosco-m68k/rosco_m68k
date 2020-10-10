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
 * rosco_m68k GPIO interface
 * ------------------------------------------------------------
 */

#ifndef ROSCO_M68K_GPIO_H
#define ROSCO_M68K_GPIO_H

typedef enum GPIOMask {
  pin_gpio1 = 0x04,
  pin_gpio2 = 0x08,
  pin_gpio3 = 0x10,
  pin_gpio4 = 0x20,
  pin_gpio5 = 0x40
} GPIO;

typedef enum GPIOMode {
  pin_mode_input = 0x00,
  pin_mode_output = 0x01
} PINMODE; 

#ifndef ROSCOM68K_QUIET_INCLUDES
#define GPIO1     pin_gpio1
#define GPIO2     pin_gpio2
#define GPIO3     pin_gpio3
#define GPIO4     pin_gpio4
#define GPIO5     pin_gpio5

#define INPUT     pin_mode_input
#define OUTPUT    pin_mode_output
#endif

void pinMode(GPIO pin, PINMODE mode);
void digitalWrite(GPIO pin, bool value);
bool digitalRead(GPIO pin);

#endif

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

#include <stdbool.h>

// bit number for rosco_m68k MFP GPIO
typedef enum GPIONumber {
  led_green_b = 0,   // active low green LED1
  led_red_b   = 1,   // active low red LED2
  pin_gpio1_b = 2,   // J5-pin 1
  pin_gpio2_b = 3,   // J5-pin 3
  pin_gpio3_b = 4,   // J5-pin 5
  pin_gpio4_b = 5,   // J5-pin 7
  pin_gpio5_b = 6,   // J5-pin 9
  pin_cts_b   = 7,   // JP1-CTS UART handshake pin
} GPIOBitNum;

// bit mask for rosco_m68k MFP GPIO
typedef enum GPIOMask {
  led_green = (1<<led_green_b),
  led_red   = (1<<led_red_b),
  pin_gpio1 = (1<<pin_gpio1_b),
  pin_gpio2 = (1<<pin_gpio2_b),
  pin_gpio3 = (1<<pin_gpio3_b),
  pin_gpio4 = (1<<pin_gpio4_b),
  pin_gpio5 = (1<<pin_gpio5_b),
  pin_cts   = (1<<pin_cts_b),
} GPIO;

// MFP_DDR register input/output select (1 bit per GPIO)
typedef enum GPIOMode {
  pin_mode_input  = 0x00,
  pin_mode_output = 0x01
} PINMODE; 

#ifndef ROSCOM68K_QUIET_INCLUDES

#define LED_GREEN   led_green
#define LED_RED     led_red
#define GPIO1       pin_gpio1
#define GPIO2       pin_gpio2
#define GPIO3       pin_gpio3
#define GPIO4       pin_gpio4
#define GPIO5       pin_gpio5
#define UART_CTS    pin_cts

#define LED_GREEN_B led_green_b
#define LED_RED_B   led_red_b
#define GPIO1_B     pin_gpio1_b
#define GPIO2_B     pin_gpio2_b
#define GPIO3_B     pin_gpio3_b
#define GPIO4_B     pin_gpio4_b
#define GPIO5_B     pin_gpio5_b
#define UART_CTS_B  pin_cts_b

#define INPUT     pin_mode_input
#define OUTPUT    pin_mode_output

#endif

void pinMode(GPIO pin, PINMODE mode);
void digitalWrite(GPIO pin, bool value);
bool digitalRead(GPIO pin);

#endif

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
 * C linkage and initialisation sanity checker.
 *
 * This just places some data in both .data and .bss sections
 * and checks that both get initialised to the expected values.
 *
 * This isn't an exhaustive check but can be a good indicator
 * of linkage problems...
 * ------------------------------------------------------------
 */

#include <stdint.h>
#include <stdbool.h>
#include <basicio.h>
#include "include/linkcheck.h"

uint32_t d = 0x12345678;
static uint8_t stb[15];
uint8_t a[] = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 };

bool checkLinkage() {
  println("\033[1;37mRunning C linkage checks...\033[0m");
  bool result = false;

  uint32_t aloc = (uint32_t)a;
  if (aloc > 0x28000) {
    print("\033[1;31mFAIL:\033[0m a is still located high; at 0x");
    printuint(aloc);
    println("\033[0m");
  } else {
    print("\033[1;32mPASS:\033[0m a is located as expected; at 0x");
    printuint(aloc);
    println("\033[0m");
    
    result = d == 0x12345678;

    if (!result) {
      print("\033[1;31FAIL:\033[0m Unexpected value in .data[d]: 0x");
      printuint(d);
      println("\033[0m");
    } else {
      println("\033[1;32mPASS:\033[0m .data[d] checks out...\033[0m");

      for (int i = 0; i < 16; i++) {
        if (a[i] != i) {
          print("\033[1;31m");
          result = false;
        } else {
          print("\033[1;32m");
        }
        printuchar(a[i]);
        print(" ");
      }
      println("\033[0m");

      if (!result) {
        println("\033[1;31mFAIL:\033[0m Unexpected value in .data[a]!\033[0m");
      } else {
        println("\033[1;32mPASS:\033[0m .data[a] checks out...\033[0m");

        for (int i = 0; i < 15; i++) {
          if (stb[i] != 0) {
            print("\033[1;31m");
            result = false;
          } else {
            print("\033[1;32m");
          }
          printuchar(stb[i]);
          print(" ");
        }
        println("\033[0m");

        if (!result) {
          println("\033[1;31mFAIL:\033[0m Unexpected value in .bss[stb]!\033[0m");
        } else {
          println("\033[1;32mPASS:\033[0m .bss[stb] checks out...\033[0m");
        }
      }
    }
  }

  if (result) {
    print("\033[1;32mPASS:\033[1;37m ");
  } else {
    print("\033[1;31mFAIL:\033[1;37m ");
  }
  println("Linkage checks complete, press a key\033[0m");

  readchar();

  return result;
}


/*
 * vim: set et ts=2 sw=2
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 * ------------------------------------------------------------
 * Copyright (c) 2020 Xark
 * MIT License
 * ------------------------------------------------------------
 */

// This is the rosco_m68k re-mixed version of Adafruit's library
// Not a huge amount of code left from the Adafruit library, but
// it was helpful and here is the original copyright notice:

/***************************************************
  This is an Arduino Library for the Adafruit 2.2" SPI display.
  This library works with the Adafruit 2.2" TFT Breakout w/SD card
  ----> http://www.adafruit.com/products/1480

  Check out the links above for our tutorials and wiring diagrams
  These displays use SPI to communicate, 4 or 5 pins are required to
  interface (RST is optional)
  Adafruit invests time and resources providing this open source code,
  please support Adafruit and open-source hardware by purchasing
  products from Adafruit!

  Written by Limor Fried/Ladyada for Adafruit Industries.
  MIT license, all text above must be included in any redistribution
 ****************************************************/

// Color definitions
enum
{
  ILI9341_BLACK  = 0x0000,
  ILI9341_BLUE  = 0x001F,
  ILI9341_RED  = (int)0xF800,
  ILI9341_GREEN  = 0x07E0,
  ILI9341_CYAN  = 0x07FF,
  ILI9341_MAGENTA = (int)0xF81F,
  ILI9341_YELLOW  = (int)0xFFE0,
  ILI9341_WHITE  = (int)0xFFFF,
};


// ILI9341 commands
// See http://www.lcdwiki.com/2.2inch_SPI_Module_ILI9341_SKU:MSP2202
enum
{
  ILI9341_NOP = 0x00,
  ILI9341_SWRESET = 0x01,
  ILI9341_RDDID = 0x04,
  ILI9341_RDDST = 0x09,

  ILI9341_SLPIN = 0x10,
  ILI9341_SLPOUT = 0x11,
  ILI9341_PTLON = 0x12,
  ILI9341_NORON = 0x13,

  ILI9341_RDMODE = 0x0A,
  ILI9341_RDMADCTL = 0x0B,
  ILI9341_RDPIXFMT = 0x0C,
  ILI9341_RDIMGFMT = 0x0A,
  ILI9341_RDSELFDIAG = 0x0F,

  ILI9341_INVOFF = 0x20,
  ILI9341_INVON = 0x21,
  ILI9341_GAMMASET = 0x26,
  ILI9341_DISPOFF = 0x28,
  ILI9341_DISPON = 0x29,

  ILI9341_CASET = 0x2A,
  ILI9341_PASET = 0x2B,
  ILI9341_RAMWR = 0x2C,
  ILI9341_RAMRD = 0x2E,

  ILI9341_PTLAR = 0x30,
  ILI9341_VSCRDEF = 0x33,
  ILI9341_MADCTL = 0x36,
  ILI9341_VSCRSADD = 0x37,
  ILI9341_IDMOFF = 0x38,
  ILI9341_IDMON = 0x39,
  ILI9341_PIXFMT = 0x3A,

  ILI9341_GETSCAN = 0x45,

  ILI9341_FRMCTR1 = 0xB1,
  ILI9341_FRMCTR2 = 0xB2,
  ILI9341_FRMCTR3 = 0xB3,
  ILI9341_INVCTR = 0xB4,
  ILI9341_DFUNCTR = 0xB6,

  ILI9341_PWCTR1 = 0xC0,
  ILI9341_PWCTR2 = 0xC1,
  ILI9341_PWCTR3 = 0xC2,
  ILI9341_PWCTR4 = 0xC3,
  ILI9341_PWCTR5 = 0xC4,
  ILI9341_VMCTR1 = 0xC5,
  ILI9341_VMCTR2 = 0xC7,

  ILI9341_RDID1 = 0xDA,
  ILI9341_RDID2 = 0xDB,
  ILI9341_RDID3 = 0xDC,
  ILI9341_RDID4 = 0xDD,

  ILI9341_GMCTRP1 = 0xE0,
  ILI9341_GMCTRN1 = 0xE1,

  // ILI9341_PWCTR6    = 0xFC,
};

// some other misc. constants
enum
{
  // screen dimensions
  ILI9341_TFTWIDTH = 240,
  ILI9341_TFTHEIGHT = 320,

  // MADCTL bits
  ILI9341_MADCTL_MH = 0x04,  // bit 2 = 0 for refresh left -> right, 1 for refresh right -> left
  ILI9341_MADCTL_RGB = 0x00, // bit 3 = 0 for RGB color order
  ILI9341_MADCTL_BGR = 0x08, // bit 3 = 1 for BGR color order
  ILI9341_MADCTL_ML = 0x10,  // bit 4 = 0 for refresh top -> bottom, 1 for bottom -> top
  ILI9341_MADCTL_MV = 0x20,  // bit 5 = 0 for column, row order (portrait), 1 for row, column order (landscape)
  ILI9341_MADCTL_MX = 0x40,  // bit 6 = 0 for left -> right, 1 for right -> left order
  ILI9341_MADCTL_MY = 0x80,  // bit 7 = 0 for top -> bottom, 1 for bottom -> top

  // delay indicator bit for commandList()
  DELAY = 0x80
};

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

// This is the rosco_m68k re-mixed version of Adafruit's library.
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

// You can help support Adafruit by buying one of their LCD modules. I believe
// this code is compatible with the "SPI mode" of these:
// 2.4" TFT LCD Breakout - https://www.adafruit.com/product/2478
// 2.8" TFT LCD Breakout - https://www.adafruit.com/product/1770
// 3.2" TFT LCD Breakout - https://www.adafruit.com/product/1743

#include <stdint.h>
#include <stdlib.h>
#include <basicio.h>
#include <machine.h>
#include <gpio.h>

// Include GPIO SPI routines
// NOTE: SPI_FAST makes SPI routines inline (can bloat code size)
#define SPI_FAST
#include <gpio_spi.h>

#include "lcd-ili9341.h"  // definitions for ILI9341 LCD

#include "rle_images.h"   // test image data (created by images/Makefile)

// define INLINE as nothing to trade some speed for size
#define INLINE  inline

// LCD modules: Most generic modules SPI LCD 320x240x16-bit color modules that
// use ILI9341 or ILI9342.
//
// I believe ILI9341 vs ILI9342 is default of 240x320 or 320x240, but the
// orientation can be changed in software anyways.
//
// The module I am using is fairly common 2.2" ILI9341 SPI TFT LCD with a 9
// pin connector (and an additional SD card connection that is not used).
// Other pinouts are common and can work fine also.
//
// Here is a good reference similar to the one I am using:
// http://www.lcdwiki.com/2.2inch_SPI_Module_ILI9341_SKU:MSP2202
//
// GPIO pin definitions for the LCD module I am using:
// 1          | VCC      | 5V / 3.3V power input        | VCC         |
// 2          | GND      | Ground                       | GND         |
// 3          | CS       | Chip select (active low)     | J5-P1 GPIO1 |
// 4          | RESET    | LCD reset (active low)       | J3-P36 RESET| *
// 5          | DC/RS    | Data/command register select | J5-P9 GPIO5 |
// 6          | COPI     | SPI data write to LCD        | J5-P5 GPIO3 |
// 7          | SCK      | SPI clock signal             | J5-P3 GPIO2 |
// 8          | LED      | LED backlight pin            | VCC         |
// 9          | CIPO     | SPI data read from LCD       | J5-P7 GPIO4 |
//
// * RESET signal is optional (there is software reset sequence)

// number of elements in C array
#define ELEMENTS(a) ((int)(sizeof(a) / sizeof (*a)))

// macro for easier MFP register access (read or write)
#define MFP(reg) (*(volatile uint8_t *)MFP_ ## reg)

// wait for ms milliseconds (with granularity of 10 ms, rounded up)
static void delayms(uint32_t ms)
{
  uint16_t ms10 = (uint16_t)(ms+9) / (uint16_t)10U;
  mcDelaymsec10(ms10);
}

// timer helpers
static uint32_t start_tick;
void timer_start()
{
  uint32_t ts = _TIMER_100HZ;
  uint32_t t;
  while ((t = _TIMER_100HZ) == ts)
    ;
  start_tick = t;
}

uint32_t timer_stop()
{
  uint32_t stop_tick = _TIMER_100HZ;

  return (stop_tick - start_tick) * 10;
}

// from https://stackoverflow.com/questions/21001659
unsigned int crc32b(unsigned char *message, int count)
{
  int i, j;
  unsigned int byte, crc, mask;

  crc = 0xFFFFFFFF;
  for (i = 0; i < count; i++)
  {
    byte = message[i]; // Get next byte.
    crc = crc ^ byte;
    for (j = 7; j >= 0; j--)
    { // Do eight times.
      mask = -(crc & 1);
      crc = (crc >> 1) ^ (0xEDB88320 & mask);
    }
  }
  return ~crc;
}

// LCD helpers
static inline uint16_t color565(uint32_t r, uint32_t g, uint32_t b)
{
  return ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3);
}

// special LCD data/control register select (1/0)
#define LCD_DCRS_B  GPIO5_B
#define LCD_DCRS    (1<<LCD_DCRS_B)

// initialize GPIO data-direction for SPI LCD
static inline void spi_init()
{
  // set data-direction for SPI signals (outputs, except CIPO)
  MFP(DDR) = (MFP(DDR)|SPI_CS|SPI_SCK|SPI_COPI|LCD_DCRS) & ~(SPI_CIPO);
}

// begin LCD command
static inline void lcd_begin_cmd()
{
  // CS selected (low)
  // LCD DCRS command mode (low)
  // SCK idle (high)
  // COPI one (high)
  MFP(GPDR) = (MFP(GPDR)|SPI_SCK|SPI_COPI) & ~(SPI_CS|LCD_DCRS);
}

// begin LCD data
static inline void lcd_begin()
{
  // CS selected (low)
  // LCD DCRS data mode (high)
  // SCK idle (high)
  // COPI one (high)
  MFP(GPDR) = (MFP(GPDR)|SPI_SCK|SPI_COPI|LCD_DCRS) & ~(SPI_CS);
}

// end LCD command/data
static inline void lcd_end()
{
  // CS de-selected (high)
  // LCD DCRS data mode (high)
  // SCK idle (high)
  // COPI one (high)
  MFP(GPDR) = (MFP(GPDR)|SPI_CS|SPI_SCK|SPI_COPI|LCD_DCRS);
}

// using macros here to allow testing/experimentation
#define SPI_SEND_BYTE(b)          spi_send_byte(b)
#define SPI_SEND_BUFFER(p, c)     spi_send_buffer(p, c)
#define SPI_READ_BYTE()           spi_read_byte()
#define SPI_READ_BUFFER(p, c)     spi_read_buffer(p,c)
#define SPI_EXCHANGE_BYTE(b)      spi_exchange_byte(b)
#define SPI_EXCHANGE_BUFFER(p, c) spi_exchange_buffer(p, c)

static INLINE void lcd_command(uint32_t byte)
{
  lcd_begin_cmd();        // cmd mode
  SPI_SEND_BYTE(byte);     // send command byte
  lcd_begin();            // data mode
}

static INLINE void lcd_write(uint32_t byte)
{
  SPI_SEND_BYTE(byte);
}

static INLINE void lcd_write16(uint32_t data)
{
  SPI_SEND_BYTE(data>>8);
  SPI_SEND_BYTE(data);
}

static INLINE void lcd_write16_count(uint32_t data, int count)
{
  while (count-- > 0)
  {
    lcd_write16(data);
  }
}

// LCD control
static int16_t _width, _height;
static uint8_t _rotation;

// set rectangular data window
static void lcd_set_window(int x0, int y0, int x1, int y1)
{
  lcd_command(ILI9341_CASET);   // column address set
  lcd_write16(x0);              // XSTART
  lcd_write16(x1);              // XEND
  lcd_command(ILI9341_PASET);   // row address set
  lcd_write16(y0);              // YSTART
  lcd_write16(y1);              // YEND
  lcd_command(ILI9341_RAMWR);   // write to RAM
}

// set LCD orientation
static void lcd_set_rotation(int m)
{
	_rotation = (m & 3); // can't be higher than 3

	lcd_command(ILI9341_MADCTL);

	switch (_rotation)
	{
	default:
	case 0:
		lcd_write(ILI9341_MADCTL_MX | ILI9341_MADCTL_BGR);
		_width	= ILI9341_TFTWIDTH;
		_height = ILI9341_TFTHEIGHT;
		break;
	case 1:
		lcd_write(ILI9341_MADCTL_MV | ILI9341_MADCTL_BGR);
		_width	= ILI9341_TFTHEIGHT;
		_height = ILI9341_TFTWIDTH;
		break;
	case 2:
		lcd_write(ILI9341_MADCTL_MY | ILI9341_MADCTL_BGR);
		_width	= ILI9341_TFTWIDTH;
		_height = ILI9341_TFTHEIGHT;
		break;
	case 3:
		lcd_write(ILI9341_MADCTL_MV | ILI9341_MADCTL_MY | ILI9341_MADCTL_MX | ILI9341_MADCTL_BGR);
		_width	= ILI9341_TFTHEIGHT;
		_height = ILI9341_TFTWIDTH;
		break;
	}

  lcd_set_window(0, 0, _width-1, _height-1);

}

// LCD vertical scroll (0-319)
void lcd_scroll(uint16_t y)
{
  lcd_command(ILI9341_VSCRSADD);
  lcd_write16(y);
}

// LCD scroll margin
void lcd_scrollmargin(uint16_t top, uint16_t bottom)
{
  // TFA+VSA+BFA must equal 320
  if (top + bottom <= ILI9341_TFTHEIGHT) {
    uint16_t middle = ILI9341_TFTHEIGHT - top + bottom;
    lcd_command(ILI9341_VSCRDEF);
    lcd_write16(top);
    lcd_write16(middle);
    lcd_write16(bottom);
  }
}

// sends "magic" commands to init display
static void lcd_init()
{
  // Initialization commands for ILI9341 screens
  static const uint8_t ILI9341_cmds[] =
  {
      ILI9341_SWRESET, DELAY,
      0xEF, 3,
      0x03, 0x80, 0x02,
      0xCF, 3,
      0x00, 0xC1, 0x30,
      0xED, 4,
      0x64, 0x03, 0x12, 0x81,
      0xE8, 3,
      0x85, 0x00, 0x78,
      0xCB, 5,
      0x39, 0x2C, 0x00, 0x34, 0x02,
      0xF7, 1,
      0x20,
      0xEA, 2,
      0x00, 0x00,
      ILI9341_PWCTR1, 1,        // power control
      0x23,                     // VRH[5:0]
      ILI9341_PWCTR2, 1,        // 10 power control
      0x10,                     // SAP[2:0];BT[3:0]
      ILI9341_VMCTR1, 2,        // VCM control
      0x3e, 0x28,
      ILI9341_VMCTR2, 1,        // VCM control2
      0x86,
      ILI9341_MADCTL, 1,
      (ILI9341_MADCTL_MX),// | ILI9341_MADCTL_BGR),
      ILI9341_VSCRSADD, 2,
      0x00, 0x00,
      ILI9341_PIXFMT, 1,
      0x55,
      ILI9341_FRMCTR1, 2,
      0x00, 0x18,
      ILI9341_DFUNCTR, 3,
      0x08, 0x82, 0x27,
      0xF2, 1,                  // Gamma Function Disable
      0x00,
      ILI9341_GAMMASET, 1,      // Gamma curve selected
      0x01,
      ILI9341_GMCTRP1, 15,      // Set Gamma
      0x0F, 0x31, 0x2B, 0x0C, 0x0E, 0x08, 0x4E, 0xF1, 0x37, 0x07, 0x10, 0x03, 0x0E, 0x09, 0x00,
      ILI9341_GMCTRN1, 15,
      0x00, 0x0E, 0x14, 0x03, 0x11, 0x07, 0x31, 0xC1, 0x48, 0x08, 0x0F, 0x0C, 0x31, 0x36, 0x0F,
      ILI9341_SLPOUT, DELAY,
      ILI9341_DISPON, 0,
  };

  lcd_end();

  const uint8_t *addr = &ILI9341_cmds[0];

  while (addr < &ILI9341_cmds[sizeof(ILI9341_cmds)])        // For each command...
  {
    uint8_t cmd = *addr++;  // read command
    lcd_command(cmd);       // issue command
    uint8_t  numArgs = *addr++;     // Number of args to follow
    if (numArgs == DELAY)
    {
      delayms(150);
    }
    else
    {
      while (numArgs--)       // For each argument...
      {
        uint8_t arg = *addr++;
        lcd_write(arg);   // Read, issue argument
      }
    }
  }

  lcd_set_rotation(0);

  lcd_end();
}

// LCD rectangle fill
void lcd_fill_rect(int x, int y, int w, int h, uint32_t color)
{
    // rudimentary clipping (drawChar w/big text requires this)
    if ((x >= _width) || (y >= _height))
        return;
    if (x < 0)
    {
        w += x;
        x = 0;
    }
    if (y < 0)
    {
        h += y;
        y = 0;
    }
    if ((x + w) > _width)
        w = _width  - x;
    if ((y + h) > _height)
        h = _height - y;

    lcd_set_window(x, y, x+w-1, _height);

    for (; h > 0; h--)
    {
        lcd_write16_count(color, w);
    }

  lcd_end();
}

uint8_t RGB888Buffer[320*240*3];

void lcd_readimage()
{
  lcd_set_rotation(1);

  lcd_command(ILI9341_CASET);   // column address set
  lcd_write16(0);               // XSTART
  lcd_write16(_width-1);        // XEND
  lcd_command(ILI9341_PASET);   // row address set
  lcd_write16(0);               // YSTART
  lcd_write16(_height-1);       // YEND
  lcd_command(ILI9341_RAMRD);   // read from RAM

  SPI_READ_BYTE();
  SPI_READ_BUFFER(RGB888Buffer, sizeof(RGB888Buffer));

  lcd_end();
}

int lcd_readscanline()
{
  lcd_command(ILI9341_GETSCAN);
  SPI_READ_BYTE();
  int r = SPI_READ_BYTE() << 8;
  r |= SPI_READ_BYTE();

  lcd_end();

  return r;
}

void testRGB(uint16_t* rgbimg)
{
  lcd_set_rotation(1);

  SPI_SEND_BUFFER(rgbimg, 320*240*2);

  lcd_end();
}

void testRLE1(uint8_t* rleimg, uint32_t backcolor, uint32_t forecolor)
{
  int32_t total = 0;
  int32_t cnt = 0;
  uint32_t curcolor = backcolor;
  uint32_t colorxor = backcolor ^ forecolor;

  const uint8_t *cmp = rleimg;

  lcd_set_rotation(1);

  while (total < (320 * 240))
  {
    cnt = *cmp++;
    if (cnt & 0x80)
        cnt = ((cnt & 0x7f) << 8) | *cmp++;

    lcd_write16_count(curcolor, cnt);
    curcolor ^= colorxor;
    total += cnt;
  }

  lcd_end();
}

void testRLE(uint16_t *p)
{
  static uint32_t color2;

  lcd_set_rotation(1);

  for (;;)
  {
    uint32_t color = *p++;
    color2 = color & ~0x0020;
    if (color != color2)
    {
      uint32_t count = *p++;
      if (count == 0xffff)
      {
        break;
      }
      lcd_write16_count(color2, count);
    }
    else
    {
      lcd_write16(color2);
    }
  }

  lcd_end();
}

static uint16_t colortable[] =
{
  ILI9341_BLACK,
  ILI9341_BLUE,
  ILI9341_RED,
  ILI9341_GREEN,
  ILI9341_CYAN,
  ILI9341_MAGENTA,
  ILI9341_YELLOW,
  ILI9341_WHITE
};

void kmain()
{
  delayms(250);  // give minicom a chance to load after kermit

  println("");
  println("*** TFT LCD Module Example ***");
  println("          by Xark");
  println("(built on " __DATE__ " at " __TIME__ ")");
  println("");
  print("rosco_m68k firmware version: ");
  printushort(_FIRMWARE_REV>>16);
  print(".");
  printuchar(_FIRMWARE_REV>>8);
  print(".");
  printuchar(_FIRMWARE_REV);
  println("");

  println("This is an example of using rosco_m68k GPIO to");
  println("control a common ILI9341/ILI9342 TFT LCD SPI");
  println("display module.");

  println("Initializing LCD...");

  spi_init(); // setup MFP GPIO port data-direction
  lcd_init(); // send initialization sequence to LCD module

  println("Done.  Now look at the LCD display. :)");
  println("");
  lcd_fill_rect((_width/2)-4, 0,  8, _height, ILI9341_GREEN);
  lcd_fill_rect(0, (_height/2)-4, _width, 8, ILI9341_GREEN);
  println("Press any key to exit.");
  println("");

  uint16_t hadcolor = 0;
  int count = 0;
  int img = 0;
  do
  {
    print("#");
    printuint(count);
    print(" Test:\"");
    print(image_name[img]);
    print("\" ");
    print(image_type[img] == 1 ? "RLE555" : image_type[img] == 2 ? "MONO" : "RGB");
    println("");

    print("  Draw...       ");
    timer_start();

    if (image_type[img] == 0)
      testRGB(image_data[img]);
    else if (image_type[img] == 1)
      testRLE(image_data[img]);
    else if (image_type[img] == 2)
    {
      testRLE1(image_data[img], colortable[hadcolor % ELEMENTS(colortable)], colortable[hadcolor+1 % ELEMENTS(colortable)]);
      hadcolor++;
    }

    uint32_t ticks = timer_stop();

    print("  Time:");
    printuint(ticks);
    println(" ms");
    delayms(2000);

#if 1 // smooth scroll test

    print("  Scroll...     ");
    timer_start();
    lcd_set_rotation(0);

    for (int s = 0; s < 320; s++)
    {
      int line1, line2;
      line1 = lcd_readscanline();
      do
      {
        line2 = lcd_readscanline();
      } while (line1 < line2);
      lcd_scroll(s);
      line1 = lcd_readscanline();
      do
      {
        line2 = lcd_readscanline();
      } while (line1 < line2);
    }
    lcd_scroll(0);

    ticks = timer_stop();

    print("  Time:");
    printuint(ticks);
    println(" ms");
    delayms(2000);

#endif

    print("  Read RGB888...");

    timer_start();

    lcd_set_rotation(1);

    lcd_readimage();

    ticks = timer_stop();

    print("  Time:");
    printuint(ticks);
    print(" ms (CRC32:");
    printuint(crc32b(RGB888Buffer, sizeof (RGB888Buffer)));
    println(")");

    print("  Draw RGB565...");

    // convert RGB888 to RGB565 (with inverted checkerboard)
    static uint16_t RGB565Buffer[320*240];

    uint8_t *src = RGB888Buffer;
    uint16_t *dst = RGB565Buffer;
    for (int y = 0; y < 240; y++)
    {
      for (int x = 0; x < 320; x++)
      {
        uint16_t c = color565(src[0], src[1], src[2]);
        *dst++ = ((y^x) & 0x40) ? c : ~c;
        src += 3;
      }
    }

    timer_start();

    lcd_set_rotation(1);

    testRGB(RGB565Buffer);

    ticks = timer_stop();

    print("  Time:");
    printuint(ticks);
    println(" ms");
    delayms(2000);

    img += 1;
    if (img >= ELEMENTS(image_data))
    {
      img = 0;
    }
    count++;
  }
  while (!(MFP(RSR)&0x80)); // loop until a char is waiting in UART buffer

  // restore GPIO data-direction and turn off LEDs
  MFP(DDR) = UART_CTS|LED_RED|LED_GREEN;
  MFP(GPDR) = LED_RED|LED_GREEN;

  println("");
  // invoke Rosco Paranoid Android(TM) module
  println("A brain the size of a planet, and they ask me to drive an LCD...");
}

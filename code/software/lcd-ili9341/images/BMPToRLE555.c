// Hacktastic "write-only" Q & D BMP -> rosco_m668k RLE LCD cruncher

// *** You have been warned! :D ***

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <time.h>
#include <ctype.h>

enum
{
  RGB565_TYPE,
  RLE555_TYPE,
  RLE1_TYPE
};
int num_images = 0;
char *image_names[256];
int image_type[256];

char bmp_name[128];
uint8_t bmp_header[54];
uint32_t pixel_offset;
uint32_t dib_size;
int32_t bmp_width;
int32_t bmp_height;
int16_t bmp_bpp;
uint32_t bmp_line;
uint32_t bmp_size;
uint8_t *RGB24_bitmap;
int32_t *y_bitmap;

int32_t width;
int32_t height;
uint16_t *lcd_bitmap;

bool rle_flag = false;
bool noise_flag = false;
bool mono_flag = false;
//
// read_bmp - there is still time to escape!
//
void read_bmp(const char *name)
{
  FILE *f = NULL;

  if ((f = fopen(name, "rb")) == NULL)
  {
    fprintf(stderr, "Error opening input BMP file \"%s\".\n", name);
    exit(5);
  }

  if (fread(bmp_header, sizeof(unsigned char), 54, f) != 54)
  {
    fprintf(stderr, "Error reading BMP header from \"%s\".\n", name);
    exit(5);
  }

  if (bmp_header[0] != 'B' || bmp_header[1] != 'M')
  {
    fprintf(stderr, "Error not valid BMP format \"%s\".\n", name);
    exit(5);
  }

  pixel_offset = bmp_header[10] | (bmp_header[11] << 8) | (bmp_header[12] << 16) | (bmp_header[13] << 24);
  dib_size = bmp_header[14] | (bmp_header[15] << 8) | (bmp_header[16] << 16) | (bmp_header[17] << 24);

  if (dib_size != 40)
  {
    fprintf(stderr, "Error unsupported BMP format DIB=%d \"%s\".\n", dib_size, name);
    exit(5);
  }

  // extract image height and width from header
  bmp_width = bmp_header[18] | (bmp_header[19] << 8) | (bmp_header[20] << 16) | (bmp_header[21] << 24);
  bmp_height = bmp_header[22] | (bmp_header[23] << 8) | (bmp_header[24] << 16) | (bmp_header[25] << 24);
  if (bmp_width < 0)
    bmp_width = -bmp_width;
  if (bmp_height < 0)
    bmp_height = -bmp_height;
  bmp_bpp = bmp_header[28] | (bmp_header[29] << 8);

  if (bmp_width < 8 || bmp_width > 8192 || bmp_height < 8 || bmp_height > 8192 || bmp_bpp != 24)
  {
    fprintf(stderr, "BMP \"%s\" size or depth fails sanity check (%d x %d bpp=%d).\n", name, bmp_width,
            bmp_height, bmp_bpp);
    exit(5);
  }

  bmp_line = (((bmp_width * bmp_bpp) + 31) / 32) * 4;

  bmp_size = bmp_line * bmp_height;
  RGB24_bitmap = realloc(RGB24_bitmap, bmp_size);
  if (!RGB24_bitmap)
  {
    fprintf(stderr, "Failed allocating %d bytes.\n", bmp_size);
    exit(5);
  }
  memset(RGB24_bitmap, 0, bmp_size);

  // seek to bitmap pixels and read them in
  if (fseek(f, pixel_offset, SEEK_SET) != 0 || fread(RGB24_bitmap, sizeof(unsigned char), bmp_size, f) != bmp_size)
  {
    fprintf(stderr, "Error reading %d bytes of BMP data from \"%s\".\n", bmp_size, name);
    exit(5);
  }
  fclose(f);

  memset(bmp_name, 0, sizeof(bmp_name));
  strncpy(bmp_name, name, sizeof(bmp_name) - 1);
  char *dot = strchr(bmp_name, '.');
  if (dot)
    *dot = '\0';
  for (int i = 0; i < strlen(bmp_name); i++)
  {
    if (!isalnum(bmp_name[i]))
      bmp_name[i] = '_';
  }
}

//
// main - turn back now!
//
int main(int argc, char *argv[])
{
  if (argc < 2)
  {
    printf("%s <BMP_file> [ <BMP_file> ... ]\n", argv[0]);
    exit(EXIT_FAILURE);
  }

  srand(time(NULL));

  printf("// created for rosco_m68k with BMPToRLE555\n");
  printf("\n");
  printf("#include <stdint.h>\n");

  for (int a = 1; a < argc; a++)
  {
    if (argv[a][0] == '-')
    {
      if (argv[a][1] == 'n')
      {
        noise_flag = !noise_flag;
        continue;
      }
      else if (argv[a][1] == 'c')
      {
        rle_flag = true;
        mono_flag = false;
        continue;
      }
      else if (argv[a][1] == 'm')
      {
        mono_flag = true;
        rle_flag = false;
        continue;
      }
      else if (argv[a][1] == 'u')
      {
        mono_flag = false;
        rle_flag = false;
        continue;
      }
      else
      {
        fprintf(stderr, "Unexpected option: %s\n", argv[a]);
        exit(EXIT_FAILURE);
      }
    }

    read_bmp(argv[a]);

    if (bmp_width > 320 || bmp_height > 240)
    {
      printf("BMP is %d x %d, but needs to be <= 320 x 240\n", bmp_width, bmp_height);
      exit(EXIT_FAILURE);
    }

    width = bmp_width;
    height = bmp_height;

    image_names[num_images] = strdup(bmp_name);
    printf("\n// \"%s\": %d x %d\n", bmp_name, bmp_width, bmp_height);

    if (noise_flag)
    {
      printf("// +/- 4 noise added to \"%s\"\n", bmp_name);
      // quantize to RGB555 with a bit of noise
      for (int y = 0; y < bmp_height; y++)
      {
        for (int x = 0; x < bmp_width; x++)
        {
          uint8_t *rgb = &RGB24_bitmap[((bmp_height - 1 - y) * bmp_line) + (x * 3)];
          float rj = ((float)rand() / (float)(RAND_MAX / 6.0) - 3.0) + rgb[2];
          uint8_t r = (uint8_t)((rj < 0) ? 0 : (rj > 0xff) ? 0xff : rj) & 0xf8;
          rgb[2] = r;
          float gj = ((float)rand() / (float)(RAND_MAX / 6.0) - 3.0) + rgb[1];
          uint8_t g = (uint8_t)((gj < 0) ? 0 : (gj > 0xff) ? 0xff : gj) & 0xf8;
          rgb[1] = g;
          float bj = ((float)rand() / (float)(RAND_MAX / 6.0) - 3.0) + rgb[0];
          uint8_t b = (uint8_t)((bj < 0) ? 0 : (bj > 0xff) ? 0xff : bj) & 0xf8;
          rgb[0] = b;
        }
      }
    }

    if (rle_flag)
    {
      int out_count = 0;
      uint16_t repeat_pix_555 = 0;
      int repeat = 0;

      image_type[num_images] = RLE555_TYPE;
      printf("// RGB555 RLE compressed \"%s\"\n", bmp_name);
      printf("uint16_t %s_rle555[] = {\n  ", bmp_name);

      for (int y = 0; y < bmp_height; y++)
      {
        for (int x = 0; x < bmp_width; x++)
        {
          uint8_t *rgb = &RGB24_bitmap[((bmp_height - 1 - y) * bmp_line) + (x * 3)];
          uint8_t r = rgb[2];
          uint8_t g = rgb[1];
          uint8_t b = rgb[0];

          // 565, except low bit of green is used as a repeat flag
          uint16_t pix_555 = ((r & 0xF8) << 8) | ((g & 0xF8) << 3) | (b >> 3);
          if (x == 0 && y == 0)
          {
            repeat_pix_555 = pix_555;
          }

          if ((repeat_pix_555 != pix_555) || repeat >= 0xfffd)
          {
            // output repeat run (if any)
            if (repeat > 1)
            {
              // set green low bit as repeat flag
              printf("0x%04x%s", repeat_pix_555 | 0x20, (++out_count & 0xf) ? ", " : ",\n  ");
              printf("%6d%s", repeat, (++out_count & 0xf) ? ", " : ",\n  ");
            }
            else if (repeat == 1)
            {
              printf("0x%04X%s", repeat_pix_555, (++out_count & 0xf) ? ", " : ",\n  ");
            }

            repeat_pix_555 = pix_555;
            repeat = 1;
          }
          else
          {
            repeat++;
          }
        }
      }
      // output last repeat run
      if (repeat)
      {
        printf("0x%04x%s", repeat_pix_555 | 0x20, (++out_count & 0xf) ? ", " : ",\n  ");
        printf("%6d%s", repeat, (++out_count & 0xf) ? ", " : ",\n  ");
      }
      printf("0x%04x%s", 0xffff, (++out_count & 0xf) ? ", " : ",\n  " );
      printf("0x%04x\n", 0xffff);
      ++out_count;
      out_count *= 2;
      int full_size = width * height * 2;
      printf("}; // %s: Uncompressed:%7d, RLE555:%7d = %.03f%%\n", bmp_name, full_size, out_count, ((double)out_count / full_size) * 100.0);
      fprintf(stderr, "%-32.32s: Uncompressed:%7d, RLE555:%7d = %.03f%%\n", bmp_name, full_size, out_count, ((double)out_count / full_size) * 100.0);
    }
    else if (mono_flag)
    {
      uint32_t out_count = 0;
      uint32_t currun = 0;
      uint8_t curstate = 0;

      image_type[num_images] = RLE1_TYPE;
      printf("// RGB1 RLE mono compressed \"%s\"\n", bmp_name);
      printf("uint8_t %s_rle1[] = {\n  ", bmp_name);

      for (int y = 0; y < bmp_height; y++)
      {
        for (int x = 0; x < bmp_width; x++)
        {
          uint8_t *rgb = &RGB24_bitmap[((bmp_height - 1 - y) * bmp_line) + (x * 3)];
          uint8_t b = rgb[1] >= 0x80 ? 0x1 : 0x0;

          if (b == curstate && currun < 32767)
          {
            currun++;
          }
          else
          {
            if (currun < 128)
            {
              printf("0x%02x%s", currun, (++out_count & 0xf) ? ", " : ",\n  ");
            }
            else
            {
              printf("0x%02x%s", 0x80 | (currun >> 8), (++out_count & 0xf) ? ", " : ",\n  ");
              printf("0x%02x%s", (currun & 0xff), (++out_count & 0xf) ? ", " : ",\n  ");
            }
            currun = 1;
            curstate = !curstate;
          }
        }
      }
      // output last repeat run
      if (currun)
      {
        if (currun < 128)
        {
          printf("0x%02x%s", currun, (++out_count & 0xf) ? ", " : "\n  ");
        }
        else
        {
          printf("0x%02x%s", 0x80 | (currun >> 8), (++out_count & 0xf) ? ", " : ",\n  ");
          printf("0x%02x%s", (currun & 0xff), (++out_count & 0xf) ? ", " : "\n  ");
        }
      }

      int full_size = ((width+7)/8) * height;
      printf("\n}; // %s: Uncompressed:%7d, Compressed RLE1  :%7d\n", bmp_name, full_size, out_count);
      fprintf(stderr, "%-32.32s: Uncompressed:%7d, RLE1  :%7d = %.03f%%\n", bmp_name, full_size, out_count, ((double)out_count / full_size) * 100.0);

#if 0
      printf("\n// Test decompress:\n");
      printf("// ");

      int runcnt;
      int color = 0;
      int pixcount = 0;
      while (cmp < compout)
      {
        runcnt = *cmp++;
        if (runcnt & 0x80)
          runcnt = ((runcnt & 0x7f) << 8) | *cmp++;

        while (runcnt--)
        {
          printf("%d", color);
          if (++pixcount == bmp_width)
          {
            pixcount = 0;
            printf("\n// ");
          }
        }
        color ^= 1;
      }

      printf("\n\n");
#endif
    }
    else // uncompressed
    {
      image_type[num_images] = RGB565_TYPE;
      printf("// RGB565 uncompressed \"%s\"\n", bmp_name);
      printf("uint16_t %s_rgb565[] = {\n  ", bmp_name);

      int out_count = 0;
      for (int y = 0; y < bmp_height; y++)
      {
        for (int x = 0; x < bmp_width; x++)
        {
          uint8_t *rgb = &RGB24_bitmap[((bmp_height - 1 - y) * bmp_line) + (x * 3)];
          uint8_t r = rgb[2];
          uint8_t g = rgb[1];
          uint8_t b = rgb[0];

          uint16_t pix_565 = ((r & 0xF8) << 8) | ((g & 0xFc) << 3) | (b >> 3);

          printf("0x%04x%s", pix_565, (++out_count & 0xf) ? ", " : ",\n  ");
        }
      }
      out_count *= 2;
      printf("\n}; // %s: Uncompressed:%7d\n", bmp_name, out_count);
      fprintf(stderr, "%-32.32s: Uncompressed:%7d, RLE565:%7d\n", bmp_name, out_count, out_count);
    }

    num_images++;
  }

  printf("\nuint8_t	image_type[%d] = {\n  ", num_images);
  for (int i = 0; i < num_images; i++)
  {
    printf("%d%s", image_type[i], i == num_images - 1 ? "\n" : ", ");
  }
  printf("};\n");

  printf("char*	image_name[%d] = {\n  ", num_images);
  for (int i = 0; i < num_images; i++)
  {
    printf("\"%s\"%s ", image_names[i], i == num_images - 1 ? "" : ",");
  }
  printf("\n};\n");
  printf("void*	image_data[%d] = {\n  ", num_images);
  for (int i = 0; i < num_images; i++)
  {
    printf("%s_%s%s ", image_names[i], image_type[i] == RLE1_TYPE ? "rle1" :  image_type[i] == RLE555_TYPE ? "rle555" : "rgb565", i == num_images - 1 ? "" : ",");
  }
  printf("\n};\n");
  printf("\n// EOF\n");
  fprintf(stderr, "Done!\n");

  return 0;
}

// abandon all hope...

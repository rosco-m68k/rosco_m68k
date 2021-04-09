/** Rosco m68k 2d maze demo Matt Pearce (c) 2020 Mattpearce@me.com */

#include <stdlib.h>
#include <string.h>
#include "vterm.h"
#include <printf.h>
#include <machine.h>
#include <math.h>
#include <stdint.h>
#include <easy68k.h>

#define ASCII_VALID_START 0x20
#define ASCII_VALID_END 0x7E

#define MAX_ROWS  15
#define MAX_COLS  15
#define MAX_SQUARES	(MAX_ROWS*MAX_COLS)

#define BEEN_HERE 1<<7

uint8_t grid[MAX_SQUARES];

#define GetRow(sq)	(sq % MAX_ROWS)
#define GetCol(sq)	(sq / MAX_ROWS)

enum
{
   DIR_NORTH = 0,
   DIR_EAST,
   DIR_WEST,
   DIR_SOUTH,
   MAX_DIRS
};
const int offset[MAX_DIRS] = {-1, MAX_ROWS, -MAX_ROWS, 1};

uint8_t GetRandomDir()
{
   return rand() % MAX_DIRS;
}

uint16_t GetRandomSquare()
{
   return rand() % MAX_SQUARES;
}

void cputcxy(int x, int y, char c) {
    e68MoveXY(x,y);
    mcSendchar(c);
}

void cputsxy(int x, int y, char *c) {
    e68MoveXY(x,y);
    vt_send(c);
}

void DrawPos(uint16_t sq)
{
   const char wall = '#';
   uint8_t col = 1 + 2*GetCol(sq);
   uint8_t row = 1 + 2*GetRow(sq);
   uint8_t g = grid[sq];

   cputcxy(col+1, row+1, ' ');
   cputcxy(col,   row,   wall);
   cputcxy(col,   row+2, wall);
   cputcxy(col+2, row+2, wall);
   cputcxy(col+2, row,   wall);
   cputcxy(col+1, row,   (g&(1<<DIR_NORTH)) ? ' ' : wall);
   cputcxy(col+2, row+1, (g&(1<<DIR_EAST))  ? ' ' : wall);
   cputcxy(col,   row+1, (g&(1<<DIR_WEST))  ? ' ' : wall);
   cputcxy(col+1, row+2, (g&(1<<DIR_SOUTH)) ? ' ' : wall);
} // end of DrawPos


void InitMaze(void)
{
   int sq;
   int count;

      /* initialize vterm control library */
    vt_init();

    /* clear the screen and reset cursor to get rid of old junk data */
    vt_clear_screen();
    e68MoveXY(0,0);


   for(sq=0; sq<MAX_SQUARES; sq++)
   {
      grid[sq]=0;
   }

   sq = GetRandomSquare();
   count = MAX_SQUARES-1;
   while (count)
   {
      int dir = GetRandomDir();
      int newSq = sq + offset[dir];

      if ( ((GetRow(sq)==GetRow(newSq)) + (GetCol(sq)==GetCol(newSq)) == 1)
            && (newSq>=0) && (newSq<MAX_SQUARES) )
      {
         if (!grid[newSq])
         {	/* We haven't been here before. */

            /* Make an opening */
            grid[sq] += 1 << (dir); DrawPos(sq);
            sq = newSq;
            grid[sq] += 1 << ((MAX_DIRS-1) - dir); DrawPos(sq);
            count--;
         }
         else if (fabs(rand()) < fabs(rand())/6)
         {
            do
            {
               sq = GetRandomSquare();
            }
            while (!grid[sq]);
         }
      }
   }
} // end of InitMaze


void kmain()
{
   int curSq, printSq;

   InitMaze();

   /* Get random start square */
   curSq = MAX_SQUARES - 1;

   while (curSq >= 0)
   {
      int dir;
      if (!curSq)
      {
         cputsxy(1, 20, "You escaped!");
      }

      grid[curSq] |= BEEN_HERE;

      for (printSq=0; printSq<MAX_SQUARES; printSq++)
      {
         if (grid[printSq] & BEEN_HERE)
         {
            DrawPos(printSq);
         }
      }

      cputcxy(2+GetCol(curSq)*2, 2+GetRow(curSq)*2, curSq ? '@' : '*');
      e68MoveXY(2+GetCol(curSq)*2, 2+GetRow(curSq)*2);
      dir = MAX_DIRS;
      
      char in = mcReadchar();
      char in2 = mcReadchar();

      if (in == 0x1B && in2 == 0x5B) {
            char in = mcReadchar();
      /* Handle arrow keys */
            switch (in)
            {
                case 0x41:
                    dir = DIR_NORTH;
                    break;
                case 0x42:
                    dir = DIR_SOUTH;
                    break;
                case 0x43:
                    dir = DIR_EAST;
                    break;
                case 0x44:
                    dir = DIR_WEST;
                    break;
                case 'q': 
                    curSq = -1; 
                    break;
            }

      if (dir < MAX_DIRS)
      {
         if (grid[curSq] & (1<<dir))
         {
            curSq += offset[dir];
         }
      }
   }
   } // end of while (curSq >= 0)

} // end of main

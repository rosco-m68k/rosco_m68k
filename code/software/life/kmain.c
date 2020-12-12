#include <stdio.h>
#include <stdlib.h>
#include <machine.h>
#include <easy68k.h>

extern void mcBusywait(uint32_t nops);
 
#define for_x for (int x = 0; x < w; x++)
#define for_y for (int y = 0; y < h; y++)
#define for_xy for_x for_y

void show(void *u, int w, int h)
{
	int (*univ)[w] = u;
	printf("\033[H");
	for_y {
		for_x printf(univ[y][x] ? "\033[07m  \033[m" : "  ");
      printf("\r\n");
	}
   printf("\033[E");
}
 
void evolve(void *u, int w, int h)
{
	unsigned (*univ)[w] = u;
	unsigned new[h][w];
 
	for_y for_x {
		int n = 0;
		for (int y1 = y - 1; y1 <= y + 1; y1++)
			for (int x1 = x - 1; x1 <= x + 1; x1++)
				if (univ[(y1 + h) % h][(x1 + w) % w])
					n++;
 
		if (univ[y][x]) n--;
		new[y][x] = (n == 3 || (n == 2 && univ[y][x]));
	}
	for_y for_x univ[y][x] = new[y][x];
}
 
void game(int w, int h)
{
	unsigned univ[h][w];
	for_xy univ[y][x] = rand() < RAND_MAX / 10 ? 1 : 0;
	while (1) {
      	e68ClearScr();
		show(univ, w, h);
		evolve(univ, w, h);
		mcBusywait(10000);
	}
}
 
void kmain()
{
	int w = 30;
	int h = 30;
	game(w, h);
}
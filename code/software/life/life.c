#include <stdio.h>
#include <stdlib.h>
#include <machine.h>
#include <basicio.h>

// Good Xosera 106x30 defaults. :)
#define w	((106)/2)
#define h	(30-1)

static int generation;
static bool last[h][w];
static bool univ[h][w];
static bool new[h][w];

#define for_x for (int16_t x = 0; x < w; x++)
#define for_y for (int16_t y = 0; y < h; y++)
#define for_xy for_x for_y

static void show()
{
	print("\033[H\033[m");
	bool last = !univ[0][0];
	for_y {
		for_x {
			if (last != univ[y][x]) {
				last = univ[y][x];
				print(last ? "\033[47m" : "\033[m");
			}
			print("  ");
		}
      printf("\n");
	}
   printf("\033[0;36mConway's Game of Life\t\t\t\033[mGeneration: \033[93m%d\033[E", generation);
}

static void seed_game()
{
	srand(_TIMER_100HZ + 42);

	for_xy {
		unsigned int n = rand();
		univ[y][x] = n < (RAND_MAX/10) ? 1 : 0;
	}

	generation = 0;
}

static bool evolve()
{
	generation += 1;

	for_y for_x {
		uint16_t n = 0;
		for (int16_t y1 = y - 1; y1 <= y + 1; y1++)
			for (int16_t x1 = x - 1; x1 <= x + 1; x1++)
				if (univ[(int16_t)(y1 + h) % (uint16_t)h][(int16_t)(x1 + w) % (uint16_t)w])
					n++;

		if (univ[y][x]) n--;
		bool alive = (n == 3 || (n == 2 && univ[y][x]));
		new[y][x] = alive;
	}

	bool unchanged = true;
	for_y for_x {
		if (last[y][x] != new[y][x]) {
			unchanged = false;
			goto changed;
		}
	}
	changed:

	for_y for_x last[y][x] = univ[y][x];
	for_y for_x univ[y][x] = new[y][x];

	return unchanged;
}

static void game()
{
	seed_game(univ);

	while (!checkchar()) {
		show(univ);
		if (evolve(univ)) {
			seed_game(univ);
		}
	}
}

int main(int argc, char **argv)
{
	(void)argc;
	(void)argv;

	print("\033[H\033[2J");

	print("\033[?7l");	// autowrap off

	game();

	print("\033c");

	return 0;
}
#include <stdio.h>
#include <stdlib.h>
#include <machine.h>
#include <basicio.h>

// Good Xosera 106x30 defaults. :)
#define w	((106)/2)
#define h	(30-1)

static int game_number;		// game played
static int generation;		// current generation count
static int max_generation;	// maximum generation count this run
static int static_death;	// population was static (unchanging)
static int toggle_death;	// population toggled between two states
static int extinct_death;	// population all died

static bool last[h][w];
static bool univ[h][w];
static bool new[h][w];

#define for_x for (int16_t x = 0; x < w; x++)
#define for_y for (int16_t y = 0; y < h; y++)
#define for_xy for_x for_y

static void show(void)
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
	printf("\033[0;36mGame of Life  \033[mGen:\033[93m%d\033[m  Max:\033[93m%d\033[m  (Games:\033[93m%d\033[m Static:\033[93m%d\033[m Toggle:\033[93m%d\033[m Extinct:\033[93m%d\033[m)\033[K",
		generation, max_generation, game_number, static_death, toggle_death, extinct_death);
}

static void seed_game(void)
{
	// save if previous was record
	if (max_generation < generation) {
		max_generation = generation;
	}
    generation = 0;

	// seed random with uptime
    srand(_TIMER_100HZ + rand());

	// random density n out of 2 to 30
    unsigned int density = rand() / (RAND_MAX / 100);
	if (density == 0) {
		density = 1;
	}
    for_xy {
        unsigned int n = rand();
        univ[y][x]     = n < (RAND_MAX / density);
    }
	for_y for_x last[y][x] = univ[y][x];
}

static void evolve(void)
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
			goto early_out;
		}
	}
	early_out:

	if (unchanged)
	{
		bool extinct = true;
		for_y for_x {
			if (new[y][x]) {
				extinct = false;
			}
		}

		if (extinct)
		{
			extinct_death += 1;
		}
		else
		{
			bool toggle = false;
			for_y for_x {
				if (univ[y][x] != last[y][x]) {
					toggle = true;
					goto early_out2;
				}
			}
			early_out2:
			if (toggle)	{
				toggle_death += 1;
			}
			else {
				static_death += 1;
			}
		}

		game_number += 1;
		seed_game();
	}
	else {
		for_y for_x last[y][x] = univ[y][x];
		for_y for_x univ[y][x] = new[y][x];
	}
}

static void game(void)
{
	seed_game();

	while (true) {
		show();
		evolve();

		if (checkchar()) {
			char c = readchar();
			if (c == 'r' || c == 'R') {
				seed_game();
			}
			else {
				break;
			}
		}
	}
}

int main(int argc, char **argv)
{
	(void)argc;
	(void)argv;

	print("\033[H\033[2J");	// home, clear screen
	print("\033[?7l");		// autowrap off
	print("\033[?25l");		// hide cursor

	game();

	print("\033c");			// reset terminal

	return 0;
}

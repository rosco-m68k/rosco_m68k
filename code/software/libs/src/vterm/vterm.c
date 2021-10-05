/* COPYRIGHT 2018 BRYAN HALEY UNDER THE MIT LICENSE *
 * SEE LICENSE.MD FOR MORE INFORMATION              */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <printf.h>
#include "vterm.h"
#include <machine.h>

#define ASCII_ESC  0x1B
#define ASCII_ZERO 0x30

FILE *inp, *out;

void vt_init (void) //FILE *input, FILE *output) 
{ 
   // = input;
   // out = output;
}

void vt_send (char* seq)
{
    int len = strlen(seq);
    vt_nsend(seq, len);
}

void vt_nsend (char* seq, int len)
{
    int i = 0;

    /* Print the escape sequence to the terminal file stream */
    mcPrintchar(ASCII_ESC);

    for (i = 0; i < len; i++)
    { 
        if (seq[i] == 0) { break; }
        mcPrintchar(seq[i]);
    }
}


void vt_move_cursor_up (char* units)
{   
    /* A note on the usage of char* here as opposed to int:
    * Ultimately since communication with the terminal is done
    * entirely through ASCII data, any integer value must eventually 
    * be converted to one or more ASCII characters before
    * being sent. Therefore, rather than convert integers to 
    * characters within these functions, it is left up to the user
    * to decide when and where to convert them, if necessary at all. */
    char* cursor_command = (char*) calloc(1, 10);

    strncat(cursor_command, "[", 2);
    strncat(cursor_command, units, 8);
    strncat(cursor_command, "A", 2);

    vt_nsend(cursor_command, 10);
    free(cursor_command); cursor_command = NULL;
}

void vt_move_cursor_down (char* units)
{
    char* cursor_command = (char*) calloc(1, 10);

    strncat(cursor_command, "[", 2);
    strncat(cursor_command, units, 8);
    strncat(cursor_command, "B", 2);

    vt_nsend(cursor_command, 10);
    free(cursor_command); cursor_command = NULL;
}

void vt_move_cursor_left (char* units)
{
    char* cursor_command = (char*) calloc(1, 10);

    strncat(cursor_command, "[", 2);
    strncat(cursor_command, units, 8);
    strncat(cursor_command, "C", 2);

    vt_nsend(cursor_command, 10);
    free(cursor_command); cursor_command = NULL;
}

void vt_move_cursor_right (char* units)
{
    char* cursor_command = (char*) calloc(1, 10);

    strncat(cursor_command, "[", 2);
    strncat(cursor_command, units, 8);
    strncat(cursor_command, "D", 2);

    vt_nsend(cursor_command, 10);
    free(cursor_command); cursor_command = NULL;
}

void vt_move_cursor_xy (char* x, char* y)
{
    char *cursor_command = (char*) calloc(1,20);

    strncat(cursor_command, "[", 2);
    strncat(cursor_command, y, 8);
    strncat(cursor_command, ";", 2);
    strncat(cursor_command, x, 8);
    strncat(cursor_command, "f", 2);

    vt_nsend(cursor_command, 20);
    free(cursor_command); cursor_command = NULL;
}

void vt_scroll_up (void)
{
    mcPrintchar(ASCII_ESC);
    mcPrintchar('D');
}

void vt_scroll_down (void)
{
    mcPrintchar(ASCII_ESC);
    mcPrintchar('M');
}

void vt_clear_line (void)
{
    vt_nsend("[2K", 3);
}

void vt_clear_screen (void)
{
    vt_nsend("[2J", 3);
}

void vt_setcolor_4bit_fg (char* fg_code)
{
    char *color_command = (char*) calloc(1,6);
    color_command[0] = '[';
    strncat(color_command, fg_code, 5);
    strncat(color_command, "m", 2);

    vt_nsend(color_command, 6);
    free(color_command); color_command = NULL;
}

/* This is redundant since fg and bg codes don't overlap */
void vt_setcolor_4bit_bg (char* bg_code)
{
    char *color_command = (char*) calloc(1,6);
    color_command[0] = '[';
    strncat(color_command, bg_code, 5);
    strncat(color_command, "m", 2);

    vt_nsend(color_command, 6);
    free(color_command); color_command = NULL;
}

void vt_setcolor_4bit (char* fg_code, char* bg_code)
{
    char *color_command = (char*) calloc(1,10);
    color_command[0] = '[';
    strncat(color_command, fg_code, 5);
    strncat(color_command, ";", 2);
    strncat(color_command, bg_code, 4);
    strncat(color_command, "m", 2);

    vt_nsend(color_command, 10);
    free(color_command); color_command = NULL;
}

void vt_setcolor_8bit_fg (char* fg_code)
{
    char *color_command = (char*) calloc(1,12);
    strncat(color_command, "[38;5;", 7);
    strncat(color_command, fg_code, 4);
    strncat(color_command, "m", 2);

    vt_nsend(color_command, 12);
    free (color_command); color_command = NULL;
}

void vt_setcolor_8bit_bg (char* bg_code)
{
    char *color_command = (char*) calloc(1,12);
    strncat(color_command, "[48;5;", 7);
    strncat(color_command, bg_code, 4);
    strncat(color_command, "m", 2);

    vt_nsend(color_command, 12);
    free(color_command); color_command = NULL;
}

void vt_setcolor_8bit (char* fg_code, char* bg_code)
{ 
    char *color_command = (char*) calloc(1,20);
    strncat(color_command, "[38;5;", 7);
    strncat(color_command, fg_code, 4);
    strncat(color_command, ";48;5;", 7);
    strncat(color_command, bg_code, 4);
    strncat(color_command, "m", 2);

    vt_nsend(color_command, 20);
    free(color_command); color_command = NULL;
}

void vt_setcolor_tru_fg (char* r, char* g, char* b)
{
    char *color_command = (char*) calloc(1,18);
    strncat(color_command, "[38;2;", 7);
    strncat(color_command, r, 4);
    strncat(color_command, ";", 2);
    strncat(color_command, g, 4);
    strncat(color_command, ";", 2);
    strncat(color_command, b, 4);
    strncat(color_command, "m", 2);

    vt_nsend(color_command, 18);
    free(color_command); color_command = NULL;
}

void vt_setcolor_tru_bg (char* r, char* g, char* b)
{
    char *color_command = (char*) calloc(1,18);
    strncat(color_command, "[48;2;", 7);
    strncat(color_command, r, 4);
    strncat(color_command, ";", 2);
    strncat(color_command, g, 4);
    strncat(color_command, ";", 2);
    strncat(color_command, b, 4);
    strncat(color_command, "m", 2);

    vt_nsend(color_command, 18);
    free(color_command); color_command = NULL;
}

void vt_setcolor_tru (char* r_fg, char* r_bg, char* g_fg, char* g_bg, char* b_fg, char* b_bg)
{
    char *color_command = (char*) calloc(1,40);
    strncat(color_command, "[38;2;", 7);
    strncat(color_command, r_fg, 4);
    strncat(color_command, ";", 2);
    strncat(color_command, g_fg, 4);
    strncat(color_command, ";", 2);
    strncat(color_command, b_fg, 4);
    strncat(color_command, ";48;2;", 7);
    strncat(color_command, r_bg, 4);
    strncat(color_command, ";", 2);
    strncat(color_command, g_bg, 4);
    strncat(color_command, ";", 2);
    strncat(color_command, b_bg, 4);
    strncat(color_command, "m", 2);

    vt_nsend(color_command, 40);
    free(color_command); color_command = NULL;
}

void vt_bold_text (void)
{
    vt_nsend("[1m", 3);
}

void vt_underline_text (void)
{
    vt_nsend("[4m", 3);
}

void vt_invert_colors (void)
{
    vt_nsend("[7m", 3);
}

void vt_blink_text (void)
{
    vt_nsend("[5m", 3);
}

void vt_reset_text_attributes (void)
{
    vt_nsend("[0m", 3);
}

vt_vec2* vt_get_cursor_pos (void)
{
    char esc = 0;
    vt_vec2 *cursor_pos = NULL;
    int x_pos = 0, y_pos = 0;
 
    /* send the request to get the screen size */
    vt_nsend("[6n", 3);
    esc = mcReadchar();

    /* read the response out of inp */
    if (esc == ASCII_ESC && mcReadchar() == '[')
    {
        char in = 0;
        int input_buff_len = 10;
        char *x_str = (char*) calloc(1, input_buff_len);
        char *y_str = (char*) calloc(1, input_buff_len);
        int index = 0;

        while (in != ';' && in != 'R' && index < input_buff_len)
        {
            in = mcReadchar();
            /* printf("Read: %c\n", in); */
            if (in == ';') { break; }

            if (in == 'R')
            {
                memcpy(y_str, x_str, input_buff_len);
                memset(x_str, 0, input_buff_len);
                x_str[0] = ASCII_ZERO;
                break;
            }

            y_str[index] = in;
            index++;
        }

        y_pos = atoi(y_str);
        memset(y_str, 0, input_buff_len);
        free(y_str); y_str = NULL;
        index = 0;

        if (x_str[0] != ASCII_ZERO) while (in != 'R' && index < input_buff_len)
        {
            in = mcReadchar();
            /* printf("Read: %c\n", in); */
            if (in == 'R') { break; }
            x_str[index] = in;
            index++;
        }

        x_pos = atoi(x_str);
        memset(x_str, 0, input_buff_len);

        free(x_str); x_str = NULL;
    }

    else { return NULL; }
    
    cursor_pos = (vt_vec2*) calloc(1, sizeof(vt_vec2));
    cursor_pos->x = x_pos;
    cursor_pos->y = y_pos;

    return cursor_pos;
}

vt_vec2* vt_get_screen_size (void)
{
    /* There is no actual ANSI/ISO/VT-100 escape sequence to get the size of the terminal 
     * screen, and this library can't rely on an OS to exist to provide ioctl, so this
     * function just cheats the old fashioned way by telling the cursor to go to position
     * (999,999) then asking where the cursor actually ended up. */

    char *old_x = (char*) calloc(1, 10);
    char *old_y = (char*) calloc(1, 10);
    vt_vec2 *old_pos = vt_get_cursor_pos();
    vt_vec2 *new_pos = NULL;

    vt_move_cursor_xy("999", "999");
    new_pos = vt_get_cursor_pos();
    
    itoa(old_pos->x, old_x, 10);
    itoa(old_pos->y, old_y, 10);

    vt_move_cursor_xy(old_x, old_y);
    free (old_pos); old_pos = NULL;
    free (old_x); old_x = NULL;
    free (old_y); old_y = NULL;

    return new_pos;
}

void vt_backspace (void)
{
    /* Simulate a backspace by setting the cursor back one space, sending a blank space to the
     * output file stream, then sending the cursor back a space again. */

    vt_nsend("[1D", 3);
    mcPrintchar(' ');
    vt_nsend("[1D", 3);
}

void vt_clear_space (void)
{
    /* Cheat by sending a space then sending the cursor back one */
    mcPrintchar(' ');
    vt_nsend("[1D", 3);
}

void vt_fill_screen (char c)
{
    int i = 0;
    vt_vec2 *screen_size = vt_get_screen_size(); 
    int num_spaces = screen_size->x * screen_size->y;

    mcPrintchar('\r');
    mcPrintchar('\n');
    
    for (i = 0; i < num_spaces; i++)
    { mcPrintchar(c); }
}

void vt_bell (void)
{
    mcPrintchar('\a');
}

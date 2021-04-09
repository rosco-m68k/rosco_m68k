/* COPYRIGHT 2018 BRYAN HALEY UNDER THE MIT LICENSE *
 * SEE LICENSE.MD FOR MORE INFORMATION       
 * 
 * Modified Matt Pearce 2020 to support Rosco m68k       */



#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "vterm.h"
#include <printf.h>
#include <machine.h>

#define ASCII_VALID_START 0x20
#define ASCII_VALID_END 0x7E

char* uart_getline(char* buff, int len)
{
    int buff_index = 0;
    char in = 0;
    
    /* Clear the buffer before using it */
    memset(buff, 0, len);

    /* Keep getting input until we get the enter key */
    while (buff_index < len && in != 0x0d)
    {
        in = mcReadchar();

        /* Handle characters than can be displayed */
        if (in >= ASCII_VALID_START && in <= ASCII_VALID_END)
        {
            /* Add them to the input buffer */
            buff[buff_index] = in;
            buff_index++;

            /* Print them to the screen so the user can see what they are typing */
            mcSendchar(in);
        }

        /* Handle Backspace (Win/Lin) or Del (Mac) */
        if (in == 0x7F || in == 0x08)
        {
            vt_backspace();
            
            /* Remove the deleted character from the input buffer */
            if (buff_index > 0) { buff_index--; }
            buff[buff_index] = 0;
        }

        /* Handle escape sequences */
        if (in == 0x1B && mcReadchar() == 0x5B)
        {
            /* Handle arrow keys */
            switch (mcReadchar())
            {
                case 0x41:
                    vt_move_cursor_up("1"); break;
                case 0x42:
                    vt_move_cursor_down("1"); break;
                case 0x43:
                    vt_move_cursor_left("1"); break;
                case 0x44:
                    vt_move_cursor_right("1"); break;
            }
        }
    }

    mcSendchar('\n');

    return buff;
}

int kmain(void) 
{
    
    /* Create an input buffer for commands */
    char* input = (char*) calloc(1,100);
    int len = 100;

    /* initialize vterm control library */
    vt_init();

    /* clear the screen and reset cursor to get rid of old junk data */
    vt_clear_screen();
    vt_move_cursor_xy(0,0);

    printf("You can type with a working backspace, or use the arrow keys to move around.\n");
    printf("Available commands: %s%s",
           "clear, color4, color8, trucolor, invert, ",
           "bold, underline, normal, bell, blink, fill, cursor-pos, screen-size, help\n");
    
    while(1)
    {
        printf("$ ");
        uart_getline(input, len);

        if (strcmp(input, "clear") == 0)
        {
            vt_clear_screen();
            vt_move_cursor_xy(0,0);
        }

        else if (strcmp(input, "help") == 0)
        {
            printf("Available commands: %s%s",
                "clear, color4, color8, trucolor, invert, ",
                "bold, underline, normal, bell, blink, fill, cursor-pos, screen-size, help\n");
        }

        else if (strcmp(input, "color4") == 0)
        {
            printf("Enter a foreground color code: ");
            char* fg_code = (char*) calloc(1,5);
            uart_getline(fg_code, 5);
            printf("Enter a background color code: ");
            char* bg_code = (char*) calloc(1,5);
            uart_getline(bg_code, 5);

            vt_setcolor_4bit(fg_code, bg_code);
            printf("Color test\n");
        }

        else if (strcmp(input, "color8") == 0)
        {
            printf("Enter a foreground color code (0-255): ");
            char* fg_code = (char*) calloc(1,5);
            uart_getline(fg_code, 5);
            printf("Enter a background color code (0-255): ");
            char* bg_code = (char*) calloc(1,5);
            uart_getline(bg_code, 5);

            vt_setcolor_8bit(fg_code, bg_code);
            printf("Color test\n");
        }

        else if (strcmp(input, "trucolor") == 0)
        {
            printf("Setting foreground colors\n");
            printf("Enter a red color value (0-255): ");
            char* r_fg = (char*) calloc(1,4);
            uart_getline(r_fg, 4);
            printf("Enter a blue color value (0-255): ");
            char* g_fg = (char*) calloc(1,4);
            uart_getline(g_fg, 4);
            printf("Enter a green color value (0-255): ");
            char* b_fg = (char*) calloc(1,4);
            uart_getline(b_fg, 4);

            printf("\nSetting background colors\n");
            printf("Enter a red color value (0-255): ");
            char* r_bg = (char*) calloc(1,4);
            uart_getline(r_bg, 4);
            printf("Enter a blue color value (0-255): ");
            char* g_bg = (char*) calloc(1,4);
            uart_getline(g_bg, 4);
            printf("Enter a green color value (0-255): ");
            char* b_bg = (char*) calloc(1,4);
            uart_getline(b_bg, 4);
            
            vt_setcolor_tru(r_fg, r_bg, g_fg, g_bg, b_fg, b_bg);
            printf("Color test\n");
        }

        else if (strcmp(input, "invert") == 0)
        {
            vt_invert_colors();
        }

        else if (strcmp(input, "bold") == 0)
        {
            vt_bold_text();
        }

        else if (strcmp(input, "underline") == 0)
        {
            vt_underline_text();
        }

        else if (strcmp(input, "normal") == 0)
        {
            vt_reset_text_attributes();
        }

        else if (strcmp(input, "bell") == 0)
        {
            vt_bell();
        }
        
        else if (strcmp(input, "blink") == 0)
        {
            vt_blink_text();
        }

        else if (strcmp(input, "trucolor-test") == 0)
        {
            printf("\x1b[38;2;40;177;249mTRUECOLOR\x1b[0m\n");
        }
        
        else if (strcmp(input, "cursor-pos") == 0)
        {
            vt_vec2 *cursor_pos = vt_get_cursor_pos();
            printf("Cursor position: (%d,%d)\n", cursor_pos->x, cursor_pos->y);
            free(cursor_pos); cursor_pos = NULL;
        }
        
        else if (strcmp(input, "screen-size") == 0)
        {
            vt_vec2 *screen_size = vt_get_screen_size();
            printf("Screen size: %dx%d\n", screen_size->x, screen_size->y);
            free(screen_size); screen_size = NULL;
        }

        else if (strcmp(input, "fill") == 0)
        {
            printf("Enter a character to fill the screen with: ");
            char in = mcReadchar();

            vt_fill_screen(in);
        
        }
        
        else if (strcmp(input, "scroll-up") == 0)
        {
            vt_scroll_up();
        }

        else if (strcmp(input, "scroll-down") == 0)
        {
            vt_scroll_down();
        }

        else
        {
            printf("Unknown command: \"%s\"\n", input);
        }
    }

    return 0;
}

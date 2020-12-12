/* COPYRIGHT 2018 BRYAN HALEY UNDER THE MIT LICENSE *
 * SEE LICENSE.MD FOR MORE INFORMATION              */

#ifndef VTERM_H
#define VTERM_H

/*
 *  Based on the list of control sequences accepted by the 'screen' utility published here:
 *  https://www.gnu.org/software/screen/manual/screen.html#Virtual-Terminal
 */

typedef struct
{
    int x, y;
} vt_vec2;

void vt_init (); /* can be called any time */

/* The following two functions can be used to send any commands not wrapped in functions by 
 * this library. */
void vt_send (char *seq);
void vt_nsend (char *seq, int len);

/* VT100 Sequences */
void vt_move_cursor_up (char* units);
void vt_move_cursor_down (char* units);
void vt_move_cursor_left (char* units);
void vt_move_cursor_right (char* units);
void vt_move_cursor_xy (char* x, char* y);

vt_vec2* vt_get_cursor_pos (void);

void vt_scroll_up (void);
void vt_scroll_down (void);

void vt_clear_line (void);
void vt_clear_screen (void);

/* See https://en.wikipedia.org/wiki/ANSI_escape_code#Colors */
void vt_setcolor_4bit_fg (char* fg_code);
void vt_setcolor_4bit_bg (char* bg_code);
void vt_setcolor_4bit (char* fg_code, char* bg_code);

void vt_setcolor_8bit_fg (char* fg_code);
void vt_setcolor_8bit_bg (char* bg_code);
void vt_setcolor_8bit (char* fg_code, char* bg_code);

/* Note: 24-bit RGB color usually isn't supported */
void vt_setcolor_tru_fg (char* r, char* b, char* g);
void vt_setcolor_tru_bg (char* r, char* b, char* g);
void vt_setcolor_tru (char* r_fg, char* r_bg, char* g_fg, char* g_bg, char* b_fg, char* b_bg);

void vt_bold_text (void);
void vt_underline_text (void);
void vt_blink_text (void);

void vt_invert_colors (void);

void vt_reset_text_attributes (void);

/* Special */
vt_vec2* vt_get_screen_size (void);

void vt_backspace (void);
void vt_clear_space (void);
void vt_fill_screen (char c);
void vt_bell (void);

#endif

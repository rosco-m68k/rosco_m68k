/*
 * vim: set et ts=4 sw=4
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|
 *  __ __
 * |  |  |___ ___ ___ ___ ___
 * |-   -| . |_ -| -_|  _| .'|
 * |__|__|___|___|___|_| |__,|
 *
 * ------------------------------------------------------------
 * Copyright (c) 2021 Xark & contributors
 * MIT License
 *
 * rosco_m68k + Xosera VT100/ANSI terminal driver
 * Based on info from:
 *  https://vt100.net/docs/vt100-ug/chapter3.html#S3.3.6.1
 *  https://misc.flogisoft.com/bash/tip_colors_and_formatting
 *  https://en.wikipedia.org/wiki/ANSI_escape_code
 *  https://www.gnu.org/software/screen/manual/html_node/Control-Sequences.html
 *  (and various other sources)
 * ------------------------------------------------------------
 */

#if defined(TEST_FIRMWARE)
#define DEBUG 0        // set to 1 for test debugging (LOG/LOGF)

#include <assert.h>
#include <basicio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>

#else

#define DEBUG 0        // must be zero (no printf in firmware)
// thse are missing from kernel machine.h
extern unsigned int _FIRMWARE_REV;        // rosco ROM firmware revision
extern void         (*_EFP_INPUTCHAR)();
extern void         (*_EFP_CHECKINPUT)();

#endif

#include <machine.h>
#include <stdbool.h>
#include <stdint.h>

#include "xosera_ansiterm_m68k.h"

#if !defined(ROSCO_M68K)
#define ROSCO_M68K
#endif
#include "xosera_m68k_api.h"

#if DEBUG
extern void dprintf(const char * fmt, ...) __attribute__((format(__printf__, 1, 2)));
#define DPRINTF(fmt, ...) dprintf(fmt, ##__VA_ARGS__)
#else
#define DPRINTF(fmt, ...) (void)0
#endif

#if DEBUG
#define LOG(msg)       dprintf(msg)
#define LOGF(fmt, ...) DPRINTF(fmt, ##__VA_ARGS__)
#define LOGC(ch)       dprintch(ch)
#else
#define LOG(msg)       (void)0
#define LOGF(fmt, ...) (void)0
#define LOGC(ch)       (void)0
#endif

#define DEFAULT_XOSERA_CONFIG 1           // default Xosera config (#1 848x480)
#define DEFAULT_COLOR         0x02        // rosco_m68k "retro" dark green on black
#define MAX_CSI_PARMS         16          // max CSI parameters per sequence
#define MAX_QUERY_LEN         16          // max query response length (including NUL terminator)

// terminal attribute and option flags
enum e_term_flags
{
    TFLAG_NEWLINE         = 1 << 0,        // LF also does a CR
    TFLAG_NO_AUTOWRAP     = 1 << 1,        // don't wrap to next line at EOL
    TFLAG_HIDE_CURSOR     = 1 << 2,        // don't show a cursor on input
    TFLAG_NOBLINK_CURSOR  = 1 << 3,        // do not blink cursor
    TFLAG_ATTRIB_BRIGHT   = 1 << 4,        // make colors bright
    TFLAG_ATTRIB_DIM      = 1 << 5,        // make colors dim
    TFLAG_ATTRIB_REVERSE  = 1 << 6,        // reverse fore/back colors
    TFLAG_ATTRIB_PASSTHRU = 1 << 7,        // print control chars as graphic [using HIDDEN attribute]
};

// current processing state of terminal
enum e_term_state
{
    TSTATE_NORMAL,
    TSTATE_ILLEGAL,
    TSTATE_ESC,
    TSTATE_CSI,
};

// all storage for terminal (must be at 16-bit memory address [< 32KB])
typedef struct xansiterm_data
{
    uint16_t cur_addr;                // +0x0: next VRAM address to draw text
    int8_t   send_index;              // +0x2: index into send_buffer or -1 if no query
    bool     cursor_drawn;            // +0x3: flag if cursor_save/cursor_word data valid
    void *   device_inputchar;        // +0x4: trap handler for console INPUTCHAR (wrapped, for asm)
    void *   device_checkinput;       // +0x8: trap handler for console CHECKINPUT (wrapped, for asm)
    uint16_t vram_base;               // base VRAM address for text screen
    uint16_t vram_size;               // size of text screen in current mode (init clears to allow 8x8 font)
    uint16_t vram_end;                // ending address for text screen in current mode
    uint16_t vram_memend;             // highest ending address used (for clear)
    uint16_t line_len;                // user specified line len (normally 0)
    uint16_t lines_high;              // user specified screen lines_high (normally 0)
    uint16_t cursor_glyph;            // custom cursor color and/or glyph (ignored if zero)
    uint16_t cursor_mask;             // custom cursor mask (1 bits = use cursor_glyph bits)
    uint16_t cursor_save;             // word saved from under input cursor
    uint16_t cursor_word;             // input cursor word (used to detect overwrite and prevent "fossil" cursor)
    uint16_t cols, rows;              // text columns and rows in current mode (zero based)
    uint16_t x, y;                    // current x and y cursor position (zero based)
    uint16_t save_x, save_y;          // storage to save/restore cursor postion
    uint16_t h_size;                  // horizontal video resolution (set in xansi_reset)
    uint16_t v_size;                  // vertical video resolution (set in xansi_reset)
    uint16_t gfx_ctrl;                // default graphics mode
    uint16_t tile_ctrl[4];            // up to four fonts <ESC>( <ESC>) <ESC>* <ESC>+
    uint16_t csi_parms[MAX_CSI_PARMS];          // CSI parameter storage
    uint8_t  num_parms;                         // number of parsed CSI parameters
    uint8_t  intermediate_char;                 // CSI intermediate character (only one supported)
    uint8_t  cur_font;                          // default font number from tile_ctrl
    uint8_t  def_color;                         // default terminal colors
    uint8_t  cur_color;                         // logical colors before attribute modifications (high/low nibble)
    uint8_t  state;                             // current ANSI parsing state (e_term_state)
    uint8_t  flags;                             // various terminal flags (e_term_flags)
    uint8_t  color;                             // effective current background and forground color (high/low nibble)
    char     ver_code[3];                       // Xosera initdata (from COPPER memory after reconfig)
    char     send_buffer[MAX_QUERY_LEN];        // xmit data for query replies
    bool     lcf;                               // flag for delayed last column wrap flag (PITA)
    bool     save_lcf;                          // storeage to save/restore lcf with cursor position
} xansiterm_data;

// high speed small inline functions
#pragma GCC push_options
#pragma GCC optimize("-O3")

// get xansiterm data (data needs to be in first 32KB of memory)

#if defined(TEST_FIRMWARE)                                           // building for RAM testing
_Static_assert(sizeof(xansiterm_data) <= 128, "data too big");        // fit in reserved space at 0x0500
// NOTE: address must be < 32KB, attribute is a bit of a hack (causes warning about section attributes)
xansiterm_data                                                _private_xansiterm_data;
static inline __attribute__((always_inline)) xansiterm_data * get_xansi_data()
{
    xansiterm_data * ptr;
    __asm__ __volatile__("   lea.l   _private_xansiterm_data,%[ptr]" : [ptr] "=a"(ptr));
    return ptr;
}
#else        // building for firmware
static inline __attribute__((always_inline)) xansiterm_data * get_xansi_data()
{
    xansiterm_data * ptr;
    __asm__ __volatile__("   lea.l   XANSI_CON_DATA.w,%[ptr]\n" : [ptr] "=a"(ptr));
    return ptr;
}


#endif

#if DEBUG
// log readable "character"
__attribute__((noinline)) static void dprintch(char ch)
{
    char * s = 0;
    switch ((uint8_t)ch)
    {
        case '\0':
            s = "'\\0' (^@ NUL)";
            break;
        case '\a':
            s = "'\\a' (^G BEL)";
            break;
        case '\b':
            s = "'\\b' (^H BS)";
            break;
        case '\t':
            s = "'\\t' (^I TAB)";
            break;
        case '\n':
            s = "'\\n' (^J LF)";
            break;
        case '\v':
            s = "'\\v' (^K VT)";
            break;
        case '\f':
            s = "'\\f' (^L FF)";
            break;
        case '\r':
            s = "'\\r' (^M CR)";
            break;
        case '\x1b':
            s = "'\\x1b' (^[ ESC)";
            break;
        case '\x18':
            s = "'\\x18' (^X CAN)";
            break;
        case '\x1a':
            s = "'\\x1a' (^Z SUB)";
            break;
        case '\x7f':
            s = "'\\x7f' (^? DEL)";
            break;
        case 0x9b:
            s = "'\\x9b' (8-bit CSI)";
            break;
        default:
            if ((uint8_t)ch < ' ')
            {
                LOGF("'\\x%x' (^%c)", (uint8_t)ch, 0x40 + (uint8_t)ch);
            }
            else if ((uint8_t)ch < 0x7f)
            {
                LOGF("'%c' (0x%02X)", ch, (uint8_t)ch);
            }
            else
            {
                LOGF("'\\x%02X'", (uint8_t)ch);
            }
            break;
    }
    if (s)
    {
        LOGF("%s", s);
    }
}

// assert x, y matches td->cur_addr VRAM address
static void xansi_assert_xy_valid(xansiterm_data * td)
{
    uint16_t calc_x;
    uint32_t divres = td->cur_addr - td->vram_base;
    // GCC is annoying me and not using perfect opcode that gives division and remainder result
    __asm__ __volatile__(
        "divu.w %[w],%[divres]\n"
        "move.l %[divres],%[calc_x]\n"
        "swap.w %[calc_x]\n"
        : [divres] "+d"(divres), [calc_x] "=d"(calc_x)
        : [w] "d"((uint16_t)td->cols));

    uint16_t calc_y = divres;

    // check for match
    if (td->x != calc_x || td->y != calc_y)
    {
        // if y is off by 1 and LCF set, this is fine (last column flag for delayed wrap)
        if (!td->lcf || (calc_y - td->y) != 1)
        {
            LOGF("ASSERT: cur_addr:0x%04x vs x, y: %u,%u (calculated %u,%u)\n",
                 td->cur_addr,
                 td->x,
                 td->y,
                 calc_x,
                 calc_y);

            // hang
            while (true)
                ;
        }
    }
}
#endif

// calculate VRAM address from x, y
static inline uint16_t xansi_calc_addr(xansiterm_data * td, uint16_t x, uint16_t y)
{
    return td->vram_base + (uint16_t)(y * td->cols) + x;
}

// calculate td->cur_addr from td->x, td->y
static inline void xansi_calc_cur_addr(xansiterm_data * td)
{
    td->cur_addr = xansi_calc_addr(td, td->x, td->y);
}

static void        xansi_scroll_up();
static inline void xansi_check_lcf(xansiterm_data * td)
{
    if (td->lcf)
    {
        td->lcf = false;
        if ((uint16_t)(td->cur_addr - td->vram_base) >= td->vram_size)
        {
            td->cur_addr = td->vram_base + (td->vram_size - td->cols);
            xansi_scroll_up();
        }
    }
}

// draw character into VRAM at td->cur_addr
static inline void xansi_drawchar(xansiterm_data * td, char cdata)
{
    xv_prep();

    xansi_check_lcf(td);
    xm_setw(WR_ADDR, td->cur_addr++);
    xm_setbh(DATA, td->color);
    xm_setbl(DATA, cdata);

    td->x += 1;
    if (td->x >= td->cols)
    {
        if (td->flags & TFLAG_NO_AUTOWRAP)
        {
            td->cur_addr--;
            td->x = td->cols - 1;
        }
        else
        {
            td->x = 0;
            td->y += 1;
            if (td->y >= td->rows)
            {
                td->y = td->rows - 1;
            }
            td->lcf = true;
        }
    }
}

// functions where speed is nice (but inline is too much)
static __attribute__((noinline)) void xansi_clear(uint16_t start, uint16_t end)
{
    xansiterm_data * td = get_xansi_data();

    if (start > end)
    {
        uint16_t t = start;
        start      = end;
        end        = t;
    }
    uint16_t count = end - start - 1;

    xv_prep();
    xm_setbl(SYS_CTRL, 0x0F);

    xwait_blit_ready();
    xreg_setw(BLIT_CTRL, 0x0001);                  // no transp, constS
    xreg_setw_next(0x0000);                        // ANDC constant
    xreg_setw_next(0x0000);                        // XOR constant
    xreg_setw_next(0x0000);                        // MOD_S no modulo S
    xreg_setw_next((td->color << 8) | ' ');        // SRC_S S = const data
    xreg_setw_next(0x0000);                        // MOD_D no modulo D
    xreg_setw_next(start);                         // DST_D VRAM display dest address
    xreg_setw_next(0xFF00);                        // SHIFT no edge masking or shifting
    xreg_setw_next(0x0000);                        // LINES lines (0 for 1-D blit)
    xreg_setw_next(count);                         // WORDS words to write -1

    if (!xm_getb_sys_ctrl(BLIT_BUSY))
    {
        xm_setw(WR_INCR, 1);
        xm_setw(WR_ADDR, start);
        xm_setbh(DATA, td->color);
        do
        {
            xm_setbl(DATA, ' ');
        } while (count--);
    }
    else
    {
        xwait_blit_done();
    }
}

// scroll unrolled for 32-bytes per loop, so no inline please
static __attribute__((noinline)) void xansi_do_scroll()
{
    xansiterm_data * td = get_xansi_data();
    xv_prep();

    // scroll 8 longs per loop (16 words)
    {
        uint16_t i;
        for (i = td->vram_size - td->cols; i >= 16; i -= 16)
        {
            xm_setl(DATA, xm_getl(DATA));
            xm_setl(DATA, xm_getl(DATA));
            xm_setl(DATA, xm_getl(DATA));
            xm_setl(DATA, xm_getl(DATA));
            xm_setl(DATA, xm_getl(DATA));
            xm_setl(DATA, xm_getl(DATA));
            xm_setl(DATA, xm_getl(DATA));
            xm_setl(DATA, xm_getl(DATA));
        }
        // scroll any remaining longs
        for (; i >= 2; i -= 2)
        {
            xm_setl(DATA, xm_getl(DATA));
        }
        // scroll any remaining word
        if (i)
        {
            xm_setw(DATA, xm_getw(DATA));
        }
    }

    // clear new line
    xm_setbh(DATA, td->color);
    for (uint16_t i = 0; i < td->cols; i++)
    {
        xm_setbl(DATA, ' ');
    }
}

// draw input cursor (trying to make it visible)
static inline void xansi_draw_cursor(xansiterm_data * td)
{
    if (!td->cursor_drawn)
    {
        xv_prep();

        bool gfx_change =
            (((uint16_t)(td->gfx_ctrl ^ xreg_getw(PA_GFX_CTRL)) & 0x007f) != 0) ||        // gfx_ctrl mode bits changed
            (td->vram_base != xreg_getw(PA_DISP_ADDR)) ||                                 // display address changed
            (td->h_size != xosera_vid_width()) ||                                         // screen video mode H changed
            (td->v_size != xosera_vid_height()) ||                                        // screen video mode V changed
            (xreg_getw(PA_LINE_LEN) != (td->line_len ? td->line_len : td->cols));         // line length changed

        if (gfx_change)
            return;

        td->cursor_drawn = true;
        xm_setw(RD_ADDR, td->cur_addr);
        uint16_t data   = xm_getw(DATA);
        td->cursor_save = data;

        // calculate cursor color:
        // start with current forground and background color swapped
        uint16_t cursor_color = ((uint16_t)(td->color & 0x0f) << 12) | ((uint16_t)(td->color & 0xf0) << 4);

        // check for same cursor foreground and data foreground
        if ((uint16_t)((cursor_color ^ data) & 0x0f00) == 0)
        {
            cursor_color ^= 0x0800;        // if match, toggle bright/dim of foreground
        }
        // check for same cursor background and data background
        if ((uint16_t)((cursor_color ^ data) & 0xf000) == 0)
        {
            cursor_color ^= 0x8000;        // if match, toggle bright/dim of background
        }

        if (td->cursor_mask)        // use custom cursor_glyph if any bits selected
        {
            cursor_color = ((uint16_t)(td->cursor_glyph & td->cursor_mask) |
                            (uint16_t)(cursor_color & (uint16_t)~td->cursor_mask)) &
                           0xfff00;
            data = (uint16_t)(td->cursor_glyph & td->cursor_mask) | (uint16_t)(data & (uint16_t)~td->cursor_mask);
        }

        uint16_t newcursor = (uint16_t)(cursor_color | (uint16_t)(data & 0x00ff));

        xm_setw(WR_ADDR, td->cur_addr);
        xm_setw(DATA, newcursor);           // draw char with cursor colors
        td->cursor_word = newcursor;        // save cursor word (to check for overwrite)
    }
}

// erase input cursor (if drawn)
static inline void xansi_erase_cursor(xansiterm_data * td)
{
    if (td->cursor_drawn)
    {
        xv_prep();

        td->cursor_drawn = false;
        xm_setw(RD_ADDR, td->cur_addr);
        uint16_t cursor_read = xm_getw(DATA);
        if (cursor_read == td->cursor_word)        // don't erase cursor if it was overwritten
        {
            xm_setw(WR_ADDR, td->cur_addr);
            xm_setw(DATA, td->cursor_save);
        }
    }
}

// set first 16 colors to default VGA colors
static void set_default_colors(volatile xmreg_t * const xosera_ptr)
{
    static const uint16_t def_colors16[16] = {0x0000,         // black
                                              0x000a,         // blue
                                              0x00a0,         // green
                                              0x00aa,         // cyan
                                              0x0a00,         // red
                                              0x0a0a,         // magenta
                                              0x0a50,         // brown
                                              0x0aaa,         // white
                                              0x0555,         // gray
                                              0x055f,         // light blue
                                              0x05f5,         // light green
                                              0x05ff,         // light cyan
                                              0x0f55,         // light red
                                              0x0f5f,         // light magenta
                                              0x0ff5,         // yellow
                                              0x0fff};        // bright white
    xmem_setw_next_addr(XR_COLOR_ADDR);
    for (uint16_t i = 0; i < 16; i++)
    {
        xmem_setw_next(def_colors16[i]);
    };
}

// reset video mode and terminal state
static void xansi_reset(bool reset_colormap)
{
    xansiterm_data * td = get_xansi_data();
    xv_prep();

    // set xosera playfield A registers
    uint16_t gfx_ctrl_val  = td->gfx_ctrl;
    bool     bitmap        = gfx_ctrl_val & 0x40;
    uint16_t bpp           = ((gfx_ctrl_val >> 4) & 0x3);
    uint16_t h_rpt         = ((gfx_ctrl_val >> 2) & 0x3) + 1;
    uint16_t v_rpt         = (gfx_ctrl_val & 0x3) + 1;
    uint16_t tile_ctrl_val = td->tile_ctrl[td->cur_font];
    uint16_t tile_w        = ((!bitmap || bpp < 2) ? 8 : (bpp == 2) ? 4 : 1) * h_rpt;
    uint16_t tile_h        = ((bitmap) ? 1 : ((tile_ctrl_val & 0xf) + 1)) * v_rpt;
    uint16_t h_size        = xosera_vid_width();
    uint16_t v_size        = xosera_vid_height();
    uint16_t hv_frac       = xreg_getw(PA_HV_FSCALE);
    uint16_t h_frac        = (hv_frac & 0x0700) >> 8;
    uint16_t v_frac        = hv_frac & 0x7;
    uint16_t rows          = td->lines_high;
    uint16_t cols          = td->line_len;
    uint16_t rows_ru       = td->lines_high;
    uint16_t cols_ru       = td->line_len;

    if (h_frac)
    {
        h_size -= h_size / (h_frac + 1);
    }

    if (v_frac)
    {
        v_size -= v_size / (v_frac + 1);
    }

    if (rows == 0)
    {
        rows    = v_size / tile_h;                       // calc full text rows
        rows_ru = (v_size + tile_h - 1) / tile_h;        // calc full text rows rounded up
    }

    if (cols == 0)
    {
        cols    = h_size / tile_w;                       // calc full text columns
        cols_ru = (h_size + tile_w - 1) / tile_w;        // calc full text columns rounded up
    }

    td->h_size    = h_size;
    td->v_size    = v_size;
    td->vram_size = cols * rows;
    td->vram_end  = td->vram_base + td->vram_size;
    td->cols      = cols;
    td->rows      = rows;
    td->cur_color = td->def_color;
    td->color     = td->def_color;

    if (td->x >= cols)
    {
        td->x = cols - 1;
    }
    if (td->y >= rows)
    {
        td->y = rows - 1;
    }

    LOGF("{Xosera gfx_ctrl=%04X tile_ctrl=%04X vram_addr=%04X vram_end=%04X line_len=%04X lines_high=%04X}",
         gfx_ctrl_val,
         tile_ctrl_val,
         td->vram_base,
         td->vram_end,
         cols,
         rows);

    xwait_not_vblank();
    xwait_vblank();

    xreg_setw(PA_GFX_CTRL, gfx_ctrl_val);
    xreg_setw(PA_TILE_CTRL, tile_ctrl_val);
    xreg_setw(PA_DISP_ADDR, td->vram_base);
    xreg_setw(PA_LINE_LEN, cols);
    xreg_setw(PA_H_SCROLL, 0x0000);
    xreg_setw(PA_V_SCROLL, 0x0000);
    xm_setbl(SYS_CTRL, 0x0F);

    if (reset_colormap)
    {
        set_default_colors(xosera_ptr);
    }

    // only clear any additional VRAM used from previous mode
    uint16_t clear_end = td->vram_base + (cols_ru * rows_ru);
    if (td->vram_memend < clear_end)
    {
        xansi_clear(td->vram_memend, clear_end);
        td->vram_memend = clear_end;
    }

    xansi_calc_cur_addr(td);
}

// invert screen, invert again to restore unless invert flag set
static void xansi_visualbell(bool invert)
{
    xansiterm_data * td = get_xansi_data();
    xv_prep();

    xm_setw(RD_INCR, 1);
    xm_setw(WR_INCR, 1);
    for (int l = 0; l < (invert ? 1 : 2); l++)
    {
        xm_setw(RD_ADDR, td->vram_base);
        xm_setw(WR_ADDR, td->vram_base);
        for (uint16_t i = 0; i < td->vram_end; i++)
        {
            uint16_t data = xm_getw(DATA);
            xm_setw(DATA,
                    (((uint16_t)(data & 0xf000) >> 4) | (uint16_t)((data & 0x0f00) << 4) | (uint16_t)(data & 0xff)));
        }
    }
}

// clear screen
static void xansi_cls()
{
    xansiterm_data * td = get_xansi_data();

    // if not using 8x8 font, clear double high (clear if mode switched later)
    xansi_clear(td->vram_base, td->vram_end);
    td->cur_addr = td->vram_base;
    td->x        = 0;
    td->y        = 0;
    td->lcf      = false;
}

// setup Xosera registers for scrolling up and call scroll function
static void xansi_scroll_up()
{
    xansiterm_data * td = get_xansi_data();

    xv_prep();

    uint16_t saddr = td->vram_base + td->cols;
    uint16_t daddr = td->vram_base;
    uint16_t count = td->vram_size - td->cols;

    xwait_blit_ready();
    xreg_setw(BLIT_CTRL, 0x0000);        // no transp
    xreg_setw_next(0x0000);              // ANDC constant
    xreg_setw_next(0x0000);              // XOR constant
    xreg_setw_next(0x0000);              // MOD_S no modulo S
    xreg_setw_next(saddr);               // SRC_S S = source
    xreg_setw_next(0x0000);              // MOD_D no modulo D
    xreg_setw_next(daddr);               // DST_D VRAM display dest address
    xreg_setw_next(0xFF00);              // SHIFT no edge masking or shifting
    xreg_setw_next(0x0000);              // LINES lines (0 for 1-D blit)
    xreg_setw_next(count - 1);           // WORDS words to write -1

    if (!xm_getb_sys_ctrl(BLIT_BUSY))
    {
        xm_setw(WR_INCR, 1);
        xm_setw(RD_INCR, 1);
        xm_setw(WR_ADDR, td->vram_base);
        xm_setw(RD_ADDR, td->vram_base + td->cols);
        xansi_do_scroll();
    }
    else
    {

        // clear bottom line
        daddr = td->vram_base + td->vram_size - td->cols;
        count = td->cols;

        xwait_blit_ready();
        xreg_setw(BLIT_CTRL, 0x0001);                         // no transp, constS
        xreg_setw(BLIT_SRC_S, (td->color << 8) | ' ');        // S = const data
        xreg_setw(BLIT_DST_D, daddr);                         // VRAM display dest address
        xreg_setw(BLIT_WORDS, count - 1);                     // words to write -1
        xwait_blit_done();
    }
}

// setup Xosera registers for scrolling down and call scroll function
static void xansi_scroll_down(xansiterm_data * td)
{
    xv_prep();

    uint16_t daddr = td->vram_end - td->cols - 1;
    uint16_t saddr = daddr - td->cols;
    uint16_t count = td->vram_size - td->cols;

    xwait_blit_ready();
    xreg_setw(BLIT_CTRL, 0x0000);           // no transp
    xreg_setw_next(0x0000);                 // ANDC constant
    xreg_setw_next(0x0000);                 // XOR constant
    xreg_setw_next(-(td->cols * 2));        // MOD_S S modulo
    xreg_setw_next(saddr);                  // SRC_S S source
    xreg_setw_next(-(td->cols * 2));        // MOD_D modulo D
    xreg_setw_next(daddr);                  // DST_D VRAM display dest address
    xreg_setw_next(0xFF00);                 // SHIFT no edge masking or shifting
    xreg_setw_next(td->rows - 1);           // LINES lines
    xreg_setw_next(td->cols - 1);           // WORDS words per line -1

    if (!xm_getb_sys_ctrl(BLIT_BUSY))
    {
        xm_setw(WR_INCR, -1);
        xm_setw(RD_INCR, -1);
        xm_setw(WR_ADDR, (uint16_t)(td->vram_end - 1));
        xm_setw(RD_ADDR, (uint16_t)(td->vram_end - 1 - td->cols));
        xansi_do_scroll();
    }
    else
    {
        // clear top line
        daddr = td->vram_base;
        count = td->cols;

        xwait_blit_ready();
        xreg_setw(BLIT_CTRL, 0x0001);                         // no transp, constS
        xreg_setw(BLIT_SRC_S, (td->color << 8) | ' ');        // S = const data
        xreg_setw(BLIT_DST_D, daddr);                         // VRAM display dest address
        xreg_setw(BLIT_WORDS, count - 1);                     // words to write -1
        xwait_blit_done();
    }
}

// process control character
static void xansi_processctrl(xansiterm_data * td, char cdata)
{
    // if auto line length, detect changes
    if (td->line_len == 0)
    {
        xv_prep();

        if (td->h_size != xosera_vid_width() || td->v_size != xosera_vid_height() || td->cols != xreg_getw(PA_LINE_LEN))
        {
            xansi_reset(false);
        }
    }

    // NOTE: return if cursor Y position unchanged, break otherwise
    switch (cdata)
    {
        case '\a':
            // VT:  \a      BEL ^G alert (visual bell)
            LOG("[BELL]");
            xansi_visualbell(false);
            return;
        case '\b':
            // VT:  \b      BS  ^H backspace (stops at left margin)
            LOG("[BS]");
            // NOTE: lcf should never be set when x != 0
            if (td->x > 0)
            {
                td->x -= 1;
                td->cur_addr--;
            }
            return;
        case '\t':
            // VT:    \t    HT  ^I  8 char tab EXTENSION: wraps to next line when < 8 chars
            LOG("[TAB]");
            uint16_t nx = (uint16_t)(td->x & ~0x7) + 8;
            if ((uint16_t)(td->cols - nx) >= 8)
            {
                td->cur_addr += (nx - td->x);
                td->x = nx;
            }
            else
            {
                td->cur_addr -= td->x;
                td->cur_addr += td->cols;
                td->x = 0;
                td->y += 1;
            }
            break;
        case '\n':
            // VT:  \n  LF  ^J  line feed (or LF+CR in NEWLINE mode)
            LOG("[LF]");
            td->cur_addr += td->cols;
            td->y += 1;
            if (td->flags & TFLAG_NEWLINE)
            {
                td->cur_addr -= td->x;
                td->x = 0;
            }
            break;
        case '\v':
            // VT:  \v  VT  ^K  vertical tab EXTENSION: reverse LF (VT100 is another LF)
            LOG("[VT]");
            td->cur_addr -= td->cols;
            td->y -= 1;
            if (td->y >= td->rows)
            {
                td->cur_addr += td->cols;
                td->y += 1;
                xansi_scroll_down(td);
            }
            break;
        case '\f':
            // VT:  \f  FF  ^L  form feed EXTENSION clear screen and home cursor (VT100 yet another LF)
            LOG("[FF]");
            xansi_cls();
            return;
        case '\r':
            // VT:  \r  CR  ^M  carriage return (move to left margin)
            LOG("[CR]");
            td->cur_addr -= td->x;
            td->x = 0;
            break;
        default:           // suppress others
            return;        // fast out (no cursor change)
    }

    td->lcf = false;
    if (td->y >= td->rows)
    {
        td->cur_addr -= td->cols;
        td->y -= 1;
        xansi_scroll_up();
    }
}

// process normal character (not CSI or ESC sequence)
static void xansi_processchar(xansiterm_data * td, char cdata)
{
    if ((uint8_t)cdata >= ' ' || (td->flags & TFLAG_ATTRIB_PASSTHRU))
    {
        xansi_drawchar(td, cdata);
        return;
    }

    xansi_processctrl(td, cdata);
}
#pragma GCC pop_options        // end -O3

// parsing functions can be small
#pragma GCC push_options
#pragma GCC optimize("-Os")

// note 0-999 only
static void str_dec(char ** strptr, unsigned int num)
{
    char *       p = *strptr;
    unsigned int n = num;
    if (num >= 100)
    {
        uint16_t r = n / 100;
        n -= r * (uint16_t)100;
        *p++ = '0' + r;
    }
    if (num >= 10)
    {
        uint16_t r = n / 10;
        n -= r * (uint16_t)10;
        *p++ = '0' + r;
    }
    *p++    = '0' + n;
    *strptr = p;
}

// note 0-ffffffff (outputs 1 to 8 digits)
static void str_hex(char ** strptr, unsigned int num)
{
    if (num > 0xf)
    {
        str_hex(strptr, num >> 4);
    }
    char * p = *strptr;
    *p++     = "0123456789ABCDEF"[num & 0xf];
    *strptr  = p;
}

// also copies NUL
static void str_copy(char * dest, char * src)
{
    char cdata;
    do
    {
        cdata   = *src++;
        *dest++ = cdata;

    } while (cdata != '\0');
}

// starts CSI sequence or ESC sequence (if c is ESC)
static inline void xansi_begin_csi_or_esc(xansiterm_data * td, char c)
{
    td->state             = (c == '\x1b') ? TSTATE_ESC : TSTATE_CSI;
    td->intermediate_char = 0;
    td->num_parms         = 0;
    xosera_memclear(td->csi_parms, sizeof(td->csi_parms));
}

// process ESC sequence (only single character supported)
static inline void xansi_process_esc(xansiterm_data * td, char cdata)
{
    td->state = TSTATE_NORMAL;
#if DEBUG
    if ((uint8_t)cdata != 0x9b && cdata != '[')
    {
        LOGC(cdata);
    }
#endif
    // NOTE: return if cursor position unaffected (or reset), break to recalculate cur_pos
    switch ((uint8_t)cdata)
    {
        case 0x9b:
            // VT: $9B      CSI
        case '[':
            // VT: <ESC>[   CSI
            xansi_begin_csi_or_esc(td, cdata);
            return;
        case 'c':
            // VT: <ESC>c  RIS reset initial settings
            LOG("=[RIS]");
            td->flags = 0;
            xansi_reset(true);
            xansi_cls();
            return;
        case '7':
            // VT: <ESC>7  DECSC save cursor
            LOG("=[DECSC]");
            td->save_x   = td->x;
            td->save_y   = td->y;
            td->save_lcf = td->lcf;
            return;
        case '8':
            // VT: <ESC>8  DECRC restore cursor
            LOG("=[DECRC]");
            td->x   = td->save_x;
            td->y   = td->save_y;
            td->lcf = td->save_lcf;
            break;
        case '(':
        case ')':
        case '*':
        case '+':
            // VT: <ESC>(  VT220 G0 font EXTENSION: Xosera font 0 (ST 8x16 default)
            // VT: <ESC>)  VT220 G1 font EXTENSION: Xosera font 1 (ST 8x8)
            // VT: <ESC>*  VT220 G2 font EXTENSION: Xosera font 2 (PC 8x8)
            // VT: <ESC>+  VT220 G3 font EXTENSION: Xosera font 3 ()
            td->cur_font = cdata & 0x03;
            LOGF("=[FONT%u]", td->cur_font);
            xansi_reset(false);
            return;
        case 'D':
            // VT: <ESC>D  IND move cursor down (regardless of NEWLINE mode)
            LOG("=[CDOWN]");
            td->y += 1;
            if (td->y >= td->rows)
            {
                td->y -= 1;
                xansi_scroll_up(td);
            }
            break;
        case 'M':
            // VT: <ESC>M  RI move cursor up
            LOG("=[RI]");
            td->y -= 1;
            if (td->y >= td->rows)
            {
                td->y += 1;
                xansi_scroll_down(td);
            }
            break;
        case 'E':
            // VT: <ESC>E  NEL next line
            LOG("=[NEL]");
            td->x = 0;
            td->y += 1;
            if (td->y >= td->cols)
            {
                td->y = td->cols - 1;
                xansi_scroll_up(td);
            }
            break;
        case 'Z':
            // VT: <ESC>Z   DA  send VT101 identifier (older sequence)
            td->send_index = 0;
            str_copy(td->send_buffer, "\x1b[?1;0c");
            LOGF("=[VT101 ID reply=\"<ESC>%s\"]\n", td->send_buffer + 1);
            return;
        case 0x7f:        // ignore DEL and stay in ESC state
            td->state = TSTATE_ESC;
            LOG("=[eaten]");
            return;
        default:
            LOG("=[eaten, bad ESC]");
            return;
    }
    xansi_calc_cur_addr(td);
}

// process a completed CSI sequence
static inline void xansi_process_csi(xansiterm_data * td, char cdata)
{
    static const uint8_t ansi_to_vga_color[8] = {
        0,        // black
        4,        // red
        2,        // green
        6,        // brown (dark yellow)
        1,        // blue
        5,        // magenta
        3,        // cyan
        7         // gray
    };
#if DEBUG
    if (td->intermediate_char)
    {
        LOGF("%c", td->intermediate_char);
    }
    for (uint16_t i = 0; i < td->num_parms; i++)
    {
        LOGF("%s%d", i ? ";" : "", td->csi_parms[i]);
    }
    LOGF("%c\n  := ", cdata);
#endif

    xv_prep();
    td->state      = TSTATE_NORMAL;            // back to NORMAL state
    uint16_t num_z = td->csi_parms[0];         // for default of zero
    uint16_t num   = num_z ? num_z : 1;        // for default of  one

    switch (cdata)
    {
        case 'A':
            // VT: <CSI><n>A  CUU  cursor up (no scroll)
            td->y -= num;
            if (td->y >= td->rows)
            {
                td->y = 0;
            }
            LOGF("[CUP %d]", num);
            break;
        case 'B':
            // VT: <CSI><n>B  CUD  cursor down (no scroll)
            td->y += num;
            if (td->y >= td->rows)
            {
                td->y = td->rows - 1;
            }
            LOGF("[CDOWN %d]", num);
            break;
        case 'C':
            // VT: <CSI><n>C  CUF  cursor right (no scroll)
            td->lcf = false;
            td->x += num;
            if (td->x >= td->cols)
            {
                td->x = td->cols - 1;
            }
            LOGF("[CRIGHT %d]", num);
            break;
        case 'D':
            // VT: <CSI><n>D  CUB   cursor left (no scroll)
            td->x -= num;
            if (td->x >= td->cols)
            {
                td->x = 0;
            }
            LOGF("[CLEFT %d]", num);
            break;
        case 'H':
            // VT: <CSI><row>;<col>H    CUP cursor home / position
        case 'f':
            // VT: <CSI><row>;<col>f    HVP cursor home / position (force)
            td->lcf = false;
            td->x   = td->csi_parms[1] ? td->csi_parms[1] - 1 : 0;
            td->y   = td->csi_parms[0] ? td->csi_parms[0] - 1 : 0;
            if (td->x >= td->cols)
            {
                td->x = td->cols - 1;
            }
            if (td->y >= td->rows)
            {
                td->y = td->rows - 1;
            }
            LOGF("[CPOS row:%d col:%d]", td->y, td->x);
            break;
        case 'h':
        case 'l':
            if (td->intermediate_char == '?')
            {
                if (num == 3)
                {
                    // VT:  <CSI>?3h    DECCOLM 132 (106) column    EXTENSION: video mode 16:9 (848x480)
                    // VT:  <CSI>?3l    DECCOLM 80 column           EXTENSION: video mode 4:3 (640x480)
                    uint16_t res = (cdata == 'h') ? 848 : 640;
                    if (xosera_vid_width() != res)
                    {
                        uint16_t config = (res == 640) ? 0 : 1;
                        LOGF("<reconfig #%d>\n", config);
                        xosera_init(config);
                        xansi_reset(true);
                        xansi_cls();
                        LOGF("[RECONFIG %dx%d]", td->rows, td->cols);
                    }
                }
                else if (num == 5)
                {
                    // VT:  <CSI>?5h    DECSCNM on  screen reverse  EXTENSION: swap fore/back (persistant)
                    // VT:  <CSI>?5l    DECSCNM off screen normal   EXTENSION: swap fore/back (persistant)
                    // fore/back colors
                    td->def_color = (uint8_t)((td->def_color & 0xf0) >> 4) | (uint8_t)((td->def_color & 0x0f) << 4);
                    td->color     = (uint8_t)((td->color & 0xf0) >> 4) | (uint8_t)((td->color & 0x0f) << 4);
                    td->cur_color = (uint8_t)((td->cur_color & 0xf0) >> 4) | (uint8_t)((td->cur_color & 0x0f) << 4);
                    xansi_visualbell(true);
                    LOG("[SCREEN REVERSE]");
                }
                else if (num == 7)
                {
                    // VT:  <CSI>?7h    DECAWM on   autowrap mode on (auto wrap/scroll at EOL) (default)
                    // VT:  <CSI>?7l    DECAWM off  autowrap mode off (cursor stops at right margin)
                    xansi_check_lcf(td);
                    if (cdata == 'l')
                    {
                        LOG("[AUTOWRAP OFF]");
                        td->flags |= TFLAG_NO_AUTOWRAP;
                    }
                    else
                    {
                        LOG("[AUTOWRAP ON]");
                        td->flags &= ~TFLAG_NO_AUTOWRAP;
                    }
                }
                else if (num == 12)
                {
                    // VT:  <CSI>?12h   ATT160 on  blinking cursor (~1/2 second)
                    // VT:  <CSI>?12l   ATT160 off non-blinking cursor
                    if (cdata == 'l')
                    {
                        LOG("[CURSOR NOBLINK]");
                        td->flags |= TFLAG_NOBLINK_CURSOR;
                    }
                    else
                    {
                        LOG("[CURSOR BLINK]");
                        td->flags &= ~TFLAG_NOBLINK_CURSOR;
                    }
                }
                else if (num == 25)
                {
                    // VT:  <CSI>?25h   DECTCEM on  show cursor when waiting for input (default)
                    // VT:  <CSI>?25l   DECTCEM off no cursor
                    if (cdata == 'l')
                    {
                        LOG("[CURSOR HIDE]");
                        td->flags |= TFLAG_HIDE_CURSOR;
                    }
                    else
                    {
                        LOG("[CURSOR SHOW]");
                        td->flags &= ~TFLAG_HIDE_CURSOR;
                    }
                }
            }
            else if (num == 20)
            {
                // VT:  <CSI>?20h   LMN on  newline mode on,  LF also does CR
                // VT:  <CSI>?20l   LMN off newline mode off, LF only (default)
                if (cdata == 'l')
                {
                    LOG("[NEWLINE OFF]");
                    td->flags &= ~TFLAG_NEWLINE;
                }
                else
                {
                    LOG("[NEWLINE ON]");
                    td->flags |= TFLAG_NEWLINE;
                }
            }
            break;
        case 'n':
            // VT: // CSI 5 n    DSR report "OK" with ESC[0n
            // VT: // CSI 6 n    CPR report ESC[Pn;PmR where Pn is the row and Pm is the column
            if (num_z == 5)
            {
                td->send_index = 0;
                str_copy(td->send_buffer, "\x1b[0n");
                LOGF("[DSR STATUS reply=\"<ESC>%s\"]\n", td->send_buffer + 1);
            }
            else if (num_z == 6)
            {
                char * strptr  = td->send_buffer;
                td->send_index = 0;
                *strptr++      = '\x1b';
                *strptr++      = '[';
                str_dec(&strptr, td->y + 1);
                *strptr++ = ';';
                str_dec(&strptr, td->x + 1);
                *strptr++ = 'R';
                *strptr++ = '\0';
                LOGF("[DSR CPR reply=\"<ESC>%s\"]\n", td->send_buffer + 1);
            }
            else
            {
                LOGF("[DSR %d ignored]", num_z);
            }
            break;
        case 'c': {
            // VT: CSI Pn c   DA report pn 0  = ESC[?1;0c         VT101 identify
            // VT:                      pn 68 = ESC[?68;Pv;Pi;Pxc EXTENSION: rosco_m68k/Xosera identify
            //                                                    (version = Pv.Pi, Px = xansi revision)
            if (td->intermediate_char == 0)
            {
                if (num_z == 0)
                {
                    td->send_index = 0;
                    str_copy(td->send_buffer, "\x1b[?1;0c");
                    LOGF("[VT101 ID reply=\"<ESC>%s\"]\n", td->send_buffer + 1);
                }
                else if (num_z == 68)
                {
                    char * strptr  = td->send_buffer;
                    td->send_index = 0;

                    *strptr++ = '\x1b';
                    *strptr++ = '[';
                    *strptr++ = '?';
                    str_dec(&strptr, 68);
                    *strptr++ = ';';
                    *strptr++ = td->ver_code[0];
                    *strptr++ = ';';
                    *strptr++ = td->ver_code[1];
                    *strptr++ = td->ver_code[2];
                    *strptr++ = ';';
                    str_dec(&strptr, XANSI_TERMINAL_REVISION);
                    *strptr++ = 'c';
                    *strptr++ = '\0';
                    LOGF("[Xosera ID reply=\"<ESC>%s\"]\n", td->send_buffer + 1);
                }
                else
                {
                    LOGF("[DA %d ignored]", num_z);
                }
            }
            else
            {
                LOG("[DA response ignored]");
            }
        }
        break;
        case 's':
            // VT: <CSI>s  SCP  save cursor position (ANSI)
            LOG("[CURSOR SAVE]");
            td->save_x   = td->x;
            td->save_y   = td->y;
            td->save_lcf = td->lcf;
            break;
        case 'u':
            // VT: <CSI>u  RCP  restore cursor position (ANSI)
            LOG("[CURSOR RESTORE]");
            td->x   = td->save_x;
            td->y   = td->save_y;
            td->lcf = td->save_lcf;
            break;
        case 'J':
            // VT:  <CSI>J  ED  erase down from cursor line to end of screen
            // VT:  <CSI>1J ED  erase up from cursor line to start of screen
            // VT:  <CSI>2J ED  erase whole screen
            LOGF("[ERASE %s]", num_z == 0 ? "DOWN" : num_z == 1 ? "UP" : num_z == 2 ? "SCREEN" : "?");
            switch (num_z)
            {
                case 0:
                    xansi_clear(xansi_calc_addr(td, 0, td->y), td->vram_end);
                    break;
                case 1:
                    xansi_clear(td->vram_base, xansi_calc_addr(td, td->cols - 1, td->y));
                    break;
                case 2:
                    xansi_clear(td->vram_base, td->vram_end);
                    break;
                default:
                    break;
            }
            break;
        case 'K':
            // VT:  <CSI>K  EL  erase from cursor to end of line
            // VT:  <CSI>1K EL  erase from cursor to start of line
            // VT:  <CSI>2K EL  erase from whole cursor line
            LOGF("[ERASE %s]", num_z == 0 ? "EOL" : num_z == 1 ? "SOL" : num_z == 2 ? "LINE" : "?");
            switch (num_z)
            {
                case 0:
                    xansi_clear(td->cur_addr, xansi_calc_addr(td, td->cols - 1, td->y));
                    break;
                case 1:
                    xansi_clear(xansi_calc_addr(td, 0, td->y), td->cur_addr);
                    break;
                case 2:
                    xansi_clear(xansi_calc_addr(td, 0, td->y), xansi_calc_addr(td, td->cols - 1, td->y));
                    break;
                default:
                    break;
            }
            break;
        case 'm':
            // VT: <CSI><n>m    SGR   set graphic rendition
            if (td->num_parms == 0)        // if no parameters
            {
                td->num_parms = 1;        // parameter zero will be 0 default
            }

            for (uint16_t i = 0; i < td->num_parms; i++)
            {
                bool def_flag = false;        // flag for default color set
                (void)def_flag;               // no warnings if unused

                uint16_t parm_code = td->csi_parms[i];        // attribute parameter
                uint8_t  col       = parm_code % 10;          // modulo ten color

                // special set default fore/back
                if (parm_code == 38 || parm_code == 48)
                {
                    if (i + 2 >= td->num_parms || td->csi_parms[i + 1] != 5)
                    {
                        LOG("[Err: setcolor mode !=5]");
                    }
                    else
                    {
                        col = td->csi_parms[i + 2] & 0xf;
                    }

                    i = td->num_parms;        // no more parameters after this
                }

                if (((parm_code >= 30 && parm_code <= 39) || (parm_code >= 40 && parm_code <= 49) ||
                     (parm_code >= 90 && parm_code <= 97) || (parm_code >= 100 && parm_code <= 107)) &&
                    col < 8)        // normal color 0-7 range
                {
                    col = ansi_to_vga_color[col];        // convert from ANSI color to VGA
                    // light color ranges?
                    if (parm_code >= 90)        // if a light color range, set to normal color range
                    {
                        col += 8;        // make color light
                        parm_code = (parm_code < 100) ? 30 : 40;
                    }
                }

                LOGF("<parm=%d>", parm_code);
                switch (parm_code)
                {
                    case 0:
                        // VT: SGR parm 0    reset   reset all attributes and default color
                        LOG("[RESET]");
                        td->flags &=
                            ~(TFLAG_ATTRIB_BRIGHT | TFLAG_ATTRIB_DIM | TFLAG_ATTRIB_REVERSE | TFLAG_ATTRIB_PASSTHRU);
                        td->cur_color = td->def_color;        // restore default color
                        break;
                    case 1:
                        // VT: SGR parm 1   bright  select bright colors (8-15)
                        LOG("[BRIGHT]");
                        td->flags &= ~TFLAG_ATTRIB_DIM;
                        td->flags |= TFLAG_ATTRIB_BRIGHT;
                        break;
                    case 2:
                        // VT: SGR parm 2   dim     select dim colors (0-7)
                        LOG("[DIM]");
                        td->flags &= ~TFLAG_ATTRIB_BRIGHT;
                        td->flags |= TFLAG_ATTRIB_DIM;
                        break;
                    case 7:
                        // VT: SGR parm 7   reverse swap fore/back colors
                        LOG("[REVERSE]");
                        td->flags |= TFLAG_ATTRIB_REVERSE;
                        break;
                    case 8:
                        // VT: SGR parm 8   hidden  EXTENSION: ctrl char graphic pass-through
                        LOG("[PASSTHRU]");
                        td->flags |= TFLAG_ATTRIB_PASSTHRU;
                        break;
                    case 39:
                        // VT: SGR parm 39  select default forground color
                        def_flag = true;
                        col      = td->def_color & 0xf;        // falls through
                        goto case_37;
                        break;
                    case 30:
                    case 31:
                    case 32:
                    case 33:
                    case 34:
                    case 35:
                    case 36:
                    case 37:
                    case_37:
                        // VT: SGR parm 30-37   select forground color
                        td->cur_color = (uint8_t)(td->cur_color & 0xf0) | col;
                        LOGF("[%sFORE=%x]", def_flag ? "DEF_" : "", col);
                        break;
                    case 38:
                        // VT: SGR parm 38;5;n  change default forground color
                        td->def_color = (uint8_t)(td->def_color & 0xf0) | col;
                        td->cur_color = (uint8_t)(td->cur_color & 0xf0) | col;
                        LOGF("[SETDEF_FORE=%x]", col);
                        break;
                    case 49:
                        // VT: SGR parm 49  select default background color
                        col      = td->def_color >> 4;
                        def_flag = true;
                        goto case_47;
                        break;
                    case 40:
                    case 41:
                    case 42:
                    case 43:
                    case 44:
                    case 45:
                    case 46:
                    case 47:
                    case_47:
                        // VT: SGR parm 40-47   select background color
                        td->cur_color = (uint8_t)(td->cur_color & 0x0f) | ((uint8_t)(col << 4));
                        LOGF("[%sBACK=%x]", def_flag ? "DEF_" : "", col);
                        break;
                    case 48:
                        // VT: SGR parm 48;5;n  change default background color
                        td->def_color = (uint8_t)(td->def_color & 0x0f) | ((uint8_t)(col << 4));
                        td->cur_color = (uint8_t)(td->cur_color & 0x0f) | ((uint8_t)(col << 4));
                        LOGF("[SETDEF_BACK=%x]", col);
                        break;
                    case 68:
                        // VT: SGR parm 68  rosco_m68k  EXTENSION: rosco_m68k Xosera commands
                        LOG("[ROSCO_M68K=68;");
                        bool rosco_cmd_good = false;
                        (void)rosco_cmd_good;
                        if (i + 3 < td->num_parms)        // must have at least rosco_cmd, n, parm0
                        {
                            uint16_t rosco_cmd = td->csi_parms[++i];
                            uint16_t n         = td->csi_parms[++i];
                            uint16_t parm0     = td->csi_parms[++i];


                            LOGF("%03u;", rosco_cmd);
                            switch (rosco_cmd)
                            {
                                // VT: SGR 68;000;<n>;<val>>m   n=1 vram addr, 2=line_len, 3=lines_high
                                case 0:
                                    if (n >= 1 && n <= 3)        // n valid
                                    {
                                        if (n == 1)
                                        {
                                            td->vram_base = parm0;
                                            LOGF(" vram_base=0x%04x", parm0);
                                        }
                                        else if (n == 2)
                                        {
                                            td->line_len = parm0;
                                            LOGF(" line_len=0x%04x", parm0);
                                        }
                                        else if (n == 3)
                                        {
                                            td->lines_high = parm0;
                                            LOGF(" lines_high=0x%04x", parm0);
                                        }
                                        rosco_cmd_good = true;
                                    }
                                    break;
                                // VT: SGR 68;010;<n>;<r>;<g>;<b>m  set COLOR_MEM[n] = RGB (each 0-255)
                                case 10:
                                    if (n < 256 && (i + 2) < td->num_parms)
                                    {
                                        uint16_t rgb = ((uint16_t)(parm0 & 0xf0) << 4) |
                                                       ((uint16_t)(td->csi_parms[i + 1] & 0xf0) << 0) |
                                                       ((uint16_t)(td->csi_parms[i + 2] & 0xf0) >> 4);

                                        xmem_setw(XR_COLOR_ADDR + n, rgb);
                                        LOGF(" COLOR_MEM[%u]=0x%03x", n, rgb);
                                        rosco_cmd_good = true;
                                    }
                                    break;
                                // VT: SGR 68;012;<n><tile_ctrl>m   set Xosera TILE_CTRL value for font n (0-3)
                                case 12:
                                    if (n < 4)
                                    {
                                        td->tile_ctrl[n] = parm0;
                                        LOGF(" FONT%u TILE_CTRL=0x%04x", n, parm0);
                                        rosco_cmd_good = true;
                                    }
                                    break;
                                // VT: SGR 68;020;16;<gfx_ctrl>m    set Xosera GFX_CTRL register value
                                case 20:
                                    if (n == XR_PA_GFX_CTRL)
                                    {
                                        td->gfx_ctrl = parm0;
                                        LOGF(" GFX_CTRL=0x%04x", parm0);
                                        rosco_cmd_good = true;
                                    }
                                    break;
                                // VT: SGR 68;030;<n>;<val>m        n=1 cursor_glyph word, 2=cursor_glyph word mask
                                case 30:
                                    if (n == 1)
                                    {
                                        td->cursor_glyph = parm0;
                                        LOGF(" cursor_glyph=0x%04x", parm0);
                                        rosco_cmd_good = true;
                                    }
                                    else if (n == 2)
                                    {
                                        td->cursor_mask = parm0;
                                        LOGF(" cursor_mask=0x%04x", parm0);
                                        rosco_cmd_good = true;
                                    }
                                    break;
                                default:
                                    break;
                            }
                        }
                        LOGF("%s]", rosco_cmd_good ? "" : "<bad>");
                        i = td->num_parms;        // eat remaning parms
                        break;
                    default:
                        LOGF("[SGR %d ignored]", parm_code);
                        break;
                }
                // calculate effective color
                if (td->flags & TFLAG_ATTRIB_REVERSE)
                {
                    td->color = ((uint8_t)(td->cur_color & 0xf0) >> 4) | (uint8_t)((td->cur_color & 0x0f) << 4);
                }
                else
                {
                    td->color = td->cur_color;
                }
                if (td->flags & TFLAG_ATTRIB_DIM)
                {
                    td->color &= ~0x08;
                }
                if (td->flags & TFLAG_ATTRIB_BRIGHT)
                {
                    td->color |= 0x08;
                }
            }
            break;
        default:
            LOG("[ignored CSI final ");
            LOGC(cdata);
            LOG("]");
            break;
    }

    xansi_calc_cur_addr(td);
}

// parse CSI sequence
static inline void xansi_parse_csi(xansiterm_data * td, char cdata)
{
    uint8_t cclass = cdata & 0xf0;
    // ignore ctrl characters (mostly)
    if ((int8_t)cdata <= ' ' || cdata == 0x7f)        // NOTE: also ignores negative (high bit set)
    {
        LOG("[");
        LOGC(cdata);
        LOG(" eaten]");
        return;
    }
    else if (cclass == 0x20)        // intermediate char
    {
        if (td->intermediate_char)
        {
            LOG("[2nd intermediate]");
        }
        td->intermediate_char = cdata;
    }
    else if (cclass == 0x30)        // parameter number
    {
        uint8_t d = (uint8_t)(cdata - '0');
        if (d <= 9)
        {
            if (td->num_parms == 0)        // if no parms use parm 0 as default zero
            {
                td->num_parms = 1;
            }
            uint16_t v = td->csi_parms[td->num_parms - 1];
            v *= (uint16_t)10;
            if ((uint16_t)(v + d) < v)        // check for unsigned wrap
            {
                v = 65535;
            }
            else
            {
                v += d;
            }
            td->csi_parms[td->num_parms - 1] = v;
        }
        else if (cdata == ';')
        {
            td->num_parms++;
            if (td->num_parms >= MAX_CSI_PARMS)
            {
                LOG("[ERR: illegal parms >16]\n");
                td->state = TSTATE_ILLEGAL;
            }
        }
        else if (td->intermediate_char != 0 || cdata == ':')
        {
            LOG("[ERR: illegal char]\n");
            td->state = TSTATE_ILLEGAL;
        }
        else
        {
            td->intermediate_char = cdata;
        }
    }
    else if (cclass >= 0x40)
    {
        xansi_process_csi(td, cdata);
    }
    else
    {
        // enter ILLEGAL state (until CAN, SUB or final character)
        LOG("[ERR: illegal ");
        LOGC(cdata);
        LOG("]");
        td->state = TSTATE_ILLEGAL;
    }
}

#pragma GCC pop_options        // end -Os

// external public console terminal functions
#pragma GCC push_options
#pragma GCC optimize("-O3")

// output character to console
void xansiterm_PRINTCHAR(char cdata)
{
    char str[2];
    str[0] = cdata;
    str[1] = '\0';
    if (cdata)
    {
        xansiterm_PRINT(str);
        return;
    }
    else
    {
        // allow printing NUL (useful only if PASSTHRU)
        LOG("[NUL]");
        xansiterm_data * td = get_xansi_data();
        xansi_erase_cursor(td);
        if (td->state == TSTATE_NORMAL && (td->flags & TFLAG_ATTRIB_PASSTHRU))
        {
            xansi_drawchar(td, 0);
        }
    }
}

// output NUL terminated string to terminal
const char * xansiterm_PRINT(const char * strptr)
{
    xansiterm_data * td = get_xansi_data();
    xansi_erase_cursor(td);

    char cdata;
    while ((cdata = *strptr++) != '\0')
    {
#if DEBUG
        // these are used to help DEBUG various state changes
        uint8_t  initial_state    = td->state;
        uint8_t  initial_flags    = td->flags;
        uint8_t  initial_cur_col  = td->cur_color;
        uint8_t  initial_col      = td->color;
        uint16_t initial_cur_addr = td->cur_addr;
        uint16_t initial_x        = td->x;
        uint16_t initial_y        = td->y;
        uint16_t initial_lcf      = td->lcf;

        xansi_assert_xy_valid(td);        // DEBUG
#endif

        // ESC or 8-bit CSI received
        if ((cdata & 0x7f) == '\x1b')
        {
            // if already ESC/CSI and in PASSTHRU mode
            if (td->state >= TSTATE_ESC && (td->flags & TFLAG_ATTRIB_PASSTHRU))
            {
                td->state = TSTATE_NORMAL;        // fall through and print ESC/CSi
            }
            else
            {
                // otherwise start new CSI/ESC
                xansi_begin_csi_or_esc(td, cdata);
                goto nextchar;
            }
        }

        if (td->state == TSTATE_NORMAL)
        {
            xansi_processchar(td, cdata);
        }
        else if (cdata == '\x18' || cdata == '\x1A')
        {
            // VT:  \x18    CAN terminate current CSI sequence, otherwise ignored
            // VT:  \x1A    SUB terminate current CSI sequence, otherwise ignored
            LOG("[CANCEL: ");
            LOGC(cdata);
            LOG("]");
            td->state = TSTATE_NORMAL;
        }
        else if (td->state == TSTATE_ESC)        // NOTE: only one char sequences supported
        {
            xansi_process_esc(td, cdata);
        }
        else if (td->state == TSTATE_CSI)
        {
            xansi_parse_csi(td, cdata);
        }
        else if (td->state == TSTATE_ILLEGAL)
        {
            if (cdata >= 0x40)
            {
                td->state = TSTATE_NORMAL;
                LOG("end Illegal: ");
                LOGC(cdata);
                LOG("]");
            }
            else
            {
                LOG("[illegal: ");
                LOGC(cdata);
                LOG(" eaten]");
            }
        }

    nextchar:;
#if DEBUG
        // show altered state in log
        if (initial_state == TSTATE_NORMAL)
        {
            LOGC(cdata);
            if ((uint8_t)cdata < ' ')
            {
                LOG("\n");
            }
        }
        if (initial_flags != td->flags)
        {
            LOGF("{Flags:%02x->%02x}", initial_flags, td->flags);
        }
        if (initial_cur_col != td->cur_color || initial_col != td->color)
        {
            LOGF("{Color:%02x:%02x->%02x:%02x}", initial_cur_col, initial_col, td->cur_color, td->color);
        }
        if ((initial_cur_addr != td->cur_addr) || (initial_x != td->x) || (initial_y != td->y) ||
            (initial_lcf != td->lcf))
        {
            LOGF("{CPos:%04x %d,%d %d->%04x %d,%d %d}",
                 initial_cur_addr,
                 initial_x,
                 initial_y,
                 initial_lcf,
                 td->cur_addr,
                 td->x,
                 td->y,
                 td->lcf);
        }
        if (td->state != initial_state)
        {
            LOGF("%s",
                 td->state == TSTATE_NORMAL    ? "\n<TXT>"
                 : td->state == TSTATE_ILLEGAL ? "\n<ILL>"
                 : td->state == TSTATE_ESC     ? "\n<ESC>"
                                               : "\n<CSI>");
        }

        xansi_assert_xy_valid(td);
#endif
    }

    return strptr;
}

const char * xansiterm_PRINTLN(const char * strptr)
{
    const char * end = xansiterm_PRINT(strptr);
    xansiterm_PRINT("\r\n");
    return end;
}

void xansiterm_SETCURSOR(bool showcursor)
{
    xansiterm_data * td = get_xansi_data();

    xansi_erase_cursor(td);
    if (showcursor)
    {
        LOG("SetCursor(CURSOR SHOW)\n");
        td->flags &= ~TFLAG_HIDE_CURSOR;
    }
    else
    {
        LOG("SetCursor(CURSOR HIDE)\n");
        td->flags |= TFLAG_HIDE_CURSOR;
    }
}

// terminal read QUERY reply (call when td->send_index >= 0)
char xansiterm_RECVQUERY(void)
{
    xansiterm_data * td = get_xansi_data();
    // sending query
    char cdata = 0;
    if (td->send_index >= 0)
    {
        cdata = td->send_buffer[td->send_index];
        LOGF("<recvchar QUERY[%d] = ", td->send_index);
        LOGC(cdata);
        td->send_index += 1;
        if (td->send_buffer[td->send_index] == '\0')
        {
            td->send_index = -1;
            LOG(" END");
        }
        LOG(">\n");
    }
    else
    {
        LOG("{bad RECVQUERY}\n");
    }
    return cdata;
}

// terminal check for input character ready (wrapper console checkchar with cursor)
void xansiterm_UPDATECURSOR(void)
{
    xansiterm_data * td = get_xansi_data();

    // if cursor is hidden, don't do lcf scroll
    if (td->flags & TFLAG_HIDE_CURSOR)
    {
        return;
    }

    // blink at ~409.6ms (on half the time, but only if cursor not disabled and no char ready)
    volatile uint8_t * timer_bh_ptr = (volatile uint8_t *)(XM_BASEADDR + XM_TIMER);
    bool               cursor_on    = (td->flags & TFLAG_NOBLINK_CURSOR) || (*timer_bh_ptr) & 0x08;
    xansi_check_lcf(td);        // wrap cursor if needed
    if (cursor_on)
    {
        xansi_draw_cursor(td);
    }
    else
    {
        xansi_erase_cursor(td);
    }
}

void xansiterm_ERASECURSOR(void)
{
    xansiterm_data * td = get_xansi_data();
    xansi_erase_cursor(td);
}

#pragma GCC pop_options        // end -O3

// init function can be small
#pragma GCC push_options
#pragma GCC optimize("-Os")

static const char xansiterm_banner[] =
    "\r\n\x1b[93m"
    "                                ___ ___ _\r\n"
    " ___ ___ ___ __ ___       _____|  _| . | |_\r\n"
    "|  _| . |_ -| _| . |     |     | . | . | '_|\r\n"
    "|_| |___|___|__|___|_____|_|_|_|___|___|_,_|\r\n"
    "\x1b[35mX\x1b[93mo\x1b[33ms\x1b[96me\x1b[92mr\x1b[91ma \x1b[0mv";                              // 0.20
static const char xansiterm_banner2[] = " XANSI \x1b[93m|_____|\x1b[1;37m  Classic \x1b[0m";        // 2.30.DEV\r\n;


// initialize XANSI // TODO: ICP default values in flash config
bool xansiterm_INIT()
{
    xosera_info_t init_data;

    LOGF("\n[xansiterm_INIT: xosera_init(%d) ", DEFAULT_XOSERA_CONFIG);
    bool reconfig_ok = xosera_init(DEFAULT_XOSERA_CONFIG);
    LOGF(" %s]\n", reconfig_ok ? "succeeded" : "FAILED");

    if (!reconfig_ok)
    {
        return false;
    }
    xansiterm_data * td = get_xansi_data();
    xosera_memclear(td, sizeof(*td));
    // default values (others will be zero or computed)
    td->device_inputchar  = _EFP_INPUTCHAR;
    td->device_checkinput = _EFP_CHECKINPUT;
    td->gfx_ctrl = MAKE_GFX_CTRL(0x00, 0, 0, 0, 0, 0);          // 16-colors 0-15, 1-BPP tiled, H repeat x1, V repeat x1
    td->tile_ctrl[0] = MAKE_TILE_CTRL(0x0000, 0, 0, 16);        // 1st font in tile RAM (8x16 ST font - default)
    td->tile_ctrl[1] = MAKE_TILE_CTRL(0x0800, 0, 0, 8);         // 2nd font in tile RAM (8x8 ST font)
    td->tile_ctrl[2] = MAKE_TILE_CTRL(0x0C00, 0, 0, 8);         // 3rd font in tile RAM (8x8 PC font)
    td->tile_ctrl[3] = MAKE_TILE_CTRL(0x1000, 0, 0, 8);         // 4th font in tile RAM (8x8 hex font)
    td->def_color    = DEFAULT_COLOR;                           // default dark-green on black
    td->send_index   = -1;

    xv_prep();
    xreg_setw(PA_GFX_CTRL, td->gfx_ctrl);
    xm_setbl(SYS_CTRL, 0x0F);

    // NOTE: Not ideal no version code without COPPER
    td->ver_code[0] = '0';
    td->ver_code[1] = '0';
    td->ver_code[2] = '0';

    if (xosera_get_info(&init_data))
    {
        td->ver_code[0] = '0' + (init_data.version_bcd >> 8);                 // Xosera vX.xx
        td->ver_code[1] = '0' + ((init_data.version_bcd >> 4) & 0x0f);        // Xosera vx.Xx
        td->ver_code[2] = '0' + (init_data.version_bcd & 0xf);                // Xosera vx.xX
    }

    xansi_reset(true);
    xansiterm_PRINT(xansiterm_banner);
    char * vs = init_data.description_str;
    *vs++     = td->ver_code[0];
    *vs++     = '.';
    *vs++     = td->ver_code[1];
    *vs++     = td->ver_code[2];
    *vs++     = '\0';
    xansiterm_PRINT(init_data.description_str);
    xansiterm_PRINT(xansiterm_banner2);
    char * ft = init_data.description_str;
    if (!(_FIRMWARE_REV & (1U << 31)))
    {
        *ft++ = ' ';
        *ft++ = ' ';
        *ft++ = ' ';
        *ft++ = ' ';
    }
    str_hex(&ft, (_FIRMWARE_REV >> 8) & 0xf);
    *ft++ = '.';
    str_hex(&ft, (_FIRMWARE_REV >> 0) & 0xff);
    if (_FIRMWARE_REV & (1U << 31))
    {
        *ft++ = '.';
        *ft++ = 'D';
        *ft++ = 'E';
        *ft++ = 'V';
    }
    *ft++ = '\0';
    xansiterm_PRINTLN(init_data.description_str);
    xansiterm_PRINTLN(0);

    return true;
}

#pragma GCC pop_options        // end -Os

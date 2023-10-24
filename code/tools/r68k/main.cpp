#include <iostream>
#include <filesystem>
#include <stdint.h>
#include <unistd.h>
#include <thread>
#include <atomic>
#include <termios.h>
#include <sys/select.h>
#include <fcntl.h>
#include <iomanip>

#include "musashi/m68k.h"
#include "musashi/m68kcpu.h"
#include "AddressDecoder.h"

using namespace std;

#define DUART_IRQ	4
#define DUART_VEC	0x45

#define TICK_COUNT 0x408
#define ECHO_ON    0x410
#define PROMPT_ON  0x411
#define LF_DISPLAY 0x412

struct termios originalTermios;

void init_term() {
    struct termios newTermios;

    tcgetattr(STDIN_FILENO, &originalTermios);

    newTermios = originalTermios;
    newTermios.c_lflag &= ~(ICANON | ECHO);
    newTermios.c_iflag &= ~(ICRNL | INLCR);

    tcsetattr(STDIN_FILENO, TCSANOW, &newTermios);

    int flags = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);
}

bool check_char() {
    fd_set readfds;
    FD_ZERO(&readfds);
    FD_SET(STDIN_FILENO, &readfds);

    struct timeval timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 0;

    return select(STDIN_FILENO + 1, &readfds, NULL, NULL, &timeout) > 0;
}

char read_char() {
    char c = 0;
    while (c == 0) {
        read(STDIN_FILENO, &c, 1);
    }
    return c;
}

// easy68k helper functions

#define BUF_LEN 78
#define BUF_MAX BUF_LEN - 2
static uint8_t buf[BUF_LEN];

static uint8_t digit(unsigned char digit) {
    if (digit < 10) {
        return (char)(digit + '0');
    } else {
        return (char)(digit - 10 + 'A');
    }
}

static char* print_unsigned(uint32_t num, uint8_t base) {
    if (base < 2 || base > 36) {
        buf[0] = 0;
        return (char *)buf;
    }

    unsigned char bp = BUF_MAX;

    if (num == 0) {
        buf[bp--] = '0';
    } else {
        while (num > 0) {
            buf[bp--] = digit(num % base);
            num /= base;
        }
    } 

    return ((char*)&buf[bp+1]);
}

extern "C" {
    rosco::m68k::emu::AddressDecoder* __mem;
    std::fstream ifs("rosco_sd.bin", std::ios::binary | std::ios::ate | std::ios::in | std::ios::out);

    int illegal_instruction_handler(int __attribute__((unused)) opcode) {
        m68ki_cpu_core ctx;
        m68k_get_context(&ctx);

        uint32_t d7 = m68k_get_reg(&ctx, M68K_REG_D7);
        uint32_t d6 = m68k_get_reg(&ctx, M68K_REG_D6);
        uint32_t d0 = m68k_get_reg(&ctx, M68K_REG_D0);
        uint32_t d1 = m68k_get_reg(&ctx, M68K_REG_D1);
        uint32_t d2 = m68k_get_reg(&ctx, M68K_REG_D2);
        uint32_t a0 = m68k_get_reg(&ctx, M68K_REG_A0);
        uint32_t a1 = m68k_get_reg(&ctx, M68K_REG_A1);
        uint32_t a2 = m68k_get_reg(&ctx, M68K_REG_A2);
        uint32_t a7 = m68k_get_reg(&ctx, M68K_REG_A7);

        if ((d7 & 0xFFFFFF00) == 0xF0F0F000 && d6 == 0xAA55AA55) {
            // It's a trap!

            // below leaves Easy68k ops from E0 and up, others from 0 ..
            uint8_t op = d7 & 0x000000FF;
            if (op >= 0xF0) {
                op &= 0x0F;
            } 

            uint8_t c;
            bool r;
            int ptr;
            int chars_left = 0;
            int chars_read = 0;
            int num = 0;
            
            switch (op) {				
                case 0:
                    // Print
                    do {
                         c = m68k_read_memory_8(a0++);
                         if (c) {
                            cout << c;
                         }
                    } while (c != 0);

                    break;
                case 1:
                    // println
                    do {
                         c = m68k_read_memory_8(a0++);
                         if (c) {
                            cout << c;
                         }
                    } while (c != 0);

                    cout << endl;

                    break;
                case 2:
                    // printchar
                    c = (d0 & 0xFF);
                    if (c) {
                        cout << c;
                    }

                    break;
                case 3:
                    // prog_exit
                    m68k_pulse_halt();
                    tcsetattr(STDIN_FILENO, TCSANOW, &originalTermios);
                    exit(m68k_read_memory_32(a7 + 4));       // assuming called from cstdlib - C will have stacked an exit code
                    break;
                case 4:
                    // check_char
                    r = check_char();
                    m68k_set_reg(M68K_REG_D0, r ? 1 : 0);

                    break;
                case 5:
                    // read_char
                    cout << flush;
                    c = read_char();
                    cout << flush;
                    m68k_set_reg(M68K_REG_D0, c);

                    break;
                case 6:
                    // sd_init
                    if (!ifs) {
                        m68k_set_reg(M68K_REG_D0, 1);
                    } else {
                        m68k_write_memory_8(a1+0, 1);		// Initialized
                        m68k_write_memory_8(a1+1, 2);		// SDHC
                        m68k_write_memory_8(a1+2, 0);		// No current block
                        m68k_write_memory_32(a1+3, 0);		// Ignored (current block num)
                        m68k_write_memory_16(a1+7, 0);		// Ignored (current block offset)
                        m68k_write_memory_8(a1+9, 0);		// No partial reads (_could_ support, just don't yet)
                        m68k_set_reg(M68K_REG_D0, 0);		// Success
                    }
                    break;
                case 7:
                    // sd_read
                    if (ifs && m68k_read_memory_8(a1) > 0) {
                        std::vector<char> buf(512);

                        ifs.clear();
                        ifs.seekg(d1 * 512, std::ios::beg);
                        ifs.read(&buf.front(), 512);

                        if (ifs.gcount() == 512) {
                            for (auto data : buf) {
                                m68k_write_memory_8(a2++, data);
                            }

                            m68k_set_reg(M68K_REG_D0, 1);		    // succeed
                        } else {
                            cout << "!!! Bad Read" << endl;
                            m68k_set_reg(M68K_REG_D0, 0);		// fail
                        }
                    } else {						
                        cout << "!!! Not init" << endl;
                        m68k_set_reg(M68K_REG_D0, 0);		// fail
                    }

                    break;
                case 8:
                    // sd_write
                    if (a2 < 0xe00000 && ifs && m68k_read_memory_8(a1) > 0) {
                        std::vector<char> buf(512);

                        for (int i = 0; i < 512; i++) {
                            buf[i] = m68k_read_memory_8(a2++);
                        }

                        ifs.clear();
                        ifs.seekg(d1 * 512, std::ios::beg);
                        ifs.write(&buf.front(), 512);

                        if (ifs.gcount() == 512) {
                            m68k_set_reg(M68K_REG_D0, 1);		    // succeed
                        } else {
                            cout << "!!! Bad Write" << endl;
                            m68k_set_reg(M68K_REG_D0, 0);		// fail
                        }
                    } else {						
                        cout << "!!! Not init or out of bounds" << endl;
                        m68k_set_reg(M68K_REG_D0, 0);		// fail
                    }

                    break;
                // Start of Easy68k traps
                case 0xD0:
                case 0xD1:
                    // PRINT_LN_LEN / PRINT_LEN
                    do {
                         c = m68k_read_memory_8(a1++);
                         if (c) {
                            cout << c;
                         }
                    } while ((c != 0) && ((--d1 & 0xFF) > 0));

                    if (op == 0xD0) {
                        cout << endl;
                    }

                    break;
                case 0xD2:
                    // READSTR
                    if (m68k_read_memory_8(PROMPT_ON) == 1) {
                        cout << "Input$> ";
                    } 

                    chars_read = 0;
                    ptr = a1;  // save start of input buffer
                    
                    while (chars_read++ < 80) {
                        cout << flush;
                        c = read_char();
                        cout << flush;

                        if (c == 0x0D) {
                            break;
                        }

                        if (m68k_read_memory_8(ECHO_ON) == 1) {
                            cout << c;
                        }

                        m68k_write_memory_8(a1++, c);
                    }

                    m68k_write_memory_8(a1++, 0);

                    if (m68k_read_memory_8(LF_DISPLAY) == 1) {
                        cout << endl;
                    }

                    m68k_set_reg(M68K_REG_D1, (chars_read - 1)); 
                    m68k_set_reg(M68K_REG_A1, ptr); 

                    break;
                case 0xD3:
                    // DISPLAYNUM_SIGNED
                    cout << (int)d1;

                    break;
                case 0xD4:
                    // READNUM
                    if (m68k_read_memory_8(PROMPT_ON) == 1) {
                        cout << "Input#> ";
                    }
                    
                    while (--chars_left) {
                        cout << flush;
                        c = read_char();
                        cout << flush;

                        if (c == 0x0D) {
                            break;
                        }
                    
                        if ((c >= '0') && (c <= '9')) {
                            num = (num * 10) + (c - '0');
                            if (m68k_read_memory_8(ECHO_ON) == 1) {
                                cout << c;
                            }
                        } 
                    }
                    if (m68k_read_memory_8(LF_DISPLAY) == 1) {
                        cout << endl;
                    }
                    m68k_set_reg(M68K_REG_D1, num);

                    break;
                case 0xD5:
                    // READCHAR
                    cout << flush;
                    c = read_char();
                    cout << flush;
                    m68k_set_reg(M68K_REG_D1, c);

                    break;
                case 0xD6:
                    // SENDCHAR
                    cout << (char) (d1 & 0xFF);
                    
                    break;
                case 0xD7:
                    // CHECKINPUT
                    r = check_char();
                    m68k_set_reg(M68K_REG_D1, r ? 1 : 0);

                    break;
                case 0xD8:
                    // GETUPTICKS
                    m68k_set_reg(M68K_REG_D1, m68k_read_memory_16(TICK_COUNT));
                    
                    break;
                case 0xD9:
                    // TERMINATE
                    m68k_pulse_halt();
                    tcsetattr(STDIN_FILENO, TCSANOW, &originalTermios);
                    exit(0);

                    break;
                // case 0xDA:
                    // Note implemented
                    
                case 0xDB:
                    // MOVEXY
                    if ((d1 & 0xFFFF) == 0xFF00) {
                        // clear screen
                        cout << endl << "easy68k CLRSCR 0xDB not implemneted" << endl;
                    } else {
                        // Move X, Y
                        cout << endl << "easy68k MOVE X,Y 0xDB " << ((d1 & 0xFF00) >> 8) << "," << (d1 & 0xFF) << " not implemented" << endl;
                    }

                    break;
                case 0xDC:
                    // SETECHO
                    if (d1 == 0) {
                        m68k_write_memory_8(ECHO_ON, 0);
                    }
                    if (d1 == 1) {
                        m68k_write_memory_8(ECHO_ON, 1);
                    }

                    break;
                case 0xDD:
                case 0xDE:
                    // PRINTLN_SZ / PRINT_SZ
                    do {
                         c = m68k_read_memory_8(a1++);
                         if (c) {
                            cout << c;
                         }
                    } while (c != 0);

                    if (op == 0xDD) {
                        cout << endl;
                    }

                    break;
                case 0xDF:
                    // PRINT_UNSIGNED
                    cout << print_unsigned(d1, d2);

                    break;
                case 0xE0:
                    // SETDISPLAY
                    if (d1 == 0) {  
                        m68k_write_memory_8(PROMPT_ON, 0);                        
                    }
                    if (d1 == 1) {  
                        m68k_write_memory_8(PROMPT_ON, 1);                        
                    }
                    if (d1 == 2) {  
                        m68k_write_memory_8(LF_DISPLAY, 0);                        
                    }
                    if (d1 == 3) {  
                        m68k_write_memory_8(LF_DISPLAY, 1);                        
                    }

                    break;
                case 0xE1:
                    // PRINTSZ_NUM
                    do {
                         c = m68k_read_memory_8(a1++);
                         if (c) {
                            cout << c;
                         }
                    } while (c != 0);

                    cout << (int)d1;

                    break;
                case 0xE2:
                    // PRINTSZ_READ_NUM
                    do {
                         c = m68k_read_memory_8(a1++);
                         if (c) {
                            cout << c;
                         }
                    } while (c != 0);
                    
                    chars_left = 10;
                    
                    while (--chars_left) {
                        cout << flush;
                        c = read_char();
                        cout << flush;

                        if (c == 0x0D) {
                            break;
                        }
                    
                        if ((c >= '0') && (c <= '9')) {
                            num = (num * 10) + (c - '0');
                            if (m68k_read_memory_8(ECHO_ON) == 1) {
                                cout << c;
                            }
                        } 
                    }
                    if (m68k_read_memory_8(LF_DISPLAY) == 1) {
                        cout << endl;
                    }
                    m68k_set_reg(M68K_REG_D1, num);

                    break;
                // case 0xE3:
                    // Not implemented

                case 0xE4:
                    // PRINTNUM_SIGNED_WIDTH
                    cout << setw(d2) << (int)d1;
                    break;
                
                default:
                    cerr << "<UNKNOWN OP " << hex << op << "; D7=0x" << hex << d7 << "; D6=0x" << d6 << ": IGNORED>" << endl;
            }
        }

        return 1;
    }

    int interrupt_ack_handler(unsigned int irq) {
        switch (irq) {
        case DUART_IRQ:
            // DUART timer tick - vector to 0x45
            m68k_set_irq(0);
            return DUART_VEC;
        default:
            cerr << "WARN: Unexpected IRQ " << irq << "; Autovectoring, but machine will probably lock up!" << endl;
            return M68K_INT_ACK_AUTOVECTOR;
        }
    }
}

std::atomic_bool is_done;

void timer_interrupt() {
    int i = 100;

    while (!is_done) {
        if (i++ == 100) {
            m68k_set_irq(DUART_IRQ);
            i = 0;
        }

        usleep(100);
    }
}

int main(int argc, char** argv) {
    if (argc != 2) {
        cout << "Usage: xl86 <binary>" << endl;
        return 1;
    } else {
        init_term();

        std::filesystem::path path = std::filesystem::path(argv[0]).parent_path();
        path += "/firmware/rosco_m68k.rom";

        __mem = new rosco::m68k::emu::AddressDecoder(0x40000, 0x100000, path.string().c_str());
        __mem->LoadMemoryFile(0x40000, argv[1]);

        m68k_set_cpu_type(M68K_CPU_TYPE_68010);
        m68k_init();
        m68k_pulse_reset();

        m68ki_cpu_core ctx;
        m68k_get_context(&ctx);
        
        std::thread timer_thread(timer_interrupt);
        while (1) {
            m68k_execute(100000);
            m68k_get_context(&ctx);
        }

        is_done = true;
        timer_thread.join();

        delete(__mem);
        return 0;
    }
}

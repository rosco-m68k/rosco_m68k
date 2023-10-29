/****************************************************************************
 *
 *                                  ___ ___ _  
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|         libraries
 *
 *
 ****************************************************************************
 * m68k GDB remote debug stub
 *
 * This file is available in the public domain.
 *
 * This is merely a tidied up, modernised version of the standard m68k 
 * debug stub included in the GDB source. See comments below for original
 * license and copyright notices.
 *
 ***************************************************************************/

/****************************************************************************

            THIS SOFTWARE IS NOT COPYRIGHTED

   HP offers the following for use in the public domain.  HP makes no
   warranty with regard to the software or it's performance and the
   user accepts the software "AS IS" with all faults.

   HP DISCLAIMS ANY WARRANTIES, EXPRESS OR IMPLIED, WITH REGARD
   TO THIS SOFTWARE INCLUDING BUT NOT LIMITED TO THE WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

****************************************************************************/

/****************************************************************************
 *  Header: remcom.c,v 1.34 91/03/09 12:29:49 glenne Exp $
 *
 *  Module name: remcom.c $
 *  Revision: 1.34 $
 *  Date: 91/03/09 12:29:49 $
 *  Contributor:     Lake Stevens Instrument Division$
 *
 *  Description:     low level support for gdb debugger. $
 *
 *  Considerations:  only works on target hardware $
 *
 *  Written by:      Glenn Engel $
 *  ModuleState:     Experimental $
 *
 *  NOTES:           See Below $
 *
 *  To enable debugger support, two things need to happen.  One, a
 *  call to set_debug_traps() is necessary in order to allow any breakpoints
 *  or error conditions to be properly intercepted and reported to gdb.
 *  Two, a breakpoint needs to be generated to begin communication.  This
 *  is most easily accomplished by a call to breakpoint().  Breakpoint()
 *  simulates a breakpoint by executing a trap #1.  The breakpoint instruction
 *  is hardwired to trap #1 because not to do so is a compatibility problem--
 *  there either should be a standard breakpoint instruction, or the protocol
 *  should be extended to provide some means to communicate which breakpoint
 *  instruction is in use (or have the stub insert the breakpoint).
 *
 * -----[ORIGINAL DOC - N/A TO US, ONLY FOR 68000]--------
 *  Some explanation is probably necessary to explain how exceptions are
 *  handled.  When an exception is encountered the 68000 pushes the current
 *  program counter and status register onto the supervisor stack and then
 *  transfers execution to a location specified in it's vector table.
 *  The handlers for the exception vectors are hardwired to jmp to an address
 *  given by the relation:  (exception - 256) * 6.  These are descending
 *  addresses starting from -6, -12, -18, ...  By allowing 6 bytes for
 *  each entry, a jsr, jmp, bsr, ... can be used to enter the exception
 *  handler.  Using a jsr to handle an exception has an added benefit of
 *  allowing a single handler to service several exceptions and use the
 *  return address as the key differentiation.  The vector number can be
 *  computed from the return address by [ exception = (addr + 1530) / 6 ].
 *  The sole purpose of the routine catchException is to compute the
 *  exception number and push it on the stack in place of the return address.
 *  The external function exceptionHandler() is
 *  used to attach a specific handler to a specific m68k exception.
 * -----[CUT]--------
 * 
 *  For 68010+ machines, the ability to have a return address around just
 *  so the vector can be determined is not necessary because the '010 pushes an
 *  extra word onto the stack containing the vector offset
 *
 *  Because gdb will sometimes write to the stack area to execute function
 *  calls, this program cannot rely on using the supervisor stack so it
 *  uses its own stack area reserved in the int array remcomStack.
 *
 *************
 *
 *    The following gdb commands are supported:
 *
 * command          function                               Return value
 *
 *    g             return the value of the CPU registers  hex data or ENN
 *    G             set the value of the CPU registers     OK or ENN
 *
 *    mAA..AA,LLLL  Read LLLL bytes at address AA..AA      hex data or ENN
 *    MAA..AA,LLLL: Write LLLL bytes at address AA.AA      OK or ENN
 *
 *    c             Resume at current address              SNN   ( signal NN)
 *    cAA..AA       Continue at address AA..AA             SNN
 *
 *    s             Step one instruction                   SNN
 *    sAA..AA       Step one instruction from AA..AA       SNN
 *
 *    k             kill
 *
 *    ?             What was the last sigval ?             SNN   (signal NN)
 *
 * All commands and responses are sent with a packet which includes a
 * checksum.  A packet consists of
 *
 * $<packet info>#<checksum>.
 *
 * where
 * <packet info> :: <characters representing the command or response>
 * <checksum>    :: < two hex digits computed as modulo 256 sum of <packetinfo>>
 *
 * When a packet is received, it is first acknowledged with either '+' or '-'.
 * '+' indicates a successful transfer.  '-' indicates a failed transfer.
 *
 * Example:
 *
 * Host:                  Reply:
 * $m0,10#2a               +$00010203040506070809101112131415#42
 *
 ****************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <setjmp.h>
#include <machine.h>

/************************************************************************
 *
 * external low-level support routines
 */
typedef void (*ExceptionHook)(int);                 /* pointer to function with int parm */
typedef void (*Function)(void);                     /* pointer to a function */

void putDebugChar(int);                             /* write a single character      */
int getDebugChar();                                 /* read and return a single char */
void cleanup_debugger(void);     

Function exceptionHandler(int, void (*)(void));     /* assign an exception handler */
extern ExceptionHook exceptionHook;                 /* hook variable for errors/exceptions */

void return_to_super(void);
void return_to_user(void);
void catchException(void);

/************************/
/* FORWARD DECLARATIONS */
/************************/
static void initializeRemcomErrorFrame(void);

/************************************************************************/
/* BUFMAX defines the maximum number of characters in inbound/outbound buffers*/
/* at least NUMREGBYTES*2 are needed for register packets */
#define BUFMAX 400

static char initialized; /* boolean flag. != 0 means we've been initialized */

int remote_debug;
/*  debug >  0 prints ill-formed commands in valid packets & checksum errors */

static const char hexchars[] = "0123456789abcdef";

/* there are 180 bytes of registers on a 68020 w/68881      */
/* many of the fpa registers are 12 byte (96 bit) registers */
#define NUMREGBYTES 180
enum regnames {
    d0, d1, d2, d3, d4, d5, d6, d7,
    a0, a1, a2, a3, a4, a5, a6, a7,
    PS, PC,
    FP0, FP1, FP2, FP3, FP4, FP5, FP6, FP7,
    FPCONTROL, FPSTATUS, FPIADDR
};

/* We keep a whole frame cache here.  "Why?", I hear you cry, "doesn't
   GDB handle that sort of thing?"  Well, yes, I believe the only
   reason for this cache is to save and restore floating point state
   (fsave/frestore).  A cleaner way to do this would be to make the
 fsave data part of the registers which GDB deals with like any
   other registers.  This should not be a performance problem if the
   ability to read individual registers is added to the protocol.  */

/* Comment from 30 years later: The ability to read individual registers 
    was added to the protocol like twenty-five years ago or something... */

typedef struct FrameStruct {
    struct FrameStruct *previous;
    int exceptionPC;                /* pc value when this frame created */
    int exceptionVector;            /* cpu vector causing exception     */
    short frameSize;                /* size of cpu frame in words       */
    short sr;                       /* for 68000, this not always sr    */
    int pc;
    short format;
    int fsaveHeader;
    int morejunk[];                 /* exception frame, fp save... */
    // ...
} Frame;

#define FRAMESIZE 500
int gdbFrameStack[FRAMESIZE];
Frame *lastFrame;

volatile int registers[NUMREGBYTES / 4];
volatile int superStack;

#define STACKSIZE 10000
volatile int remcomStack[STACKSIZE / sizeof(int)];
volatile int *stackPtr = &remcomStack[STACKSIZE / sizeof(int) - 1];

/*
 * In many cases, the system will want to continue exception processing
 * when a continue command is given.
 * oldExceptionHook is a function to invoke in this case.
 */

static volatile ExceptionHook oldExceptionHook;

/* the size of the exception stack on the 68010+ varies with the type of
 * exception.  The following table is the number of WORDS used for each exception format.
 *
 * TODO Currently this only has format sizes for '010 and 020!
 */
const short exceptionSize[] = {4, 4, 6, 4, 4, 4, 4, 4, 29, 10, 16, 46, 12, 4, 4, 4};

static char remcomInBuffer[BUFMAX];
static char remcomOutBuffer[BUFMAX];

jmp_buf remcomEnv;

#define BREAKPOINT()            asm("       trap #1\n\t")

#define debugf(...)                                                         \
    do {                                                                    \
        if (remote_debug) {                                                 \
            printf(__VA_ARGS__);                                            \
        }                                                                   \
    } while (0)

#define debug_error             debugf

#ifdef GDB_STUB_TRACE
#define tracef(...)                                                         \
    do {                                                                    \
        if (remote_debug) {                                                 \
            printf(__VA_ARGS__);                                            \
        }                                                                   \
    } while (0)
#else
#define tracef(...)
#endif

void returnFromException(Frame *frame) {
    /* if no passed in frame, use the last one */
    if (!frame) {
        frame = lastFrame;
        frame->frameSize = 4;
        frame->format = 0;
        frame->fsaveHeader = -1; /* restore regs, but we dont have fsave info */
    }

    /* throw away any frames in the list after this frame */
    lastFrame = frame;

    frame->sr = registers[(int)PS];
    frame->pc = registers[(int)PC];

    if (registers[(int)PS] & 0x2000) {
        /* return to supervisor mode... */
        tracef("  <- rt super: 0x%08x [0x%04x 0x%04x 0x%04x 0x%04x 0x%04x]\n", frame->pc, 
                *((uint16_t*)(frame->pc - 4)),
                *((uint16_t*)(frame->pc - 2)),
                *((uint16_t*)(frame->pc - 0)),
                *((uint16_t*)(frame->pc + 2)),
                *((uint16_t*)(frame->pc + 4))
        );
        return_to_super();
    } else { /* return to user mode */
        tracef("  <- rt user : 0x%08x [0x%04x 0x%04x 0x%04x 0x%04x 0x%04x]\n", frame->pc, 
                *((uint16_t*)(frame->pc - 4)),
                *((uint16_t*)(frame->pc - 2)),
                *((uint16_t*)(frame->pc - 0)),
                *((uint16_t*)(frame->pc + 2)),
                *((uint16_t*)(frame->pc + 4))
        );
        return_to_user();
    }
}

static int hex(char ch) {
    if ((ch >= 'a') && (ch <= 'f')) {
        return (ch - 'a' + 10);
    }

    if ((ch >= '0') && (ch <= '9')) {
        return (ch - '0');
    }

    if ((ch >= 'A') && (ch <= 'F')) {
        return (ch - 'A' + 10);
    }

    return (-1);
}

/* scan for the sequence $<data>#<checksum>     */

static unsigned char* getpacket(void) {
    unsigned char *buffer = (unsigned char*)&remcomInBuffer[0];
    unsigned char checksum;
    unsigned char xmitcsum;
    int count;
    char ch;

    while (1) {
        /* wait around for the start character, ignore all other characters */
        while ((ch = getDebugChar()) != '$')
            ;

    retry:
        checksum = 0;
        xmitcsum = -1;
        count = 0;

        /* now, read until a # or end of buffer is found */
        while (count < BUFMAX - 1) {
            ch = getDebugChar();
            if (ch == '$')
                goto retry;
            if (ch == '#')
                break;
            checksum = checksum + ch;
            buffer[count] = ch;
            count = count + 1;
        }
        buffer[count] = 0;

        if (ch == '#') {
            ch = getDebugChar();
            xmitcsum = hex(ch) << 4;
            ch = getDebugChar();
            xmitcsum += hex(ch);

            if (checksum != xmitcsum) {
                debugf("bad checksum.  My count = 0x%x, sent=0x%x. buf=%s\n",
                        checksum, xmitcsum, buffer);

                putDebugChar('-'); /* failed checksum */
            } else {
                putDebugChar('+'); /* successful transfer */

                /* if a sequence char is present, reply the sequence ID */
                if (buffer[2] == ':') {
                    putDebugChar(buffer[0]);
                    putDebugChar(buffer[1]);

                    return &buffer[3];
                }

                return &buffer[0];
            }
        }
    }
}

/* send the packet in buffer. */

static void putpacket(char *buffer) {
    unsigned char checksum;
    int count;
    char ch;

    /*  $<packet info>#<checksum>. */
    do {
        putDebugChar('$');
        checksum = 0;
        count = 0;

        while ((ch = buffer[count])) {
            putDebugChar(ch);
            checksum += ch;
            count += 1;
        }

        putDebugChar('#');
        putDebugChar(hexchars[checksum >> 4]);
        putDebugChar(hexchars[checksum % 16]);

    } while (getDebugChar() != '+');
}

/* convert the memory pointed to by mem into hex, placing result in buf */
/* return a pointer to the last char put in buf (null) */
static char* mem2hex(char *mem, char *buf, int count) {
    int i;
    unsigned char ch;
    debugf(" [m2h] ");
    for (i = 0; i < count; i++) {
        ch = *mem++;
        debugf(" 0x%02x", ch);
        *buf++ = hexchars[ch >> 4];
        *buf++ = hexchars[ch % 16];
    }
    debugf("\n");
    *buf = 0;
    return (buf);
}

/* convert the hex array pointed to by buf into binary to be placed in mem */
/* return a pointer to the character AFTER the last byte written */
static char* hex2mem(char *buf, char *mem, int count) {
    int i;
    unsigned char ch;
    debugf(" [h2m] ");
    for (i = 0; i < count; i++) {
        ch = hex(*buf++) << 4;
        ch = ch + hex(*buf++);
        debugf(" 0x%02x", ch);
        *mem++ = ch;
    }
    debugf("\n");
    return (mem);
}

/* a bus error has occurred, perform a longjmp
   to return execution and allow handling of the error */

static void handle_buserror(void) {
    longjmp(remcomEnv, 1);
}

/* this function takes the 68000 exception number and attempts to
   translate this number into a unix compatible signal value */
static int computeSignal(int exceptionVector) {
    int sigval;
    switch (exceptionVector) {
    case 2:
        sigval = 10;
        break; /* bus error           */
    case 3:
        sigval = 10;
        break; /* address error       */
    case 4:
        sigval = 4;
        break; /* illegal instruction */
    case 5:
        sigval = 8;
        break; /* zero divide         */
    case 6:
        sigval = 8;
        break; /* chk instruction     */
    case 7:
        sigval = 8;
        break; /* trapv instruction   */
    case 8:
        sigval = 11;
        break; /* privilege violation */
    case 9:
        sigval = 5;
        break; /* trace trap          */
    case 10:
        sigval = 4;
        break; /* line 1010 emulator  */
    case 11:
        sigval = 4;
        break; /* line 1111 emulator  */

        /* Coprocessor protocol violation.  Using a standard MMU or FPU
       this cannot be triggered by software.  Call it a SIGBUS.  */
    case 13:
        sigval = 10;
        break;

    case 31:
        sigval = 2;
        break; /* interrupt           */
    case 33:
        sigval = 5;
        break; /* breakpoint          */

        /* This is a trap #8 instruction.  Apparently it is someone's software
       convention for some sort of SIGFPE condition.  Whose?  How many
       people are being screwed by having this code the way it is?
       Is there a clean solution?  */
    case 40:
        sigval = 8;
        break; /* floating point err  */

        /* TODO Modern gdb uses TRAP#15 rather than TRAP#1 (which I guess it used 
           back in the 90's when this stub was written) for breakpoints when
           the Z command isn't supported (which it isn't here). This is likely 
           going to cause us problems because of the Easy68k trap, but for now
           this hack will do... 

           See BPT_VECTOR: https://sourceware.org/git/?p=binutils-gdb.git;a=blob;f=gdb/m68k-tdep.c;h=5b2a29a350e53d2a7d366dcfcd95213d57b63897;hb=HEAD
           
           We should probably just support Z ...
           */
    case 47:
        sigval = 5;
        break; /* breakpoint          */

    case 48:
        sigval = 8;
        break; /* floating point err  */
    case 49:
        sigval = 8;
        break; /* floating point err  */
    case 50:
        sigval = 8;
        break; /* zero divide         */
    case 51:
        sigval = 8;
        break; /* underflow           */
    case 52:
        sigval = 8;
        break; /* operand error       */
    case 53:
        sigval = 8;
        break; /* overflow            */
    case 54:
        sigval = 8;
        break; /* NAN                 */
    default:
        sigval = 7; /* "software generated" */
    }

    return (sigval);
}

/**********************************************/
/* WHILE WE FIND NICE HEX CHARS, BUILD AN INT */
/* RETURN NUMBER OF CHARS PROCESSED           */
/**********************************************/
static int hexToInt(char **ptr, int *intValue) {
    int numChars = 0;
    int hexValue;

    *intValue = 0;

    while (**ptr) {
        hexValue = hex(**ptr);

        if (hexValue >= 0) {
            *intValue = (*intValue << 4) | hexValue;
            numChars++;
        } else {
            break;
        }

        (*ptr)++;
    }

    return (numChars);
}

/*
 * This function does all command procesing for interfacing to gdb.
 */
void handle_exception(int exceptionVector) {
    int sigval, stepping;
    int addr, length;
    char *ptr;
    int newPC;
    Frame *frame;

    tracef("\n$$$$EX ================\n");
    debugf("vector=%d, sr=0x%x, pc=0x%x\n",
            exceptionVector, registers[PS], registers[PC]);

    /* reply to host that an exception has occurred */
    sigval = computeSignal(exceptionVector);
    remcomOutBuffer[0] = 'S';
    remcomOutBuffer[1] = hexchars[sigval >> 4];
    remcomOutBuffer[2] = hexchars[sigval % 16];
    remcomOutBuffer[3] = 0;

    putpacket(remcomOutBuffer);

    stepping = 0;

    while (1 == 1) {
        remcomOutBuffer[0] = 0;
        ptr = (char*)getpacket();
        char thec = *ptr++;
        debugf("  ===> Got Packet '%c'\n", thec);
        switch (thec) {
        case '?':
            remcomOutBuffer[0] = 'S';
            remcomOutBuffer[1] = hexchars[sigval >> 4];
            remcomOutBuffer[2] = hexchars[sigval % 16];
            remcomOutBuffer[3] = 0;
            break;
        case 'd':
            remote_debug = !(remote_debug); /* toggle debug flag */
            break;
        case 'g': /* return the value of the CPU registers */
            mem2hex((char *)registers, remcomOutBuffer, NUMREGBYTES);
            break;
        case 'G': /* set the value of the CPU registers - return OK */
            hex2mem(ptr, (char *)registers, NUMREGBYTES);
            strcpy(remcomOutBuffer, "OK");
            break;

            /* mAA..AA,LLLL  Read LLLL bytes at address AA..AA */
        case 'm':
            if (setjmp(remcomEnv) == 0) {
                tracef("remcomEnv set with setjmp\n");
                exceptionHandler(2, handle_buserror);

                /* TRY TO READ %x,%x.  IF SUCCEED, SET PTR = 0 */
                if (hexToInt(&ptr, &addr)) {
                    debugf("m!! : read from 0x%08x", addr);
                    if (*(ptr++) == ',') {
                        if (hexToInt(&ptr, &length)) {
                            ptr = 0;
                            mem2hex((char *)addr, remcomOutBuffer, length);
                        }
                    }
                }

                if (ptr) {
                    strcpy(remcomOutBuffer, "E01");
                }
            } else {
                exceptionHandler(2, catchException);
                strcpy(remcomOutBuffer, "E03");
                debug_error("bus error");
            }

            /* restore handler for bus error */
            exceptionHandler(2, catchException);
            break;

            /* MAA..AA,LLLL: Write LLLL bytes at address AA.AA return OK */
        case 'M':
            if (setjmp(remcomEnv) == 0) {
                exceptionHandler(2, handle_buserror);

                /* TRY TO READ '%x,%x:'.  IF SUCCEED, SET PTR = 0 */
                if (hexToInt(&ptr, &addr)) {
                    tracef("M!! : 0x%08x before: 0x%04x 0x%04x\n", addr, *((uint16_t*)(addr)), *((uint16_t*)(addr + 2)));
                    debugf("M!! : write to 0x%08x", addr);
                    if (*(ptr++) == ',') {
                        if (hexToInt(&ptr, &length)) {
                            if (*(ptr++) == ':') {
                                hex2mem(ptr, (char *)addr, length);
                                ptr = 0;
                                strcpy(remcomOutBuffer, "OK");
                            }
                        }
                    }
                    tracef("M!! : 0x%08x after: 0x%04x 0x%04x\n", addr, *((uint16_t*)(addr)), *((uint16_t*)(addr + 2)));
                }

                if (ptr) {
                    strcpy(remcomOutBuffer, "E02");
                }
            } else {
                exceptionHandler(2, catchException);
                strcpy(remcomOutBuffer, "E03");
                debug_error("bus error");
            }

            /* restore handler for bus error */
            exceptionHandler(2, catchException);
            break;

            /* cAA..AA    Continue at address AA..AA(optional) */
            /* sAA..AA   Step one instruction from AA..AA(optional) */
        case 's':
            tracef("s!! : next c!! is single step\n");
            stepping = 1;
        case 'c':
            /* try to read optional parameter, pc unchanged if no parm */
            if (hexToInt(&ptr, &addr)) {
                registers[PC] = addr;
                debugf("c!! : arg 0x%08x\n", addr);
            } else {
                debugf("c!! : no arg; cont at 0x%08x\n", registers[PC]);
            }

            newPC = registers[PC];
            tracef("  -> newpc: 0x%08x\n", newPC);

            /* clear the trace bit */
            registers[PS] &= 0x7fff;

            /* set the trace bit if we're stepping */
            if (stepping) {
                tracef("  -> STEPPING; set trace bit...\n");
                registers[PS] |= 0x8000;
            }


            // TODO I believe somewhere here is where we need to rerun breakpoint insns!
            //      at this point, the original instruction has been restored by the client,
            //      once we return it'll be set back to the breakpoint.
            //
            //      In this case we _should_ be hitting the `frame->exceptionPC == (newPC + 2)`
            //      case in the `while` below, but we don't because we don't seem to ever rerun 🤔
            //
            //      (obviously we wouldn't actually do the rerun here - we'd have to set things
            //       up so we returned to it, which I would think means setting up a frame...)
            //
            //      I expected the client to do this initially, but on further reflection there's
            //      probably no possible way it could, it doesn't have enough information...


            /*
             * look for newPC in the linked list of exception frames.
             * if it is found, use the old frame it.  otherwise,
             * fake up a dummy frame in returnFromException().
             */
            if (remote_debug)
                tracef("  -> new pc = 0x%x\n", newPC);
            frame = lastFrame;
            while (frame) {
                tracef("  -> frame at 0x%x has pc=0x%x, except#=%d\n",
                        (int)frame, frame->exceptionPC, frame->exceptionVector);

                if (frame->exceptionPC == newPC) {
                    tracef("  -> match (exact): newpc: 0x%08x\n", newPC);
                    break; /* bingo! a match */
                }

                /*
                 * for a breakpoint instruction, the saved pc may
                 * be off by two due to re-executing the instruction
                 * replaced by the trap instruction.  Check for this.
                 */
                if ((frame->exceptionVector == 33 || frame->exceptionVector == 47) && (frame->exceptionPC == (newPC + 2))) {
                    tracef("  -> match (near): newpc: 0x%08x\n", newPC);
                    break;
                }

                if (frame == frame->previous) {
                    tracef("  -> nomatch: newpc: 0x%08x\n", newPC);
                    frame = 0; /* no match found */
                    break;
                }
                frame = frame->previous;
            }

            /*
             * If we found a match for the PC AND we are not returning
             * as a result of a breakpoint (33 or 47),
             * trace exception (9), nmi (31), jmp to
             * the old exception handler as if this code never ran.
             */
            if (frame) {
                if ((frame->exceptionVector != 9) &&
                    (frame->exceptionVector != 31) &&
                    (frame->exceptionVector != 33) &&       // TODO do we just dump TRAP#1 now? Not just here, obvs...
                    (frame->exceptionVector != 47)) {       // TODO this last one is what breaks E68k...

                    tracef("  -> jmp old: newpc: 0x%08x\n", newPC);

                    /*
                     * invoke the previous handler.
                     */
                    if (oldExceptionHook) {
                        tracef("    -> have old exception hook: 0x%08lx\n", (uint32_t)oldExceptionHook);
                        (*oldExceptionHook)(frame->exceptionVector);
                    }

                    newPC = registers[PC]; /* pc may have changed  */
                    tracef("    -> newpc now: 0x%08x\n", newPC);

                    if (newPC != frame->exceptionPC) {
                        tracef("frame at 0x%x has pc=0x%x, except#=%d\n",
                                (int)frame, frame->exceptionPC,
                                frame->exceptionVector);

                        /* re-use the last frame, we're skipping it (longjump?) */
                        frame = (Frame *)0;
                        tracef("    -> reuse last: 0x%08lx\n", (uint32_t)frame);
                        returnFromException(frame); /* this is a jump */
                    }
                }
            }

            /* if we couldn't find a frame, create one */
            if (frame == 0) {
                frame = lastFrame - 1;
                tracef("  -> create new frame: 0x%08lx\n", (uint32_t)frame);

                /* by using a bunch of print commands with breakpoints,
               it's possible for the frame stack to creep down.  If it creeps
               too far, give up and reset it to the top.  Normal use should
               not see this happen.
                 */
                if ((unsigned int)(frame - 2) < (unsigned int)&gdbFrameStack) {
                    initializeRemcomErrorFrame();
                    frame = lastFrame;
                }
                frame->previous = lastFrame;
                lastFrame = frame;
                frame = 0; /* null so _return... will properly initialize it */
            }

            returnFromException(frame); /* this is a jump */

            break;

            /* kill the program */
        case 'k': /* do nothing */
            cleanup_debugger();
            mcEnableInterrupts(0);
            abort();
            break;
        default:
            debugf("WARN: unhandled command '%c'\n", thec);
        } /* switch */

        /* reply to the request */
        putpacket(remcomOutBuffer);
    }
}

static void initializeRemcomErrorFrame(void)
{
    lastFrame = ((Frame *)&gdbFrameStack[FRAMESIZE - 1]) - 1;
    lastFrame->previous = lastFrame;
}

/* this function is used to set up exception handlers for tracing and
   breakpoints */
void set_debug_traps()
{
    extern void debug_level7();
    extern void remcomHandler();
    int exception;

    initializeRemcomErrorFrame();
    stackPtr = &remcomStack[STACKSIZE / sizeof(int) - 1];

    for (exception = 2; exception <= 23; exception++)
        exceptionHandler(exception, catchException);

    /* level 7 interrupt              */
    exceptionHandler(31, debug_level7);

    /* 
     * static breakpoint exception (trap #1)
     * We could probably just use trap #15 for this now, but there _might_ be
     * value in knowing whether we hit a static or dynamic breakpoint I guess
     * (and it doesn't really cost much to separate them 🤷)
     */
    exceptionHandler(33, catchException);

    /* 
     * modern gdb memory breakpoint exception (trap #15)
     * The client writes a TRAP#15 (4e4f) instruction when setting them up
     */
    exceptionHandler(47, catchException);

    /* 48 to 54 are floating point coprocessor errors */
    for (exception = 48; exception <= 54; exception++) {
        exceptionHandler(exception, catchException);
    }

    if (oldExceptionHook != remcomHandler) {
        oldExceptionHook = exceptionHook;
        exceptionHook = remcomHandler;
    }

    initialized = 1;
}

/* This function will generate a breakpoint exception.  It is used at the
   beginning of a program to sync up with a debugger and can be used
   otherwise as a quick means to stop program execution and "break" into
   the debugger. */

void breakpoint()
{
    if (initialized) {
        BREAKPOINT();
    }
}

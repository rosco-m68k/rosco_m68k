/*
 *------------------------------------------------------------
 *                                  ___ ___ _   
 *  ___ ___ ___ ___ ___       _____|  _| . | |_ 
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_| 
 *                     |_____|       firmware v1                 
 * ------------------------------------------------------------
 * Copyright (c)2019 Ross Bamford
 * See top-level LICENSE.md for licence information.
 *
 * C defines, structs etc for dealing with M68k exceptions
 * ------------------------------------------------------------
 */
#ifndef _ROSCOM68K_MACHINE_EXCEPTION_H
#define _ROSCOM68K_MACHINE_EXCEPTION_H

#include <stdint.h>

/*
 * Exception frame format on the stack. Not all fields are present
 * for all exception types - the fields that are valid are determined
 * by the exception vector and format code.
 */
typedef struct {
  uint16_t sr;                      /* Status register                  */
  uint32_t pc;                      /* Program counter                  */
  uint16_t format: 4;               /* Format code                      */
  uint16_t vec_ofs: 12;             /* Vector offset                    */
  union {
    struct {
      uint16_t ssw;                 /* 68010 Special Status Word        */
      uint32_t fault_address;       /* 68010 Fault address              */
      uint16_t reserved0;
      uint16_t data_out_buffer;     /* 68010 Data output buffer         */
      uint16_t reserved1;
      uint16_t data_in_buffer;      /* 68010 Data input buffer          */
      uint16_t reserved2;
      uint16_t insn_in_buffer;      /* 68010 Instruction input buffer   */

      // |VERSION NUMBER| (?) / 16 words of internal registers may follow
    } fmt010;
    struct {
      union {
        uint32_t insn_address;      /* 68020 Instruction address        */
        struct {
          uint16_t reserved0;
          uint16_t ssw;             /* 68020 Special Status Word        */
        };
      }; 
      uint16_t pipe_stage_c;        /* 68020 Instruction pipe - Stage C */
      uint16_t pipe_state_b;        /* 68020 Instruction pipe - Stage B */
      uint32_t fault_address;       /* 68020 Fault address              */
      uint32_t reserved1;
      uint32_t data_out_buffer;     /* 68020 Data output buffer         */
      uint32_t reserved2;
      uint32_t reserved3;
      uint32_t stage_b_address;     /* 68020 Stage B address            */
      uint32_t reserved4;
      uint32_t data_in_buffer;      /* 68020 Data input buffer          */
      uint32_t reserved5;
      uint16_t reserved6;
      uint16_t version: 4;          /* 68020 frame Version number       */
      uint16_t reserved7: 12;

      // 18 words of internal registers may follow (long bus fault frame)
    } fmt020;
  };
} __attribute__((packed)) CPUExceptionFrame;

#ifndef ROSCOM68K_QUIET_INCLUDES
/* Format codes */
#define EX_FMT_FOUR_WORD       0x0     /* 0b0000: Basic four-word frame */
#define EX_FMT_TW_FOUR_WORD    0x1     /* 0b0001: Throwaway four-word frame (68020+) */
#define EX_FMT_SIX_WORD        0x2     /* 0b0010: Six-word frame (68020+) */
#define EX_FMT_010_BERR        0x8     /* 0b1000: Twenty-nine word 68010 bus error frame (68010 only) */
#define EX_FMT_COPRO_MID       0x9     /* 0b1001: Coprocessor midinstruction frame (ten word, 68020+) */
#define EX_FMT_020_BERR_SHORT  0xA     /* 0b1010: Short 68020 address/bus fault frame (sixteen word, 68020+) */
#define EX_FMT_020_BERR_LONG   0xB     /* 0b1011: Long 68020 address/bus fault frame (forty-six word, 68020+) */

/* MC68020 Special Status Word Bits */
#define EX_M020_SSW_FC_MASK    0x8000  /* Fault on Stage C */
#define EX_M020_SSW_FB_MASK    0x4000  /* Fault on Stage B */
#define EX_M020_SSW_RC_MASK    0x2000  /* Rerun flag for Stage C; 1 for re-run, 0 for don't re-run */
#define EX_M020_SSW_RB_MASK    0x1000  /* Rerun flag for Stage B; 1 for re-run, 0 for don't re-run */
#define EX_M020_SSW_DF_MASK    0x0100  /* Data Fault indicator & rerun flag - set 1 for re-run, 0 for don't re-run */
#define EX_M020_SSW_RM_MASK    0x0080  /* Read-modify-write cycle */
#define EX_M020_SSW_RW_MASK    0x0040  /* 0 for write, 1 for read */
#define EX_M020_SSW_SIZE_MASK  0x0030  /* Size code */
#define EX_M020_SSW_FCODE_MASK 0x0007  /* Function codes for data cycle */

/* MC68010 Special Status Word Bits */
#define EX_M010_SSW_RR_MASK    0x8000  /* Rerun flag - 0 for processor, 1 for software */
#define EX_M010_SSW_IF_MASK    0x2000  /* Instruction fetch to input buffer */
#define EX_M010_SSW_DF_MASK    0x1000  /* Data fetch to input buffer */
#define EX_M010_SSW_RM_MASK    0x0800  /* Read-modify-write cycle */
#define EX_M010_SSW_HB_MASK    0x0400  /* High-byte transfer */
#define EX_M010_SSW_BY_MASK    0x0200  /* 1 for byte transfer, 0 for word transfer */
#define EX_M010_SSW_RW_MASK    0x0100  /* 0 for write, 1 for read */
#define EX_M010_SSW_FCODE_MASK 0x0007  /* Function codes for faulted access */ 
#endif // ROSCOM68K_QUIET_INCLUDES

#endif // _ROSCOM68K_MACHINE_EXCEPTION_H

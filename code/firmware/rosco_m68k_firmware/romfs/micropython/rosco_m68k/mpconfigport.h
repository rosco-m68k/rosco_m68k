#include <stdint.h>

// Python internal features.
#define MP_ENDIANNESS_BIG                       (1)
// #define MICROPY_CONFIG_ROM_LEVEL                MICROPY_CONFIG_ROM_LEVEL_FULL_FEATURES
#define MICROPY_ENABLE_COMPILER                 (1)
#define MICROPY_STACKLESS                       (0)
#define MICROPY_STACKLESS_STRICT                (0)
#define MICROPY_OBJ_BASE_ALIGNMENT              __attribute__((aligned(4)))
#define MICROPY_ENABLE_GC                       (1)

#define MICROPY_HELPER_REPL                     (1)
#define MICROPY_REPL_AUTO_INDENT                (1)

// #define MICROPY_DEBUG_PRINTER                   (&mp_stderr_print)
// #define MICROPY_DEBUG_PRINTERS                  (1)
// #define MICROPY_ERROR_REPORTING                 (MICROPY_ERROR_REPORTING_DETAILED)
#define MICROPY_ERROR_REPORTING                 (MICROPY_ERROR_REPORTING_TERSE)
// #define MICROPY_ERROR_PRINTER                   (&mp_stderr_print)
#define MICROPY_LONGINT_IMPL                    (MICROPY_LONGINT_IMPL_LONG)
#define MICROPY_FLOAT_IMPL                      (MICROPY_FLOAT_IMPL_DOUBLE)
// #define MICROPY_FLOAT_IMPL                      (MICROPY_FLOAT_IMPL_FLOAT)

// Fine control over Python builtins, classes, modules, etc.
#define MICROPY_PY_ASYNC_AWAIT                  (0)
#define MICROPY_PY_BUILTINS_SET                 (0)
#define MICROPY_PY_ATTRTUPLE                    (0)
#define MICROPY_PY_COLLECTIONS                  (0)
#define MICROPY_PY_MATH                         (0)
#define MICROPY_PY_IO                           (0)
#define MICROPY_PY_STRUCT                       (0)

// #define MICROPY_PY_BUILTINS_ROUND_INT           (1)
// #define MICROPY_PY_MICROPYTHON_MEM_INFO         (1)
// #define MICROPY_PY_ALL_SPECIAL_METHODS          (1)
// #define MICROPY_PY_REVERSE_SPECIAL_METHODS      (1)
// #define MICROPY_PY_ARRAY_SLICE_ASSIGN           (1)
// #define MICROPY_PY_BUILTINS_SLICE_ATTRS         (1)

// #define MICROPY_PY_SYS_PATH_ARGV_DEFAULTS       (0)
// #define MICROPY_PY_SYS_EXIT                     (1)
// #define MICROPY_PY_SYS_ATEXIT                   (1)
#define MICROPY_PY_SYS_PLATFORM                 "rosco_m68k"

// #define MICROPY_PY_CMATH                        (1)
// #define MICROPY_PY_IO_IOBASE                    (1)
// #define MICROPY_PY_GC_COLLECT_RETVAL            (1)

// #define MICROPY_PY_OS_ERRNO                     (1)
// #define MICROPY_PY_OS_GETENV_PUTENV_UNSETENV    (0)
// #define MICROPY_PY_OS_SEP                       (1)
// #define MICROPY_PY_OS_STATVFS                   (0)
// #define MICROPY_PY_OS_SYSTEM                    (0)

// #define MICROPY_PY_ERRNO                        (1)
// #define MICROPY_PY_UCTYPES                      (1)
// #define MICROPY_PY_JSON                         (1)
// #define MICROPY_PY_RE                           (1)
// #define MICROPY_PY_HEAPQ                        (1)
// #define MICROPY_PY_HASHLIB                      (1)
// #define MICROPY_PY_RANDOM                       (1)

#define MICROPY_MAKE_POINTER_CALLABLE(p)        ((void *)((mp_uint_t)(p)))

// Not yet...
// #define MICROPY_BEGIN_ATOMIC_SECTION()          disable_interrupts()
// #define MICROPY_END_ATOMIC_SECTION(_s)          enable_interrupts(_s)

// Type definitions for the specific machine.

typedef intptr_t mp_int_t; // must be pointer size
typedef uintptr_t mp_uint_t; // must be pointer size
typedef long mp_off_t;

// We need to provide a declaration/definition of alloca().
#include <alloca.h>

// Define the port's name and hardware.
#define MICROPY_HW_BOARD_NAME "rosco_m68k"
#define MICROPY_HW_MCU_NAME "MC680x0"


#define MP_STATE_PORT MP_STATE_VM

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
 * This defines the Kernel API for user-mode code
 * (including servers).
 * ------------------------------------------------------------
 */
#include <stdint.h>

typedef struct {
  /*
   * Find a library by name.
   *
   * Name is null-terminated and limited to 16 characters - anything extra is ignored.
   *
   * Magic is matched against the magic number defined by the library with the 
   * given name. If the value does not match, NULL is returned (as this indicates
   * the caller was expecting a different library, or a different version of the
   * same library).
   *
   * Returns:
   *    NULL if no matching library is registered, or
   *    An opaque pointer to the library.
   *
   * The structure returned is library-dependent, so it is up to the caller
   * to know what they are expecting and cast accordingly. This is made (a bit) safer
   * thanks to the magic number.
   */
  void (*FindLibrary)(char *name, uint32_t magic);

  /*
   * Register a library with the kernel.
   *
   * Name is null-terminated and limited to 16 characters. Names cannot be reused!
   *
   * Magic is the magic number this library uses. This does not have to be unique,
   * but library authors should take care not to choose the same name *and* magic
   * number as some other library (unless their library is binary compatible).
   *
   * Library is the library structure that gives access to this library's functions.
   */
  void (*RegisterLibrary)(char *name, uint32_t magic, void *library);
} KernelApi;

/*
 * Top level method for obtaining the Kernel API instance.
 *
 * This is the only safe way to obtain this. 
 */
KernelApi* GetKernelApi();


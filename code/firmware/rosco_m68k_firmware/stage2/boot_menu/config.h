/*
 *------------------------------------------------------------
 *                                  ___ ___ _
 *  ___ ___ ___ ___ ___       _____|  _| . | |_
 * |  _| . |_ -|  _| . |     |     | . | . | '_|
 * |_| |___|___|___|___|_____|_|_|_|___|___|_,_|
 *                     |_____|          firmware
 * ------------------------------------------------------------
 * Copyright (c)2024 The rosco_m68k Open Source Project
 * See top-level LICENSE.md for licence information.
 *
 * Configuration for concept boot screen
 * ------------------------------------------------------------
 */

#ifndef __CONFIG_H
#define __CONFIG_H

#define VERSION     "2.50.DEV"

/*
 * General options
 */
#if 1   /** Enabled options **/
#define CENTER_ITEMS                            /* Should items in the list be centered? */
#define HIGHLIGHT_SELECTION                     /* Should the text of the selection be highlighted? */
#define ENABLE_TIMER                            /* Should the count-down timer be enabled? */
#endif

#if 0   /** Disabled options **/
#define ALWAYS_BIZCAT                           /* Always use bizcat font, even at low resolution */
#define ALWAYS_TOPAZ                            /* Always use topaz font, even at high resolution */
#define ENABLE_ANIM                             /* Should the animation system be enabled? */
#define SHOW_TEST_ANIM                          /* Should the test animation be displayed? */
#endif

/*
 * Resolution, everything else is driven off of these...
 *
 * Either 848x480, 640x480, 424x320 or 320x240 is acceptable.
 * 
 * You can pass in HRES and VRES on Make command line, if you only
 * specify HRES, then VRES will be set accordingly.
 */
#ifndef VIEW_HRES
#   define VIEW_HRES   424
#endif

#ifndef VIEW_VRES
#   if (VIEW_HRES == 640) || (VIEW_HRES == 848)
#       define VIEW_VRES   480
#   else
#       define VIEW_VRES   240
#   endif
#endif

#if (VIEW_HRES == 320) || (VIEW_HRES == 424)
#   if VIEW_VRES != 240
#       warning Invalid resolution, forcing vertical back to 240
#       undef VIEW_VRES
#       define VIEW_VRES   240
#   endif
#elif (VIEW_HRES == 640) || (VIEW_HRES == 848)
#   if VIEW_VRES != 480
#       warning Invalid resolution, forcing vertical back to 480
#       undef VIEW_VRES
#       define VIEW_VRES   480
#   endif
#else
#   error Invalid resolution, please configure in config.h
#endif

#endif

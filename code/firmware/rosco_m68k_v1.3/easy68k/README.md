# Easy68K-compatible TRAP implementations

This code optionally provides a mostly-Easy68K-compatible TRAP#15 implementation
that can be built into the firmware and called from user code.

Currently only a subset of the Easy68K tasks are implemented, mostly due
to limitations of only having Serial output (i.e. it's not possible to set
exact text colours or read characters at a given screen position using ANSI).

These functions are called by loading the task number into `D0` and setting
up other registers as documented below, and then calling `TRAP #15`.

## Functions

| Function Code | Description                                                                                                      |
|:-------------:|------------------------------------------------------------------------------------------------------------------|
| 0             | Display string at (A1), D1.W bytes long (max 255) with carriage return and line feed (CR, LF). (see task 13)     |
| 1             | Display string at (A1), D1.W bytes long (max 255) without CR, LF. (see task 14)                                  |
| 2             | Read string from keyboard and store at (A1), NULL terminated, length retuned in D1.W (max 80)                    |
| 3             | Display signed number in D1.L in decimal in smallest field. (see task 15 & 20)                                   |
| 4             | Read a number from the keyboard into D1.L.                                                                       |
| 5             | Read single character from the keyboard into D1.B.                                                               |
| 6             | Display single character in D1.B.                                                                                |
| 7             | Set D1.B to 1 if keyboard input is pending, otherwise set to 0. Use code 5 to read pending key. (**See Note 1**) |
| 8             | Return time in hundredths of a second since boot in D1.L. (**See Note 2**)                                       |
| 9             | Terminate the program. (Disables interrupts and halts the CPU)                                                   |
| 10            | **Not implemented**                                                                                              |
| 11            | Position the cursor at ROW, COL. Requires ANSI support on the receiving terminal.                                |
|               | * The high byte of D1.W holds the COL number (0-79),                                                             |  
|               | * The low byte holds the ROW number (0-31).                                                                      |
|               | 0,0 is top left 79,31 is the bottom right (depending on terminal size).                                          |
|               | Out of range coordinates are usually ignored (depends on terminal).                                              | 
|               | **Clear Screen : Set D1.W to $FF00**.                                                                            |
| 12            | Keyboard Echo.                                                                                                   |
|               | * D1.B = 0 to turn off keyboard echo.                                                                            |
|               | * D1.B = non zero to enable it (default).                                                                        |
|               | Echo is restored on 'Reset'.                                                                                     |
| 13            | Display the NULL terminated string at (A1) with CR, LF.                                                          |
| 14            | Display the NULL terminated string at (A1) without CR, LF.                                                       |
| 15            | Display the unsigned number in D1.L converted to number base (2 through 36) contained in D2.B.                   |
|               | For example, to display D1.L in base16 put 16 in D2.B                                                            |
|               | Values of D2.B outside the range 2 to 36 inclusive are ignored.                                                  |
| 16            | Adjust display properties                                                                                        |
|               | * D1.B = 0 to turn off the display of the input prompt.                                                          |
|               | * D1.B = 1 to turn on the display of the input prompt. (default)                                                 |
|               | * D1.B = 2 do not display a line feed when Enter pressed during Trap task #2 input                               |
|               | * D1.B = 3 display a line feed when Enter key pressed during Trap task #2 input (default)                        |
|               | Other values of D1 reserved for future use.                                                                      |
|               | Input prompt display is enabled by default and by 'Reset' or when a new file is loaded.                          |
| 17            | Combination of Trap codes 14 & 3.                                                                                |
|               | * Display the NULL terminated string at (A1) without CR, LF then                                                 | 
|               | * Display the decimal number in D1.L.                                                                            |
| 18            | Combination of Trap codes 14 & 4.                                                                                |
|               | * Display the NULL terminated string at (A1) without CR, LF then                                                 |
|               | * Read a number from the keyboard into D1.L.                                                                     |
| 19            | **Not implemented**                                                                                              |
| 20            | Display signed number in D1.L in decimal in field D2.B columns wide.                                             |
| 21            | **Not implemented** (Colours can be changed using ANSI escape sequences where supported)                         |
| 22            | **Not implemented**                                                                                              | 

## Notes

### Note 1 - Task 7 considered harmful

Using task #7 doesn't make a lot of sense in the current rosco_m68k environment, because our only input is
via the UART. This means that, while this task _is_ implemented, its meaning is subtly different from 
the Easy68K equivalent - in our case a true result means there is serial data waiting, not specifically 
a user keypress.

That's not the worst of it, however - **using this task may actually be harmful**, in that it will 
silently clear any errors the UART is signalling! This is because it works by reading the Buffer Full
indicator bit in the receiver status register, which has the effect of _also_ clearing the error flags
(e.g. overrun) in that same register. Normally, these would be checked during a receive, but this task
doesn't check them _at all_ and so could lead to errors being ignored / discarded.

So, if you must use this task, keep all this in mind!                        

### Note 2 - "Hundredths of a second since boot"

Easy68K defines task #8 as returning the count of "hundredths of a second since midnight", but since we 
don't have a real-time clock this just returns the system tick counter from the system data block (SDB).

Unfortunately this counter is only word-sized, and will roll over every 655.36 seconds
(or 10.92 minutes if you prefer). It also isn't updated at exactly 100HZ, so all-in-all this isn't 
really going to return "hundredths of a second since boot" unless you aren't particularly strict with
your definition of "hundredths" and the computer was started less than ~11 minutes ago.

If you do need any kind of precision timing, you'll have to design some sort of expansion that connects
to the expansion bus :) 

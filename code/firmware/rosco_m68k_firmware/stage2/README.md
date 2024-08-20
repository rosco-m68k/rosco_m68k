## Stage 2 program loader - Rules of engagement

* Stage2 is a "user-mode program" (albeit a custom-linked one) - keep it that way
    * This doesn't mean it runs in CPU user mode, just that it's linked with newlib...
* Don't use `printf` in stage 2 unless it's behind preprocessor guards
    * You'll know you've done this by accident if the size balloons!
    * Use `FW_PRINT_C` (linked from stage1) instead
    * use `print_unsigned` (also linked from stage1) for numbers
* Don't go around malloc'ing stuff. Static allocation only please!
* Be careful with moving it lower in RAM!
    * Remember, the loaded program has to fit below it...
    * (If you need to move it, you need the `STAGE2_LOAD` address in top-level `.ld`)


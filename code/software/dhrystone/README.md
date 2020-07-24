# Dhrystone Benchmark for rosco_m68k

## Building

If compiling for FW 1.01, you'll have to use a stopwatch for the timing.
Just build with:

```
make clean all
```

If you're compiling for FW 1.1+, the timing can be done automatically.
Compile like:

```
HAVE_TIMER=true make clean all
```



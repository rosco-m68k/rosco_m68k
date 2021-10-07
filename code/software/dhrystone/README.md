# Dhrystone Benchmark for rosco_m68k

## Building

Just build with:

```bash
make clean all
```

NOTE: If compiling for FW earlier than 1.1, you'll have to use a stopwatch for the timing and compile like:

```bash
HAVE_TIMER=false make clean all
```

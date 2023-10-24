# PoC ROM Kernel Test Program

This is a simple test harness for starting up the 
embedded ROM kernel.

This will **not** be retained as an example, and does
**not** demonstrate how the kernel will be used in its
final form. The main reason this is here is so we can
develop and test the kernel without having to change
up the way stage2 works - eventually, a lot of what's
here (the bootstrap stuff at least) will be done 
automatically by the ROM, before programs are executed.


## Building

```
make clean all
```


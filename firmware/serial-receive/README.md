# Serial Loader for rosco_m68k

This firmware implements a simple way to load code into the computer from startup,
enabling quicker iteration (and less dead ROM chips).

The idea with this is to do basic set up of the system (e.g. set up the MFP) and
then wait for the user to initiate a file transfer from their terminal program.

This transfer should upload (in binary) the code that is to be run (perhaps a kernel,
or some other thing).

## Protocols

Currently, two protocols are supported (for varying values of 'supported'):

* ZMODEM -  A fairly limited subset and not especially robust, but should be
  good enough to get some code uploaded.
  
* Kermit - The standard, embedded Kermit. Should be pretty robust, but may
  be a bit slow (Recommend using `robust` mode on the sender!)
  
## Code

TODO There will eventually be some documentation here on how to write and
build code that is compatible with this loader.

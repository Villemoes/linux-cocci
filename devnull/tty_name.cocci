// tty_name used to require the caller to pass in a buffer to copy the
// name to, but all users just passed the result to a printf
// function. A small patch series [1] eliminated a bunch of 64 byte
// stack buffers, the last mostly generated by this script.
//
// [1] http://thread.gmane.org/gmane.linux.kernel.input/42425
//
// Options: --no-includes --include-headers
//

virtual patch

@depends on patch@
identifier buf;
constant C;
expression tty;
@@
- char buf[C];
  <+...
- tty_name(tty, buf)
+ tty_name(tty)
  ...+>
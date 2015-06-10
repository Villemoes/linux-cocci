// strlen() in loop conditions
//
// Often, gcc is able to deduce that the strlen is constant, and hence
// only do a single call. But if s is modified in any way inside the
// loop (e.g. doing inplace tolower()), the strlen() is computed anew
// for each iteration.
//
// This is just a trivial script to help find potential targets.
//
// Options: --include-headers --no-includes
//

virtual context

@depends on context@
expression i, s;
statement S;
@@
* for (...; i < strlen(s); ...)
*   S

@depends on context@
expression i, s;
statement S;
@@
* while (i < strlen(s))
*   S

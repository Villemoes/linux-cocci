/// strstr(x, y) == x is asking whether x starts with y. But in the
/// negative case, this is more expensive than it needs to
/// be. Moreover, strstarts() (which is a simple wrapper around
/// strncmp) exists already, so it is a little clearer to use that.
///
// Depending on the nature of y, this may increase or decrease the
// size of the generated code. For very short string literals, gcc is
// likely to not even emit a strncmp call and just open-code a few
// byte-compares, which should be a win. For longer literals, we will
// end up generating a function call with one more parameter (the
// compile-time constant strlen(y)). For non-literal y, it is even
// worse, as we will end up generating an extra strlen() call.
//
// Confidence: High
// Options: --no-includes --include-headers
//

virtual patch

@r1 depends on patch@
expression x, y;
@@
- strstr(x, y) == x
+ strstarts(x, y)

@r2 depends on patch@
expression x, y;
@@
- strstr(x, y) != x
+ !strstarts(x, y)


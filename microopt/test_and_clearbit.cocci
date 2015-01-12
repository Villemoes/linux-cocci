/// This is a micro-optimization which eliminates a few instructions,
/// including a branch.  Ideally, gcc should realize
/// this, but this does not currently seem to be the case.
///
/// Simple test case:
//
// $ cat test.c
// #define F1 0x04
// int bar(const char *s, unsigned flags);
// int foo(const char *s, unsigned flags)
// {
//         if (flags & F1)
//                 flags &= ~F1;
//         return bar(s, flags);
// }
//
// $ gcc -Wall -O2 -c -o test.o test.c
// $ objdump -d test.o | tail -n6
// 0000000000000000 <foo>:
//    0:   89 f0                   mov    %esi,%eax
//    2:   83 e0 fb                and    $0xfffffffb,%eax
//    5:   40 f6 c6 04             test   $0x4,%sil
//    9:   0f 45 f0                cmovne %eax,%esi
//    c:   e9 00 00 00 00          jmpq   11 <foo+0x11>
//

/// c may not consist of a single bit. However, we still have high
/// confidence: rule1 is ok: if any of the bits in c are set, we clear
/// them all; that's the same as unconditionally clearing all the
/// bits.
///
/// rule2 is ok in the case c does consist of a single bit. It is not
/// ok when c consists of multiple bits, but it is odd (and rare)
/// mixing bitwise and arithmetic operations like this. rule3 is
/// always ok.
///
// unlikely(X) also matches X and likely(X).
//
// Confidence: High
// Options: --no-includes 

virtual patch
virtual context
virtual org
virtual report


@rule1 depends on patch@
expression e;
constant c;
@@
- if (unlikely(e & c)) {
-     e &= ~c;
- }
+ e &= ~c;

@rule2 depends on patch@
expression e;
constant c;
@@
- if (unlikely(e & c)) {
-     e -= c;
- }
+ e &= ~c;


// There are even more ways the LSB could be tested and manipulated.
@rule3 depends on patch@
expression e;
@@
- if (unlikely(
(
- e % 2
|
- e & 1
)
- )) {
(
-    e--;
|
-    --e;
|
-    e -= 1;
|
-    e &= ~1;
)
- }
+ e &= ~1;

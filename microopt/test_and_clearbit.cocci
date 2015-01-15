/// Don't test bit before clearing it
///
/// While there can be valid reasons for testing a bit for being
/// set/not set before setting/clearing it (see for example
/// 358eec18243a ("vfs: decrapify dput(), fix cache behavior under
/// normal load")), in most cases this just forces gcc to generate
/// worse code than it could. The cost is usually about three extra
/// instructions and an extra register used (mov, and, test,
/// cmov). Note that "if (x & y) { x &= ~y; }" can always be replaced
/// by simply "x &= ~y;", regardless of whether y has one or more bits
/// set (and whether or not it is a compile-time constant). The only
/// requirement is of course that y doesn't have side-effects [and
/// that there's no rule like "this location is only writable if that
/// bit is set and you can write-protect x by clearing it" in place].
//
// Simple test case:
//
// $ cat test_and.c
// #define F1 0x04
// #define F2 0x08
// int bar(unsigned flags);
// int foo(unsigned flags)
// {
//         if (flags & (F1|F2))
//                 flags &= ~(F1|F2);
//         return bar(flags);
// }
// int foo2(unsigned flags)
// {
//         flags &= ~(F1|F2);
//         return bar(flags);
// }
// $ gcc -O2 -c test_and.c
// $ objdump -d test_and.o | grep '^\s*[0-9a-f]'
// 0000000000000000 <foo>:
//    0:   89 f8                   mov    %edi,%eax
//    2:   83 e0 f3                and    $0xfffffff3,%eax
//    5:   40 f6 c7 0c             test   $0xc,%dil
//    9:   0f 45 f8                cmovne %eax,%edi
//    c:   e9 00 00 00 00          jmpq   11 <foo+0x11>
//   11:   66 66 66 66 66 66 2e    data32 data32 data32 data32 data32 nopw %cs:0x0(%rax,%rax,1)
//   18:   0f 1f 84 00 00 00 00 
//   1f:   00 
// 0000000000000020 <foo2>:
//   20:   83 e7 f3                and    $0xfffffff3,%edi
//   23:   e9 00 00 00 00          jmpq   28 <foo2+0x8>
//
//
// c may not consist of a single bit. However, we still have high
// confidence: rule1 is ok: if any of the bits in c are set, we clear
// them all; that's the same as unconditionally clearing all the
// bits.
//
// rule2 is ok in the case c does consist of a single bit. It is not
// ok when c consists of multiple bits, but it is odd (and rare)
// mixing bitwise and arithmetic operations like this. rule3 is
// always ok.
//
// Confidence: High
// Options: --no-includes 

virtual patch
virtual context
virtual org
virtual report


@rule1 depends on patch@
expression e;
expression c;
@@
- if (unlikely((e & c) != 0)) {
-     e &= ~c;
- }
+ e &= ~c;

@rule2 depends on patch@
expression e;
constant c;
@@
- if (unlikely((e & c) != 0)) {
-     e -= c;
- }
+ e &= ~c;

// There are even more ways the LSB could be tested and manipulated.
@rule3a depends on patch@
expression e;
@@
- if (unlikely((e % 2) != 0)) {
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

@rule3b depends on patch@
expression e;
@@
- if (unlikely((e & 1) != 0)) {
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

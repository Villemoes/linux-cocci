/// Don't test bit before setting it
///
/// While there can be valid reasons for testing a bit for being
/// set/not set before setting/clearing it (see for example
/// 358eec18243a ("vfs: decrapify dput(), fix cache behavior under
/// normal load")), in most cases this just forces gcc to generate
/// worse code than it could. The cost is usually about three extra
/// instructions and an extra register used (mov, or, test, cmov).
//
// In particular, if foo is a local variable, I'm pretty sure "if
// (!(foo & FLAG)) foo |= FLAG;" can always be replaced by simply "foo
// |= FLAG;" without incurring a cache penalty. The same is true if
// the surrounding code unconditionally writes to the cacheline
// containing foo.
//
// Simple test case:
//
// $ cat test_or.c
// #define F1 0x04
// int bar(unsigned flags);
// int foo(unsigned flags)
// {
//         if (!(flags & F1))
//                 flags |= F1;
//         return bar(flags);
// }
// int foo2(unsigned flags)
// {
//         flags |= F1;
//         return bar(flags);
// }
// $ gcc -O2 -c test_or.c
// $ objdump -d test_or.o | grep '^\s*[0-9a-f]'
// 0000000000000000 <foo>:
//    0:   89 f8                   mov    %edi,%eax
//    2:   83 c8 04                or     $0x4,%eax
//    5:   40 f6 c7 04             test   $0x4,%dil
//    9:   0f 44 f8                cmove  %eax,%edi
//    c:   e9 00 00 00 00          jmpq   11 <foo+0x11>
//   11:   66 66 66 66 66 66 2e    data32 data32 data32 data32 data32 nopw %cs:0x0(%rax,%rax,1)
//   18:   0f 1f 84 00 00 00 00 
//   1f:   00 
// 0000000000000020 <foo2>:
//   20:   83 cf 04                or     $0x4,%edi
//   23:   e9 00 00 00 00          jmpq   28 <foo2+0x8>
//
//
// rule1 is only ok for c consisting of a single bit. We try to catch
// the obvious false positives using python, but this only works for
// literals; it won't catch stuff hidden behind a macro. So we set
// the confidence to medium. rule2 and rule3 are always ok.
//
// Confidence: Medium
// Options: --no-includes 

virtual patch
virtual context
virtual org
virtual report


@rule1a depends on patch@
expression e;
position p;
constant c;
@@
  if (unlikely((e & c)@p == 0)) {
(
    e |= c;
|
    e += c;
)
  }

@script:python rule1b@
c << rule1a.c;
@@
try:
  x = int(c, 0)
  if ((x & (x-1)) != 0):
    cocci.include_match(False)
except:
  pass

@rule1c depends on patch@
expression rule1a.e;
position rule1a.p;
constant rule1a.c;
@@
- if (unlikely((e & c)@p == 0)) {
(
-     e |= c;
|
-     e += c;
)
- }
+ e |= c;

@rule2a depends on patch@
expression e;
constant c;
@@
- if (unlikely((e & (1 << c)) == 0)) {
(
-     e |= 1 << c;
|
-     e += 1 << c;
)
- }
+ e |= 1 << c;

@rule2b depends on patch@
expression e;
constant c;
@@
- if (unlikely((e & BIT(c)) == 0)) {
(
-     e |= BIT(c);
|
-     e += BIT(c);
)
- }
+ e |= BIT(c);

@rule2c depends on patch@
expression e;
constant c;
@@
- if (unlikely((e & BIT_ULL(c)) == 0)) {
(
-     e |= BIT_ULL(c);
|
-     e += BIT_ULL(c);
)
- }
+ e |= BIT_ULL(c);


@rule3a depends on patch@
expression e;
@@
- if (unlikely((e % 2) == 0)) {
-    e++;
- }
+ e |= 1;

@rule3b depends on patch@
expression e;
@@
- if (unlikely((e % 2) == 0)) {
-    ++e;
- }
+ e |= 1;

@rule3c depends on patch@
expression e;
@@
- if (unlikely((e % 2) == 0)) {
-    e += 1;
- }
+ e |= 1;

@rule3d depends on patch@
expression e;
@@
- if (unlikely((e % 2) == 0)) {
-    e |= 1;
- }
+ e |= 1;

@rule3e depends on patch@
expression e;
@@
- if (unlikely((e & 1) == 0)) {
-    e++;
- }
+ e |= 1;

@rule3f depends on patch@
expression e;
@@
- if (unlikely((e & 1) == 0)) {
-    ++e;
- }
+ e |= 1;

@rule3g depends on patch@
expression e;
@@
- if (unlikely((e & 1) == 0)) {
-    e += 1;
- }
+ e |= 1;

@rule3h depends on patch@
expression e;
@@
- if (unlikely((e & 1) == 0)) {
-    e |= 1;
- }
+ e |= 1;

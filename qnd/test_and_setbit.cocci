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
//         if (!(flags & F1))
//                 flags |= F1;
//         return bar(s, flags);
// }
//
// $ gcc -Wall -O2 -c -o test.o test.c
// 0000000000000000 <foo>:
//    0:   89 f0                   mov    %esi,%eax
//    2:   83 c8 04                or     $0x4,%eax
//    5:   40 f6 c6 04             test   $0x4,%sil
//    9:   0f 44 f0                cmove  %eax,%esi
//    c:   e9 00 00 00 00          jmpq   11 <foo+0x11>

/// rule1 is only ok for c consisting of a single bit. We try to catch
/// the obvious false positives using python, but this only works for
/// literals; it won't catch stuff hidden behind a macro. So we set
/// the confidence to medium. rule2 is always ok.
///
// unlikely(X) also matches X and likely(X).
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
  unlikely(!(e & c)@p)

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
- if (unlikely(!(e & c)@p)) {
(
-     e |= c;
|
-     e += c;
)
- }
+ e |= c;


// There are even more ways the LSB could be tested and manipulated.
@rule2 depends on patch@
expression e;
@@
- if (unlikely(
(
- !(e % 2)
|
- !(e & 1)
)
- )) {
(
-    e++;
|
-    ++e;
|
-    e += 1;
|
-    e |= 1;
)
- }
+ e |= 1;

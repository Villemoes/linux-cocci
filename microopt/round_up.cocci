/// These are micro-optimizations which eliminates a few
/// branches. E.g., instead of "if (foo & 1) foo++;" one can
/// unconditionally do "foo += foo & 1;", or even better foo =
/// ALIGN(foo, 2) (which expands to foo = (foo + 1) & ~1; this
/// generally saves a tmp register). Ideally, gcc should realize this,
/// but this does not currently seem to be the case.
//
// Well, as Andreas Schwab correctly pointed out when I submitted this
// as a bug report to gcc, if foo may lie in read-only memory (and is
// then somehow guaranteed to be even), this transformation is
// actually invalid. So maybe it is not completely trivial for the
// compiler to implement this; in most real cases where this occurs,
// however, I don't think this can possibly be a problem.
//
// Anyway, simple example:
//
// int foo(int x);
// int bar(int x)
// {
// 	if (x & 1)
// 		++x;
// 	return foo(x);
// }
//
// int bar2(int x)
// {
// 	x = (x + 1) & ~1;
// 	return foo(x);
// }
//
// With gcc -O2, this compiles to
//
// 0000000000000000 <bar>:
//    0:   89 f8                   mov    %edi,%eax
//    2:   83 e0 01                and    $0x1,%eax
//    5:   83 f8 01                cmp    $0x1,%eax
//    8:   83 df ff                sbb    $0xffffffff,%edi
//    b:   e9 00 00 00 00          jmpq   10 <bar2>
//
// 0000000000000010 <bar2>:
//   10:   83 c7 01                add    $0x1,%edi
//   13:   83 e7 fe                and    $0xfffffffe,%edi
//   16:   e9 00 00 00 00          jmpq   1b <bar2+0xb>
//
// In more realistic examples, one sees the same behaviour: Two more
// instructions and one extra register used (usually the original
// value of x is completely thrown away, so the x = (x + 1) & ~1 can
// be done in whatever register is convenient for subsequent
// operations on x).

//
// unlikely(X) also matches X and likely(X).
//
// Confidence: High
// Options: --no-includes --include-headers

virtual patch

@rule1 depends on patch@
expression e;
@@
- if (unlikely(e & 1)) {
-     e++;
- }
+ e = ALIGN(e, 2);

@rule2 depends on patch@
expression e;
@@
- e += e & 1;
+ e = ALIGN(e, 2);

@rule3 depends on patch@
expression e;
@@
- if (unlikely(e % 2 != 0)) {
-     e++;
- }
+ e = ALIGN(e, 2);

@rule4 depends on patch@
expression e;
@@
- if (unlikely(e & 2)) {
-     e += 2;
- }
+ e += e & 2;

@rule5 depends on patch@
expression e;
@@
- if (unlikely(e & 4)) {
-     e += 4;
- }
+ e += e & 4;

@rule6 depends on patch@
expression e;
@@
- e = ALIGN(e, 2);
- e += e & 2;
+ e = ALIGN(e, 4);

@rule7 depends on patch@
expression e;
@@
- e = ALIGN(e, 4);
- e += e & 4;
+ e = ALIGN(e, 8);


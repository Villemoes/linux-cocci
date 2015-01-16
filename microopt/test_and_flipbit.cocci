/// Don't test value of bit before flipping it
///
/// For some reason, gcc doesn't realize that "if (x & bit) x &= ~bit;
/// else x |= bit;" can simply be written "x ^= bit;". Since x is
/// written to in either case, cache dirtying or "x may be read-only"
/// are non-issues.
//
// Simple example:
//
// $ cat test_xor.c
// #define F1 0x04
// int bar(unsigned flags);
// int foo(unsigned flags)
// {
//         if (flags & F1)
//                 flags &= ~F1;
//         else
//                 flags |= F1;
//         return bar(flags);
// }
// int foo2(unsigned flags)
// {
//         flags ^= F1;
//         return bar(flags);
// }
// $ gcc -O2 -c test_xor.c
// $ objdump -d test_xor.o | grep '^\s*[0-9a-f]'
// 0000000000000000 <foo>:
//    0:   89 f8                   mov    %edi,%eax
//    2:   89 fa                   mov    %edi,%edx
//    4:   83 e0 fb                and    $0xfffffffb,%eax
//    7:   83 ca 04                or     $0x4,%edx
//    a:   83 e7 04                and    $0x4,%edi
//    d:   0f 44 c2                cmove  %edx,%eax
//   10:   89 c7                   mov    %eax,%edi
//   12:   e9 00 00 00 00          jmpq   17 <foo+0x17>
//   17:   66 0f 1f 84 00 00 00    nopw   0x0(%rax,%rax,1)
//   1e:   00 00 
// 0000000000000020 <foo2>:
//   20:   83 f7 04                xor    $0x4,%edi
//   23:   e9 00 00 00 00          jmpq   28 <foo2+0x8>
//
// To catch more cases, we use an expression for c. However, one must
// check that the expression is guaranteed to be a power of 2. (False
// positives are somewhat unlikely: One would be doing "if any of
// these bits are set, turn them all off, otherwise turn them all
// on".)
//
// Confidence: Medium
// Options: --no-includes 

virtual patch
virtual context
virtual org
virtual report


@depends on patch@
expression e;
expression c;
@@

- if (unlikely((e & c) != 0)) {
(
-     e &= ~c;
|
-     e -= c;
)
- } else {
(
-     e |= c;
|
-     e += c;
)
- }
+ e ^= c;

// There are even more ways the LSB could be tested and manipulated.
@depends on patch@
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
- else {
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
+ e ^= 1;

/// Use sign_extend API when applicable
//
//
// Some hardware provides e.g. a 14-bit 2's complement value with bit
// 13 being sign bit. To get that value into a C variable, one needs
// to sign-extend it. The kernel has an API for that, but one
// sometimes sees stuff like 'if (foo & 0x2000) foo |= 0xffffc000;',
// which is not very readable. Moreover, it is probably less efficient
// than the two simple shifts done by sign_extend{32,64}. Try to find
// places where these can be used.
//
// Because of C's promotion rules, open-coding the sign-extension as
// 'val = (val << 5) >> 5' is often wrong when val has type narrower
// than int. So also try to find such instances.
//
// Before applying the generated patches, please ensure that sign
// extension was actually the intention. Also, ensure that
// <linux/bitops.h> is explicitly included instead of relying one some
// other header pulling it in.

virtual patch
virtual context
virtual org
virtual report

// Options: --no-includes --include-headers

@r1 depends on patch@
expression e;
// For c1, we want something with only one bit set. This won't catch
// e.g. 512 or other decimals with more than one digit, but should
// catch all hexadecimal and octal literals, as well as the decimals
// 1,2,4,8.
constant c1 =~ "^(0[xX]0*[1248]0*|[1248]|0+[124]0*)[uUlL]*$";
// c2 can initally be anything (but will usually be a hex literal), we
// sanity check in Python below.
constant c2 =~ "^(0[xX])?[0-9a-fA-F]+[uUlL]*$";
position p;
@@
  if (e@p & c1) {
    e |= c2;
  }

@script:python r2@
bit << r1.c1;
highbits << r1.c2;
p << r1.p;
signidx;
extendfn;
@@
import re
import sys
// Python doesn't grok suffixes
bit = re.sub("[uUlL]*$", "", bit)
highbits = re.sub("[uUlL]*$", "", highbits)
bit = int(bit, 0)
highbits = int(highbits, 0)
// bit should have a single bit set, but just in case
if bit & (bit - 1):
    sys.stderr.write("%s:%s: odd, 0x%x is not a power of 2\n" % (p[0].file, p[0].line, bit))
    cocci.include_match(False)
signidx = bit.bit_length() - 1
// Export the appropriate index as an "identifier" to coccinelle.
coccinelle.signidx = str(signidx)
// highbits may or may not include the sign bit, but the expression
// highbits | bit | (bit - 1) should be one less than a power of 2
// (more than that, it should be 2^8-1, 2^16-1, 2^32-1 or 2^64-1), and
// highbits must not have bits in common with (bit-1).
x = highbits | bit | (bit - 1)
if (x.bit_length() not in (8, 16, 32, 64) or
    (x & (x + 1)) or
    (highbits & (bit - 1))):
    sys.stderr.write("%s:%s: bit = 0x%x, highbits = 0x%x, skipping...\n" % (p[0].file, p[0].line, bit, highbits))
    cocci.include_match(False)
coccinelle.extendfn = "sign_extend32"
if highbits & (1 << 32):
    coccinelle.extendfn = "sign_extend64"

@r3 depends on patch@
expression r1.e;
constant r1.c1, r1.c2;
position r1.p;
identifier r2.signidx;
identifier r2.extendfn;
@@
- if (e@p & c1) {
-     e |= c2;
- }
+ e = extendfn(e, signidx);

// Do the same, but this time where the sign bit is found with a simple shift expression.
@r4 depends on patch@
expression e;
constant one =~ "^(0[xX])?0*1[uUlL]*$";
constant c1 =~ "^(0[xX])?[0-9a-fA-F]+[uUlL]*$";
constant c2 =~ "^(0[xX])?[0-9a-fA-F]+[uUlL]*$";
position p;
@@
  if (e@p & (one << c1)) {
    e |= c2;
  }

@script:python r5@
shift << r4.c1;
highbits << r4.c2;
p << r4.p;
extendfn;
@@
import re
import sys

shift = re.sub("[uUlL]*$", "", shift)
highbits = re.sub("[uUlL]*$", "", highbits)
shift = int(shift, 0)
highbits = int(highbits, 0)
bit = 1 << shift

x = highbits | bit | (bit - 1)
if (x.bit_length() not in (8, 16, 32, 64) or
    (x & (x + 1)) or
    (highbits & (bit - 1))):
    sys.stderr.write("%s:%s: shift = %d, highbits = 0x%x, skipping...\n" % (p[0].file, p[0].line, shift, highbits))
    cocci.include_match(False)
coccinelle.extendfn = "sign_extend32"
if highbits & (1 << 32):
    coccinelle.extendfn = "sign_extend64"

@r6 depends on patch@
expression r4.e;
constant r4.one;
constant r4.c1;
constant r4.c2;
position r4.p;
identifier r5.extendfn;
@@
- if (e@p & (one << c1)) {
-   e |= c2;
- }
+ e = extendfn(e, c1);

// Find places where sign_extend is open-coded. If e is of type
// narrower than int, (e<<c)>>c doesn't work as intended because of
// promotion rules. So this is usually a bug. The same is true if e is
// e.g. u16 and one is trying to clear the upper 4 bits (which should
// then be written e &= 0x0fff;). Instead of trying to suggest a
// patch, just point out the place for manual inspection.
@r7 depends on !patch@
expression e;
expression c;
position p;
@@
(
* e <<=@p c;
* e >>= c;
|
* e = e <<@p c;
* e = e >> c;
)

@script:python depends on report@
p << r7.p;
@@
coccilib.report.print_report(p[0], "possible sign_extend or bit clearing bug")

@script:python depends on org@
p << r7.p;
@@
cocci.print_main("possible sign_extend or bit clearing bug", p)

@r8 depends on !patch@
expression e;
expression c;
position p;
@@
* (e << c)@p >> c

@script:python depends on report@
p << r8.p;
@@
coccilib.report.print_report(p[0], "possible sign_extend or bit clearing bug")

@script:python depends on org@
p << r8.p;
@@
cocci.print_main("possible sign_extend or bit clearing bug", p)


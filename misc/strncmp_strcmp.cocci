/// Replace strncmp with equivalent strcmp
///
/// It is generally true that strncmp(s1, s2, n) is equivalent to
/// strcmp(s1, s2) if it is known that n > min(strlen(s1),
/// strlen(s2)). A common case where this occurs is when s2 is a
/// string literal and n is sizeof(s2). In the case where the return
/// value is compared to 0, using !strcmp() makes it more obvious that
/// the strings are tested for equality, since the rather
/// similar-looking !strncmp(s1, s2, strlen(s2)) instead means "does
/// s1 start with s2". Passing one less parameter may also give a
/// small code size reduction at the call site.
//
// Confidence: Medium
// Options: --no-includes --include-headers

virtual patch
virtual context
virtual report
virtual org

// Note1: We don't restrict 'other' to be a constant (which would
// match a string literal as well as an all-uppercase macro, which
// would presumably expand to a string literal). The only other case
// where sizeof() could reasonably be used is on an array, and,
// assuming that 'other' is actually nul-terminated, sizeof(that
// array) is > strlen(other).
//
// Note2: We don't restrict to the case where the return value is
// compared to 0, since it is generally true that strncmp(e1, e2, len)
// is equivalent to strcmp(e1, e2) whenever len > min(strlen(e1),
// strlen(e2)). [Of course, strncmp may return a different
// negative/positive value than what strcmp returns, but the caller
// cannot rely on any particular non-zero values being returned].
@rule1 depends on patch@
expression e;
expression other;
@@
(
- strncmp(e, other, sizeof(other))
+ strcmp(e, other)
|
- strncmp(other, e, sizeof(other))
+ strcmp(other, e)
|
- strncasecmp(e, other, sizeof(other))
+ strcasecmp(e, other)
|
- strncasecmp(other, e, sizeof(other))
+ strcasecmp(other, e)
)

@rule2 depends on !patch@
identifier i;
expression e;
expression other;
position p;
@@
(
* strncmp@i@p(e, other, sizeof(other))
|
* strncmp@i@p(other, e, sizeof(other))
|
* strncasecmp@i@p(e, other, sizeof(other))
|
* strncasecmp@i@p(other, e, sizeof(other))
)

@script:python depends on report@
p << rule2.p;
i << rule2.i;
@@
i2 = "strcmp" if i == "strncmp" else "strcasecmp"
coccilib.report.print_report(p[0], "%s(..., \"foo\", sizeof(\"foo\")) may be replaced by %s(..., \"foo\")" % (i,i2))

@script:python depends on org@
p << rule2.p;
i << rule2.i;
@@
i2 = "strcmp" if i == "strncmp" else "strcasecmp"
cocci.print_main("%s(..., \"foo\", sizeof(\"foo\")) may be replaced by %s(..., \"foo\")" % (i,i2), p)


@rule3@
position p;
expression e;
constant s;
constant length =~ "^(0[xX])?[0-9a-fA-F]+$";
@@
(
  strncmp@p(e, s, length)
|
  strncmp@p(s, e, length)
|
  strncasecmp@p(e, s, length)
|
  strncasecmp@p(s, e, length)
)

@script:python@
s << rule3.s;
length << rule3.length;
p << rule3.p;
@@
import re
import sys

// We only handle explicit string literals (not macros). We take care
// of simple backslash escapes (\t, \n, \" etc.), but we don't handle
// octal escapes, juxtaposed literals or trigraphs. Anyway, this
// should be enough 99% of the time.
m = re.match("\"(.*)\"", s)
if not m:
    cocci.include_match(False)
else:
    ss = m.group(1)
    ss = re.sub("\\\\.", "X", ss)
    length = int(length, 0)
    if length <= len(ss):
        cocci.include_match(False)

@rule4 depends on !patch@
position rule3.p;
expression e;
constant s;
constant length;
@@
(
* strncmp@p(e, s, length)
|
* strncmp@p(s, e, length)
|
* strncasecmp@p(e, s, length)
|
* strncasecmp@p(s, e, length)
)

@script:python depends on report@
p << rule3.p;
@@
coccilib.report.print_report(p[0], "strncmp may be replaced by strcmp")

@script:python depends on org@
p << rule3.p;
@@
cocci.print_main("strncmp may be replaced by strcmp", p)

@rule5 depends on patch@
position rule3.p;
expression e;
constant s;
constant length;
@@
(
- strncmp@p(e, s, length)
+ strcmp(e, s)
|
- strncmp@p(s, e, length)
+ strcmp(s, e)
|
- strncasecmp@p(e, s, length)
+ strcasecmp(e, s)
|
- strncasecmp@p(s, e, length)
+ strcasecmp(s, e)
)

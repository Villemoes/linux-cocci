// Find silly uses of strn(case)cmp
//
// strncmp(a, "literal", 6) is silly, since it will only use the first
// six characters of "literal", so one might as well have passed
// "litera". Most likely, this is a bug due the length being
// hard-coded.
//
// Similarly, strncmp(a, "literal", 8) is silly, since this is
// equivalent to strcmp(a, "literal").
//
// In general, strncmp(a, b, n) is equivalent to strcmp(a, b) if it is
// known that n > min(strlen(a), strlen(b)). One way to know this is
// when b is a string literal and n is either some large enough
// numeric literal or sizeof(b).
//
// This semantic patch finds and reports on such cases.
//
// Confidence: Medium
// Options: --no-includes --include-headers
//

virtual report
virtual context

@script:python depends on report@
@@
report_mode = True

@script:python depends on !report@
@@
report_mode = False

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
@rule1@
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
p << rule1.p;
i << rule1.i;
@@
i2 = "strcmp" if i == "strncmp" else "strcasecmp"
coccilib.report.print_report(p[0], "%s(..., \"foo\", sizeof(\"foo\")) may be replaced by %s(..., \"foo\")" % (i,i2))


@rule2@
position p;
identifier i;
expression e;
constant s;
constant length =~ "^(0[xX])?[0-9a-fA-F]+$";
@@

(
  strncmp@i@p(e, s, length)
|
  strncmp@i@p(s, e, length)
|
  strncasecmp@i@p(e, s, length)
|
  strncasecmp@i@p(s, e, length)
)

@script:python@
s << rule2.s;
length << rule2.length;
p << rule2.p;
i << rule2.i;
@@
import re
import sys

// We only handle explicit string literals (not macros). We take care
// of simple backslash escapes (\t, \n, \" etc.), but we don't handle
// octal escapes, juxtaposed literals or trigraphs. Anyway, this
// should be enough 99% of the time.
m = re.match("\"(.*)\"", s)
if not m:
    sys.stderr.write("%s:%s: skipping %s\n" % (p[0].file, p[0].line, s))
    cocci.include_match(False)
else:
    ss = m.group(1)
    ss = re.sub("\\\\.", "X", ss)
    slen = len(ss)
    length = int(length, 0)
    i2 = "strcmp" if i == "strncmp" else "strcasecmp"
    if slen == length:
        cocci.include_match(False)
    elif report_mode and length < slen:
        coccilib.report.print_report(p[0], "silly use of %s; %s is longer than %d {%d}" % (i, s, length, slen))
    elif report_mode and length > slen:
        coccilib.report.print_report(p[0], "%s is shorter than %d; %s can be replaced by %s" % (s, length, i, i2))

@depends on context@
position rule2.p;
expression rule2.e;
constant rule2.s;
constant rule2.length;
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

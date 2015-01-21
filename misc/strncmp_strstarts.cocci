/// Replace !strncmp() idiom with strstarts()
///
/// The idiom '!strncmp(s, "literal", 7)' needlessly duplicates the
/// length of the prefix, and is slightly error prone in case the
/// string changes or the code is copy-pasted. Use strstarts() which
/// was created for this purpose.
///
//
// In this semantic patch, we look for the variants where we are
// pretty confident the transformation is ok:
//
// (1) !strncmp(a, b, strlen(b)) for any expressions a,b
// (2) !strncmp(a, "literal", sizeof("literal")-1)
// (3) !strncmp(a, "literal", 7)
// 
// The first two are rather easy to implement. The last one requires
// some care, since there are certainly cases where the integer is not
// equal to the length of the string. So we use Python to check
// whether the two actually match. Another coccinelle script
// (strncmp_bad.cocci) checks for the bad cases.
//
// We use the strncmp() == 0 variants, since Coccinelle has an
// isomorphism making this also match the !strncmp() case. However, I
// don't know how to tell it that !strncmp(a,b,c) is equivalent to
// !strncmp(b,a,c) (note that the ! is important for this to be true).
//
// While at it, we also handle strncasecmp. But note that
// strcasestarts does not exist - introducing it should be rather
// uncontroversial, though, especially if we find many cases where a
// wrong length is used.
//
// Options: --no-includes --include-headers
// Confidence: High

virtual patch

@rule1 depends on patch@
expression e1,e2;
@@
(
- strncmp(e1, e2, strlen(e2)) == 0
+ strstarts(e1, e2)
|
- strncmp(e1, e2, strlen(e1)) == 0
+ strstarts(e2, e1)
|
- strncasecmp(e1, e2, strlen(e2)) == 0
+ strcasestarts(e1, e2)
|
- strncasecmp(e1, e2, strlen(e1)) == 0
+ strcasestarts(e2, e1)
)


@rule2 depends on patch@
expression e;
constant prefix;
@@
(
- strncmp(e, prefix, sizeof(prefix) - 1) == 0
+ strstarts(e, prefix)
|
- strncmp(prefix, e, sizeof(prefix) - 1) == 0
+ strstarts(e, prefix)
|
- strncasecmp(e, prefix, sizeof(prefix) - 1) == 0
+ strcasestarts(e, prefix)
|
- strncasecmp(prefix, e, sizeof(prefix) - 1) == 0
+ strcasestarts(e, prefix)
)


@rule3 depends on patch@
position p;
expression e;
constant prefix;
constant length =~ "^(0[xX])?[0-9a-fA-F]+$";
@@
(
  strncmp@p(e, prefix, length) == 0
|
  strncmp@p(prefix, e, length) == 0
|
  strncasecmp@p(e, prefix, length) == 0
|
  strncasecmp@p(prefix, e, length) == 0
)

@script:python@
prefix << rule3.prefix;
length << rule3.length;
pos << rule3.p;
@@
import re
import sys

// We only handle explicit string literals (not macros). We take care
// of simple backslash escapes (\t, \n, \" etc.), but we don't handle
// octal escapes, juxtaposed literals or trigraphs. Anyway, this
// should be enough 99% of the time.
m = re.match("\"(.*)\"", prefix)
if not m:
#    sys.stderr.write("%s:%s: skipping %s\n" % (pos[0].file, pos[0].line, prefix))
    cocci.include_match(False)
else:
    s = m.group(1)
    s = re.sub("\\\\.", "X", s)
    if (len(s) != int(length, 0)):
#        sys.stderr.write("%s:%s: skipping %s; it is %s than %s\n" % (pos[0].file, pos[0].line, prefix, ("longer", "shorter")[len(s) < int(length)], length))
	cocci.include_match(False)

@rule4 depends on patch@
position rule3.p;
expression rule3.e;
constant rule3.prefix;
constant rule3.length;
@@
(
- strncmp@p(e, prefix, length) == 0
+ strstarts(e, prefix)
|
- strncmp@p(prefix, e, length) == 0
+ strstarts(e, prefix)
|
- strncasecmp@p(e, prefix, length) == 0
+ strcasestarts(e, prefix)
|
- strncasecmp@p(prefix, e, length) == 0
+ strcasestarts(e, prefix)
)

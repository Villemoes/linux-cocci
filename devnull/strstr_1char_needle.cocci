/// strstr() with single-character needle is equivalent to a strchr()
/// call; the latter is likely cheaper and may also give a tiny code
/// size reduction at the call site.
//
// gcc seems to be smart enough to do this transformation itself, so
// this mostly serves as an example.
//
// Confidence: High
// Options: --no-includes --include-headers

virtual patch

@strstr1 depends on patch@
position p;
expression s;
constant c;
@@
  strstr@p(s, c)

// Use python to check whether the string constant consists of a
// single character, and if so, create an "identifier" containing that
// single character as a C literal.
@script:python strstr2@
c << strstr1.c;
ch;
@@
import re
import sys

m = re.match("^\"(.|\\\\.)\"$", c)
if not m:
    cocci.include_match(False)
else:
    coccinelle.ch = "'" + m.group(1) + "'"

@strstr3 depends on patch@
position strstr1.p;
expression strstr1.s;
constant strstr1.c;
identifier strstr2.ch;
@@
- strstr@p(s, c)
+ strchr(s, ch)

/// Testing whether a string is equal, modulo case, to a literal
/// string can be done using !strcmp instead of !strcasecmp when the
/// literal doesn't contain any letters. Similarly for the
/// length-delimited case. 
//
// The return value must be compared to 0 for this to work (that is,
// we can only be interested in whether the strings are equal, not how
// they compare lexicographically).
//
// This may avoid the cache miss which strcasecmp is almost guaranteed
// to incur when it does tolower() on the first pair of characters,
// and in any case str[n]cmp should be a simpler function than its
// case-insensitive buddy. Moreover, gcc may actually optimize the
// str[n]cmp call away, especially for short strings (it can't do that
// for str[n]casecmp, since they are locale-dependent).
//
// Confidence: High
// Options: --include-headers --no-includes
//

virtual patch
virtual context
virtual report
virtual org

@rule1@
expression e;
constant c;
position p;
@@
(
  strcasecmp@p(e, c) == 0
|
  strcasecmp@p(c, e) == 0
)

@script:python rule2@
c << rule1.c;
@@
// c is a string representing all the tokens forming the literal
// argument, so may be something like '"$123"', '"Hello " "World"',
// 'FANCY_MACRO' or even '"prefix_" ## #macro_arg', all without the
// outer single quotes. We don't know what's hidden behind macros, and
// certainly cannot know how a macro argument stringifies, but in
// either case we can be pretty sure to encounter a letter in c
// (otherwise the macro or macro parameter name would match
// /^_[0-9_]*$/, which I highly doubt exists...).
import re
if re.search("[a-zA-Z]", c):
    cocci.include_match(False)


@rule3 depends on patch@
expression rule1.e;
constant rule1.c;
position rule1.p;
@@
(
- strcasecmp@p(e, c) == 0
+ strcmp(e, c) == 0
|
- strcasecmp@p(c, e) == 0
+ strcmp(e, c) == 0
)

@depends on context@
expression rule1.e;
constant rule1.c;
position rule1.p;
@@
(
* strcasecmp@p(e, c) == 0
|
* strcasecmp@p(c, e) == 0
)

@script:python depends on org@
p << rule1.p;
@@
cocci.print_main("strcasecmp may be repaced by strcmp", p)

@script:python depends on report@
p << rule1.p;
@@
coccilib.report.print_report(p[0], "strcasecmp may be repaced by strcmp")

@rule4@
expression e, len;
constant c;
position p;
@@
(
  strncasecmp@p(e, c, len) == 0
|
  strncasecmp@p(c, e, len) == 0
)

@script:python rule5@
c << rule4.c;
@@
import re
if re.search("[a-zA-Z]", c):
    cocci.include_match(False)

@rule6 depends on patch@
expression rule4.e, rule4.len;
constant rule4.c;
position rule4.p;
@@
(
- strncasecmp@p(e, c, len) == 0
+ strncmp(e, c, len) == 0
|
- strncasecmp@p(c, e, len) == 0
+ strncmp(e, c, len) == 0
)

@depends on context@
expression rule4.e, rule4.len;
constant rule4.c;
position rule4.p;
@@
(
* strncasecmp@p(e, c, len) == 0
|
* strncasecmp@p(c, e, len) == 0
)

@script:python depends on org@
p << rule4.p;
@@
cocci.print_main("strncasecmp may be repaced by strncmp", p)

@script:python depends on report@
p << rule4.p;
@@
coccilib.report.print_report(p[0], "strncasecmp may be repaced by strncmp")

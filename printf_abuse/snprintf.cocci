/// Replace snprintf() with strlcpy().
///
/// I'm not a huge fan of strlcpy, but it's quite a bit cheaper than
/// snprintf for copying a literal string. They have exactly the same
/// semantics (ignoring the different return types): Guarantee
/// nul-termination of the destination (unless given size==0) and
/// return the length of the source string, not counting the
/// terminating '\0'.

// Confidence: High
// Options: --no-includes --include-headers

virtual patch
virtual context
virtual org
virtual report

@rule1a depends on patch@
expression dst;
expression s;
expression size;
position p;
@@
  snprintf@p(dst, size, s)

// See seq_printf.cocci for why we compare p[0].current_element to
// "something_else".
@script:python rule1b@
s << rule1a.s;
p << rule1a.p;
ss;
@@
import re
coccinelle.ss = re.sub('%%', '%', s)
if p[0].current_element == "something_else":
    cocci.include_match(False)

@rule1c depends on patch@
expression rule1a.dst;
expression rule1a.s;
expression rule1a.size;
position rule1a.p;
identifier rule1b.ss;
@@
- snprintf@p(dst, size, s)
+ strlcpy(dst, ss, size)

@rule2 depends on patch@
expression dst;
expression s;
expression size;
position p;
@@
- snprintf@p(dst, size, "%s", s)
+ strlcpy(dst, s, size)

@rule3 depends on !patch@
expression dst;
expression s;
expression size;
position p;
@@
(
* snprintf@p(dst, size, "%s", s)
|
* snprintf@p(dst, size, s)
)

@script:python depends on org@
p << rule3.p;
@@
cocci.print_main("snprintf may be repaced by strlcpy", p)

@script:python depends on report@
p << rule3.p;
@@
coccilib.report.print_report(p[0], "snprintf may be repaced by strlcpy")


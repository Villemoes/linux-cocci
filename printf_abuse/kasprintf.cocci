/// Using kasprintf with a single string argument without format
/// specifiers, or a format of "%s", to duplicate a string is somewhat
/// more expensive than it needs to be (for starters, vsnprintf is
/// called twice). Use kstrdup instead. That may also save a little
/// .text since fewer arguments need to be passed.
//
// Confidence: High
// Options: --no-includes --include-headers

virtual context
virtual patch
virtual org
virtual report

@rule1a depends on patch@
expression flags;
expression s;
position p;
@@
  kasprintf@p(flags, s)

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
expression rule1a.flags;
expression rule1a.s;
position rule1a.p;
identifier rule1b.ss;
@@
- kasprintf@p(flags, s)
+ kstrdup(ss, flags)


@rule2 depends on patch@
expression flags;
expression s;
position p;
@@
- kasprintf@p(flags, "%s", s)
+ kstrdup(s, flags)


@rule3 depends on !patch@
expression flags;
expression s;
position p;
@@
(
* kasprintf@p(flags, s)
|
* kasprintf@p(flags, "%s", s)
)

@script:python depends on org@
p << rule3.p;
@@
cocci.print_main("kasprintf may be repaced by kstrdup", p)

@script:python depends on report@
p << rule3.p;
@@
coccilib.report.print_report(p[0], "kasprintf may be repaced by kstrdup")


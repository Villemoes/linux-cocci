/// Use the macro created for this purpose instead of open-coding it.
//
// This doesn't catch the case where i is some more complicated member
// selection, such as ->a.b.c[0]. I don't know how to do that.
//
// Also, it doesn't handle the case where the aggregate is a union,
// but that's just because I'm lazy and because I don't think it
// occurs that often.
//
// Confidence: High
// Options: --no-includes --include-headers

virtual patch
virtual context
virtual org
virtual report

@r1 depends on patch@
identifier T;
identifier i;
expression e;
@@
- sizeof(((struct T *)e)->i)
+ FIELD_SIZEOF(struct T, i)

@r2 depends on !patch@
identifier T;
identifier i;
expression e;
position p;
@@
* sizeof@p(((struct T *)e)->i)

@script:python depends on org@
p << r2.p;
@@
cocci.print_main("FIELD_SIZEOF can be used instead of open-coding it", p)

@script:python depends on report@
p << r2.p;
@@
coccilib.report.print_report(p[0], "FIELD_SIZEOF can be used instead of open-coding it")


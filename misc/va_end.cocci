virtual patch
virtual context
virtual org
virtual report

@r depends on !patch@
expression ap, aq, ret;
identifier last;
position p;
@@
(
* va_start@p(ap, last);
|
* va_copy@p(ap, aq);
)
  ... when != va_end(ap)
(
* return ret;
|
* return;
)

@script:python depends on org@
p << r.p;
@@
cocci.print_main("va_start or va_copy without corresponding va_end",p)

@script:python depends on report@
p << r.p;
@@
coccilib.report.print_report(p[0], "va_start or va_copy without corresponding va_end")

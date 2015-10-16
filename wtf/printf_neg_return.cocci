/// sprintf, snprintf etc. never return a negative value. Neither do
/// strlcpy. Find such bogus checks - they may hide real problems
/// (e.g., the programmer may have thought he was checking whether
/// truncation happened).
//
// Confidence: High
// Options: --no-includes --include-headers
//

virtual context
virtual report
virtual org

@r1 depends on context || report || org@
expression len, e;
identifier i;
position p;
@@
* len = \(sprintf@i\|snprintf@i\|vsprintf@i\|vsnprintf@i\|scnprintf@i\|vscnprintf@i\|strlcpy@i\)(...);
  ... when != len = e;
* \(len <@p 0 \| len <=@p 0\)

@script:python depends on report@
i << r1.i;
p << r1.p;
@@
coccilib.report.print_report(p[0], "%s never returns a negative value" % i)

@script:python depends on org@
i << r1.i;
p << r1.p;
@@
cocci.print_main("%s never returns a negative value" % i, p)

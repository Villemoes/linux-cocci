/// sprintf(dst, "...", ..., dst, ...) is a really bad idea. It may
/// work when the format string starts with "%s" and dst is passed as
/// the corresponding argument, but even that is a bit fragile to rely
/// on.
//
// This doesn't detect all cases; it would be nice to also catch cases
// where one of the arguments is dst+foo or is derived from dst in
// some other way.
//
// Confidence: High
// Options: --no-includes --include-headers
//

virtual context
virtual report
virtual org
virtual patch

@r depends on !patch@
expression dst;
position p;
@@
* \(sprintf\|snprintf\|scnprintf\)(dst, ..., dst, ...)@p

@script:python depends on org@
p << r.p;
@@
cocci.print_main("s[n]printf, overlapping source and destination buffers", p)

@script:python depends on report@
p << r.p;
@@
coccilib.report.print_report(p[0], "s[n]printf, overlapping source and destination buffers")


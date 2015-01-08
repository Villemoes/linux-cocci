/// Find bugs of the form func(..., T a[N], ... ) { ... sizeof(a) ... },
/// where the sizeof evaluates to sizeof(T*) instead of N*sizeof(T).
//
// Other array-decay induced bugs could also be checked for.

virtual context
virtual org
virtual report

@r@
position p;
identifier func, param;
constant C;
type T;
@@

func(..., T param[C], ...)
{
...
(
* sizeof@p(param)
|
* ARRAY_SIZE@p(param)
)
...
}


@script:python depends on org@
p << r.p;
param << r.param;
@@
cocci.print_main("sizeof applied to 'array' parameter %s" % param, p2)

@script:python depends on report@
p << r.p;
param << r.param;
@@

coccilib.report.print_report(p[0], "sizeof applied to 'array' parameter %s" % param)

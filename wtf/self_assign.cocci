// Many of these are done to shut up gcc. But we also find a number of
// code smells, such as a struct copying with a rather obvious
// copy-pasto, e.g.
//
// x->a = y->a;
// x->b = y->b;
// x->c = x->c;
//
// I'd like to to eliminate some false positives by checking for
// volatiles, where the self-assignment may actually serve a purpose,
// but I'm not sure how to do that. But we can eliminate those where
// x=x is just used to silence a 'may be used uninitialized' warning,
// by simply ignoring self-assignments where both sides are simply an
// identifier (which would usually be a local variable).

virtual patch
virtual context
virtual org
virtual report

// Options: --no-includes --include-headers

@r1 depends on !patch@
expression E;
position p;
identifier i;
@@
(
  i = i
|
* E =@p E
|
* E |=@p E
|
* E &=@p E
)

@script:python depends on org@
p << r1.p;
@@
cocci.print_main("no-op self-assignment", p)

@script:python depends on report@
p << r1.p;
@@
coccilib.report.print_report(p[0], "no-op self-assignment")


@r2 depends on !patch@
expression E;
position p;
identifier i;
@@
(
* \( memcpy@i \| memmove@i \| memcmp@i \) (E, E, ...)@p
|
* \( strcmp@i \| strcasecmp@i \| strcpy@i \| strcat@i \) (E, E)@p
|
* \( strncmp@i \| strncasecmp@i \| strncpy@i \| strncat@i \) (E, E, ...)@p
|
* \( strlcpy@i \| strlcat@i \) (E, E, ...)@p
)

@script:python depends on report@
p << r2.p;
i << r2.i;
@@
coccilib.report.print_report(p[0], "odd use of '%s' with two identical arguments" % i)

@script:python depends on org@
p << r2.p;
i << r2.i;
@@
cocci.print_main("odd use of '%s' with two identical arguments" % i, p)


@r3 depends on !patch@
expression E;
position p;
identifier i;
@@
(
* \( min@i \| max@i \| min_not_zero@i \) (E, E)@p
|
* \( min_t@i \| max_t@i \) (..., E, E)@p
|
* swap@i(E, E)@p
)
@script:python depends on report@
p << r3.p;
i << r3.i;
@@
coccilib.report.print_report(p[0], "odd use of '%s' with two identical arguments" % i)

@script:python depends on org@
p << r3.p;
i << r3.i;
@@
cocci.print_main("odd use of '%s' with two identical arguments" % i, p)


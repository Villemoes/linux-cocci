// a < b < c does not mean what it does in Python and mathematics. It
// must be spelled a < b && b < c.
//
// Also check for certain other expressions whose value is guaranteed
// to be 0 or 1 being used as operands of inequalities. It may not be
// wrong, but it's certainly confusing, and could probably be written
// in a different way.
//
// Options: --no-includes --include-headers

virtual context
virtual org
virtual report

// Apparently, the builtin isomorphisms are sufficient for this to
// also match the a >= b > c cases, at least in the simple cases I
// tested.
@rule1@
expression E1, E2, E3;
position p;
@@
(
* (E1@p < E2) < E3
|
* E1@p < (E2 < E3)
|
* (E1@p <= E2) < E3
|
* E1@p <= (E2 < E3)
|
* (E1@p <= E2) <= E3
|
* E1@p <= (E2 <= E3)
|
* (E1@p < E2) <= E3
|
* E1@p < (E2 <= E3)
)

@script:python depends on org@
p << rule1.p;
@@
cocci.print_main("Comparison operator abuse; probably needs a &&", p)

@script:python depends on report@
p << rule1.p;
@@
coccilib.report.print_report(p[0], "Comparison operator abuse; probably needs a &&")

@rule2a@
expression E1, E2;
expression E;
@@
(
  E1 ==@E E2
|
  E1 !=@E E2
|
  E1 &&@E E2
|
  E1 ||@E E2
|
  !@E E1
)

@rule2b@
expression E3;
expression rule2a.E;
position pp;
@@
(
* (E) <@pp E3
|
* (E) >@pp E3
|
* (E) <=@pp E3
|
* (E) >=@pp E3
|
* (E) ==@pp E3
|
* (E) !=@pp E3
)

@script:python depends on org@
pp << rule2b.pp;
@@
cocci.print_main("Using a boolean result as an operand of an (in)equality is confusing", pp)

@script:python depends on report@
pp << rule2b.pp;
@@
coccilib.report.print_report(pp[0], "Using a boolean result as an operand of an (in)equality is confusing")


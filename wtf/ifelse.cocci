/// Simplify conditionals with identical if- and else-branches
//
// if (e) S; else S; is, unless e has side-effects, equivalent to just
// S. Either something is wrong in the code or one can save a number
// of lines. Manual inspection is needed to decide which.
//
// Similar remarks apply to the case of "x ? y : y".
//
// Confidence: High
// Options: --no-includes --include-headers
//

virtual context
virtual patch
virtual report
virtual org


// If there's three or more branches, as in "if (A) S; else if (B) S;
// else if (C) S; else S;", this will only catch the "if (C) S; else
// S;" part. As always, manual inspection is required. But iteratively
// applying this semantic patch should actually DTRT.
@r2 depends on patch@
expression e;
statement S;
@@
- if (e) {
-   S
- } else {
-   S
- }
+ S


@r3 depends on !patch@
expression e;
statement S;
position p1, p2;
@@
* if@p1 (e) {
*   S
* } else@p2 {
*   S
* }

// Assuming x does not have side effects. Otherwise, one could replace
// by a comma expression (x, y), but that's just plain ugly.
@r4 depends on patch@
expression x, y;
@@
- x ? y : y
+ y

@r5 depends on !patch@
expression x, y;
position p;
@@
* x@p ? y : y

@script:python depends on report@
p1 << r3.p1;
@@
coccilib.report.print_report(p1[0], "if-branch identical to else-branch")

@script:python depends on org@
p1 << r3.p1;
@@
cocci.print_main("if-branch identical to else-branch", p1)

@script:python depends on report@
p << r5.p;
@@
coccilib.report.print_report(p[0], "second and third operand of ternary ?: identical")

@script:python depends on org@
p << r5.p;
@@
cocci.print_main("second and third operand of ternary ?: identical", p)


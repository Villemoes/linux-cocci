/// gcc happily compiles a loop such as
///
/// for (i = 0; i < 1000000000; ++i);
///
/// into just 'i = 1000000000' (which is then often eliminated as a
/// dead store). So this is not a reliable way to introduce a small
/// delay.
//
// Confidence: High
// Options: --include-headers --no-includes
//
// Note that the patch mode is mostly a mockup. Also note that gcc
// does not eliminate the loop if the variable is declared volatile
// (so that may one way to fix the code).

virtual patch
virtual context
virtual report

@depends on patch@
expression i;
constant C;
@@
- for (...; \( i < C \| i <= C \); \(++i \| i++ \| i += 1\));
+ i = C;

@r2 depends on !patch@
expression i;
constant C;
position p;
@@
(
* for@p (...; \( i < C \| i <= C \); \(++i \| i++ \| i += 1\));
|
* for@p (...; \( i++ < C \| i++ <= C \| ++i < C \| ++i <= C \); ... );
|
* while@p (\( i++ < C \| i++ <= C \| ++i < C \| ++i <= C \));
|
* for@p (...; \( i-- \| --i \); ... );
|
* while@p (\( i-- \| --i \));
)

@script:python depends on report@
p << r2.p;
@@
coccilib.report.print_report(p[0], "no-op delay loop")

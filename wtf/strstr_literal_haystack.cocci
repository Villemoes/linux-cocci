// strstr() is not symmetric in its two arguments. It is rather
// unusual to use a string literal as the first, haystack, argument -
// one is much more likely to want to ask "is this literal a substring
// of this user input" than "is this user input a substring of this
// particular literal". So find such instances.
//
// Options: --include-headers --no-includes
//

virtual context
virtual report
virtual org

@r@
position p;
constant c;
expression e;
@@
* strstr@p(c, e)

@script:python depends on org@
p << r.p;
@@
cocci.print_main("strstr() with literal haystack", p)

@script:python depends on report@
p << r.p;
@@
coccilib.report.print_report(p[0], "strstr() with literal haystack")

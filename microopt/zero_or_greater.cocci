/// Simplify "!a || b >= a"
//
// When a and b have unsigned type [1], the test "!a || b >= a" is
// equivalent to just the latter, "b >= a" (since if a is 0, clearly b
// >= a). Unfortunately, gcc doesn't seem to realize this, and so
// issues both a test and a cmp instruction on x86_64. So search for
// such instances, suggesting a replacement.
//
// The 'unsigned' part is really important, so we only have low confidence.
//
// [1] Due to promotion rules, it is sufficient that a has unsigned
// type, sizeof(a) >= sizeof(b) and sizeof(a) >= sizeof(int).
//
// Confidence: Low
// Options: --include-headers --no-includes
//

virtual patch

@r1 depends on patch@
expression a, b;
@@
- !a || (b >= a)
+ b >= a

@r2 depends on patch@
expression a, b;
@@
- (a == 0) || (b >= a)
+ b >= a

/// This is a micro-optimization which eliminates a few instructions,
/// including a branch.  Ideally, gcc should realize
/// this, but this does not currently seem to be the case.
///
/// The confidence is only medium, since the first transformation
/// requires that c is a power-of-two to be valid.
///
// unlikely(X) also matches X and likely(X).
//
// Confidence: Medium
// Options: --no-includes 

virtual patch
virtual context
virtual org
virtual report


@depends on patch@
expression e;
constant c;
@@

- if (unlikely(e & c)) {
(
-     e &= ~c;
|
-     e -= c;
)
- }
- else {
(
-     e |= c;
|
-     e += c;
)
- }
+ e ^= c;

// There are even more ways the LSB could be tested and manipulated.
@depends on patch@
expression e;
@@
- if (unlikely(
(
- e % 2
|
- e & 1
)
- )) {
(
-    e--;
|
-    --e;
|
-    e -= 1;
|
-    e &= ~1;
)
- }
- else {
(
-    e++;
|
-    ++e;
|
-    e += 1;
|
-    e |= 1;
)
- }
+ e ^= 1;

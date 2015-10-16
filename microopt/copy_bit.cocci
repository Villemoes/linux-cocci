/// Code such as
///
///   if (foo & FLAG)
///       bar |= FLAG;
/// 
/// can, in most cases, be replaced by
///
///   bar |= foo & FLAG;
//
// One case where it's not ok is of course when FLAG doesn't consist
// of a single bit. But that's not why gcc doesn't perform this
// transformation: The problem is that it is invalid if bar is not
// writable; one could imagine a situation where bar is only writable
// in the case where foo does contain FLAG.
//
// However, nobody writes code that way, so it should be pretty safe
// to just do the transformation in the source (but do check the
// 'single bit' condition before blindly applying patches generated
// by this). If a series of replacements is done, as in
//
//   if (foo & F1)
//     bar |= F1;
//   if (foo & F2)
//     bar |= F2;
//
// then gcc is smart enough to actually transform
//
//   bar |= foo & F1;
//   bar |= foo & F2;
//
// into
//
//   bar |= (foo & (F1 | F2));
//
// Confidence: Medium
// Options: --include-headers --no-includes
//

virtual patch

@rule1a depends on patch@
expression src, dst;
constant c;
@@
  if (unlikely(src & c)) {
    dst |= c;
  }

@script:python rule1b@
c << rule1a.c;
@@
try:
  x = int(c, 0)
  if ((x & (x-1)) != 0):
    cocci.include_match(False)
except:
  pass

@rule1c depends on patch@
expression rule1a.src, rule1a.dst;
constant rule1a.c;
@@
- if (unlikely(src & c)) {
-   dst |= c;
- }
+ dst |= src & c;

@rule2a depends on patch@
expression src, dst;
constant c;
@@
- if (unlikely((src & (1 << c)) != 0)) {
-   dst |= 1 << c;
- }
+ dst |= src & (1 << c);

@rule2b depends on patch@
expression src, dst;
constant c;
@@
- if (unlikely((src & BIT(c)) != 0)) {
-   dst |= BIT(c);
- }
+ dst |= src & BIT(c);

@rule2c depends on patch@
expression src, dst;
constant c;
@@
- if (unlikely((src & BIT_ULL(c)) != 0)) {
-   dst |= BIT_ULL(c);
- }
+ dst |= src & BIT_ULL(c);

// A rare variant is where we want to clear a bit in dst if it is
// clear in src. This is somewhat uglier to do with pure bitops, but
// it's doable. We don't bother testing whether c is a literal
// non-power-of-2, since that would be extraordinarily odd. When
// manually checking the generated patches, remember to also take
// types (and signedness) into account; something which is easy to
// screw up with bitops transformations.
@rule3a depends on patch@
expression src, dst;
constant c;
@@
- if (unlikely(!(src & c))) {
-   dst &= ~c;
- }
+ dst &= src | ~c;

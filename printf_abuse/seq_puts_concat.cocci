/// Merge consecutive puts calls
///
/// Consecutive calls of seq_puts with literal strings, where the
/// return value is not checked, might as well be replaced by a single
/// call with the combined string. This gives smaller generated code
/// (less function calls), a slight .rodata reduction, since nul and
/// padding bytes are eliminated, and hits fewer cache lines (nothing
/// guarantees that the linker places string literals which are used
/// together close together in the final image).
//
// Two small, but in practice irrelevant, issues:
//
// (1) If one of the strings is also used elsewhere, this reduces the
// possiblity for the linker to do string merging (thus increasing
// .rodata), but these multiple seq_puts calls are mostly to print
// multi-line headers in various /proc or /sys files.
//
// (2) seq_puts is all-or-nothing, so if there is not room for the
// entire string, one would previously get some of the strings
// printed, but not all; combining the strings means nothing is
// printed. So this formally changes the semantics of the
// code. However, usually there is room. Moreover, the point of the
// seq_* interface is that if we overflow, a larger buffer is
// allocated and the printing is done again.
//
// The easiest way to use this script is to apply it once to find the
// first two of a sequence of calls, then manually inspect the
// location and merge potential third, fourth etc. calls. One can also
// run and apply repeatedly until no furter patches are generated, but
// one will in any case need to fix the whitespace, and that's easier
// if it is not too messed up.
//
// Confidence: High
// Options: --no-includes --include-headers


virtual patch
virtual context
virtual org
virtual report

// Prevent "token already tagged" error
@r@
position p;
@@
  seq_puts(...);
  seq_puts(...);
  seq_puts@p(...);


@concat1 depends on patch@
expression s;
constant c1, c2;
position p1 != r.p, p2 != r.p;
@@
  seq_puts@p1(s, c1);
  seq_puts@p2(s, c2);

@script:python concat2@
c1 << concat1.c1;
c2 << concat1.c2;
c3;
@@

// The indentation probably needs to be fixed manually
coccinelle.c3 = c1 + "\n\t" + c2

@concat3 depends on patch@
identifier concat2.c3;
expression concat1.s;
constant concat1.c1, concat1.c2;
position concat1.p1, concat1.p2;
@@
- seq_puts@p1(s, c1);
- seq_puts@p2(s, c2);
+ seq_puts(s, c3);


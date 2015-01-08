/// Using seq_puts to write a one-character string is suboptimal,
/// since puts has to call strlen(). Replacing those instances with
/// putc avoids that call (and thus a memory reference), and also
/// tends to give a tiny code size reduction at the call site.
///
//
// Confidence: High
// Options: --no-includes --include-headers
//
// Since the changes to any given line should consist of changing an s
// to a c and two " to ', the generated patches should be easy to
// proofread.

virtual patch
virtual context
virtual org
virtual report

@putc1 depends on patch@
position p;
expression s;
constant c;
@@
  \(trace_seq_puts@p\|seq_puts@p\)(s, c)

// Use python to check whether the string constant consists of a
// single character, and if so, create an "identifier" containing that
// single character as a C literal.
@script:python putc2@
s << putc1.s;
c << putc1.c;
ch;
@@
import re
import sys

m = re.match("^\"(.|\\\\.)\"$", c)
if not m:
    cocci.include_match(False)
else:
    coccinelle.ch = "'" + m.group(1) + "'"

@putc3 depends on patch@
position putc1.p;
expression putc1.s;
constant putc1.c;
identifier putc2.ch;
@@
(
- seq_puts@p
+ seq_putc
|
- trace_seq_puts@p
+ trace_seq_putc
)
- (s, c)
+ (s, ch)

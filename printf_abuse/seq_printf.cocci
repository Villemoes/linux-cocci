/// Using {trace_,}seq_printf to print a simple string is a lot more
/// expensive than it needs to be, since seq_puts exists [1]. This
/// semantic patch purposely also matches non-literals, since in that
/// case it is also safer to use puts.
///
/// We also handle the cases where the format string is exactly "%s"
/// or "%c" and replace with puts/putc.
///
/// [1] printf must push all the, in this case non-existent, varargs
/// into a va_arg structure on the stack, then vprintf takes over and
/// calls vsnprintf, ...
///
/// Work is being done towards making all seq_* and trace_seq_*
/// functions return void, so I'm not careful with replacing a
/// function by one with a different return value.
///
//
// Confidence: High
// Options: --no-includes --include-headers
//

virtual patch
virtual context
virtual org
virtual report

// See comment on puts("\n") --> putc('\n') below.
@rule0 depends on patch@
symbol seq_puts;
symbol trace_seq_puts;
@@
(
- seq_puts
+ __seq_puts__HACK
|
- trace_seq_puts
+ __trace_seq_puts__HACK
)

// printf(x) --> puts(x)
@rule1a depends on patch@
expression s;
expression t;
position p;
@@
  \(seq_printf@p \| trace_seq_printf@p\)(s, t)
  
// In order to DTRT when the format string contains %%, we need to
// process it with python. If t is actually an expression and not just
// a string literal, it is very unlikely to contain two adjacent %
// characters. But note that this does not handle the case where t is
// either a macro or a const char* which happens to point to a string
// containing two %%. git grep 'define.*%%' shows that macros
// containing %% are usually used in inline asm, so we're probably ok.
//
// If we're outside a function, we've likely hit a macro wrapper doing
// something like
//
// #define foo(a, fmt...) seq_printf(a, fmt)
//
// In that case, fmt will actually be replaced by the format string
// and all varargs, so it is a false positive.
//
// Of course, the macro may be defined inside a function, but that's
// rather rare.
//
// I think checking current_element for being the sentinel string
// "something_else" is the best way of detecting whether we're outside
// a function.

@script:python rule1b@
t << rule1a.t;
p << rule1a.p;
tt;
@@
import re
coccinelle.tt = re.sub('%%', '%', t)
if p[0].current_element == "something_else":
    cocci.include_match(False)

@rule1c depends on rule1a@
expression rule1a.s;
expression rule1a.t;
position rule1a.p;
identifier rule1b.tt;
@@
(
- seq_printf@p
+ seq_puts
|
- trace_seq_printf@p
+ trace_seq_puts
)
- (s, t)
+ (s, tt)

// printf("%s", x) --> puts(x)
@rule2 depends on patch@
expression s;
expression t;
@@
(
- seq_printf
+ seq_puts
|
- trace_seq_printf
+ trace_seq_puts
)
- (s, "%s", t)
+ (s, t)


// printf("%c", x) --> putc(x)
@rule3 depends on patch@
expression s;
expression t;
@@
(
- seq_printf
+ seq_putc
|
- trace_seq_printf
+ trace_seq_putc
)
- (s, "%c", t)
+ (s, t)


// puts(".") --> putc("."), for any single-character string.
//
// This is also done in a separate file, seq_putsc.cocci. Using that
// by itself generates easy-to-review patches (simply changing 's' to
// 'c' and two double quotes to single quotes). However, one may want
// to replace seq_printf(s, "\n") directly by seq_puts(s, '\n')
// instead of splitting that into two patches. On the other hand, this
// file should mostly be about replacing printf with simpler calls, so
// we don't want to handle existing puts("\n") here. That's why we had
// a rule0 finding preexisting puts calls for us.
//
// I'd like to handle it by simply noting the position in rule0 and
// then using a != rule0.p restriction here. But this gives a
// "semantic error: position cannot be inherited over
// modifications". So instead, we let rule0 rename existing puts
// calls, and then rename back at the end.
@putc1 depends on patch@
expression s;
constant c;
position p;
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


@fix_hack depends on patch@
symbol __seq_puts__HACK;
symbol __trace_seq_puts__HACK;
@@
(
- __seq_puts__HACK
+ seq_puts
|
- __trace_seq_puts__HACK
+ trace_seq_puts
)

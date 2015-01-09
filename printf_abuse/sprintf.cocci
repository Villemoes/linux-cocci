/// 'sprintf(dst, "foo");' can be replaced by 'strcpy(dst, "foo");'
/// similarly for strcpy(dst, "%s", whatever).
///
/// Ideally, neither sprintf or strcpy should ever be used; the size
/// of the destination buffer should be known and passed to the
/// callee. But precisely because both functions should raise the same
/// red flag for anyone reading the code, it should be ok to do this
/// optimization.
///
/// When the return value is used, we need to be more careful. I'm not
/// a huge fan of strlcpy, but (apart from the type) its return value
/// is precisely what sprintf would also return, namely the length of
/// the printed string, not counting '\0'. Use INT_MAX as a bogus size
/// value (that is also what sprintf ends up passing to vsnprintf
/// anyway). For now, I only do this replacement in the "%s"
/// case. Partly to avoid having to do the %% -> % conversion, partly
/// because changing one call of a function with three arguments to
/// another (note that both INT_MAX and "%s" are compile/link-time
/// constants) shouldn't increase the generated code at the call site
/// [calling a non-variadic function may be cheaper, though, e.g. on
/// x86_64]. In terms of visibility, these INT_MAX should make it
/// obvious that the size is bogus, but for the benefit of people just
/// grepping for sprintf, leave a comment.
//
// Confidence: High
// Options: --no-includes --include-headers

virtual context
virtual patch
virtual org
virtual report

@rule1a depends on patch@
expression dst;
expression s;
position p;
@@
  sprintf@p(dst, s);

// See seq_printf.cocci for why we compare p[0].current_element to
// "something_else".
@script:python rule1b@
s << rule1a.s;
p << rule1a.p;
ss;
@@
import re
coccinelle.ss = re.sub('%%', '%', s)
if p[0].current_element == "something_else":
    cocci.include_match(False)

@rule1c depends on patch@
expression rule1a.dst;
expression rule1a.s;
position rule1a.p;
identifier rule1b.ss;
@@
- sprintf@p(dst, s);
+ strcpy(dst, ss);

@rule2 depends on patch@
expression dst;
expression s;
position p;
@@
- sprintf@p(dst, "%s", s);
+ strcpy(dst, s);

@rule3 depends on patch@
expression dst;
expression s;
position p;
@@
- sprintf@p(dst, "%s", s)
+ strlcpy(dst, s, INT_MAX) /* used to be sprintf(), which uses INT_MAX internally anyway */


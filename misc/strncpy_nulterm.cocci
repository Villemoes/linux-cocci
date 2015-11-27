/// Replace strncpy with strlcpy
///
/// Doing
///
///   strncpy(dst, src, sizeof(dst));
///   dst[sizeof(dst)-1] = '\0';
///
/// can usually be replaced by
///
///   strlcpy(dst, src, sizeof(dst));
///
/// They are not exactly equivalent, but one is very rarely interested
/// in the 'fill the rest of the buffer, if any, with 0' "feature" of
/// strncpy. In fact, that's usually just an annoying waste of cycles.
///
// In the patches below, we use ... for the original length
// argument. Sometimes that argument is sizeof(dst)-1 for whatever
// cargo-culted reason. But, as always, you should check that the
// patches make sense before submitting.

// Confidence: Medium
// Options: --include-headers --no-includes
//

virtual patch
virtual context
virtual report
virtual org

@r1 depends on patch@
expression dst, src;
@@
- strncpy(dst, src, ...);
- dst[sizeof(dst)-1] = 0;
+ strlcpy(dst, src, sizeof(dst));

// The same, but maybe the array was declared as buf[SOME_MACRO] and
// SOME_MACRO is used instead of sizeof().
@r2 depends on patch@
expression dst, src;
constant C;
@@
- strncpy(dst, src, ...);
- dst[C - 1] = 0;
+ strlcpy(dst, src, C);

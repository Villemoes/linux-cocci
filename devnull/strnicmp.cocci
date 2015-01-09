/// Do strnicmp -> strncasecmp conversion.
//
// Used once; now strnicmp is gone from the kernel.
//
// Confidence: High
// Options: --no-includes --include-headers

virtual patch

@r depends on patch@
expression e1, e2, e3;
@@
- strnicmp
+ strncasecmp
  (e1, e2, e3)

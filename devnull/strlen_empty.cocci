// Calling strlen() just to check if a string is empty is rather
// expensive. Except that it turns out that gcc is actually smart
// enough to change strlen(s)==0 into !*s.
//
// Confidence: High
// Options: --no-includes --include-headers

virtual patch

@r0 depends on patch@
expression s;
@@
- strlen(s) == 0
+ s[0] == '\0'

@r1 depends on patch@
expression s;
statement S;
@@

- if (strlen(s))
-     S
+ if (s[0] != '\0')
+     S

@r2 depends on patch@
expression s, E;
@@

- E && strlen(s)
+ E && s[0] != '\0'

@r3 depends on patch@
expression s, E;
@@

- strlen(s) && E
+ s[0] != '\0' && E

@r4 depends on patch@
expression s, E;
@@

- E || strlen(s)
+ E || s[0] != '\0'

@r5 depends on patch@
expression s, E;
@@

- strlen(s) || E
+ s[0] != '\0' || E

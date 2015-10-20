// sprintf, snprintf etc. never return a negative value. Neither do
// strlcpy or the copy_*_user family. Find such bogus checks - they
// may hide real problems (e.g., the programmer may have thought he
// was checking whether truncation happened).
//
// Some of these have an unsigned return type, but that can easily
// have been assigned to a signed variable, which is then tested.
//
// We also search for the "<= 0" case: Even though some of these
// functions may return 0, checking for that would be better written
// '== 0'.
//
// Confidence: High
// Options: --no-includes --include-headers
//

virtual context
virtual report
virtual org

@r1 depends on context || report || org@
expression len, e;
identifier i = {sprintf, snprintf, vsprintf, vsnprintf, scnprintf, vscnprintf,
         strlcpy, sscanf, vsscanf,
	 copy_from_user, copy_to_user,
	 _copy_from_user, _copy_to_user,
	 __copy_from_user, __copy_to_user,
	 __copy_from_user_inatomic,  __copy_to_user_inatomic,
	 clear_user, __clear_user, copy_in_user,
	 strlen_user, strnlen_user};
position p;
@@
* len = i(...);
  ... when != len = e;
* \(len <@p 0 \| len <=@p 0\)

@script:python depends on report@
i << r1.i;
p << r1.p;
@@
coccilib.report.print_report(p[0], "%s never returns a negative value" % i)

@script:python depends on org@
i << r1.i;
p << r1.p;
@@
cocci.print_main("%s never returns a negative value" % i, p)

@r2 depends on context || report || org@
identifier i = {sprintf, snprintf, vsprintf, vsnprintf, scnprintf, vscnprintf,
         strlcpy, sscanf, vsscanf,
	 copy_from_user, copy_to_user,
	 _copy_from_user, _copy_to_user,
	 __copy_from_user, __copy_to_user,
	 __copy_from_user_inatomic,  __copy_to_user_inatomic,
	 clear_user, __clear_user, copy_in_user,
	 strlen_user, strnlen_user};
position p;
@@
* \( i(...) <@p 0 \| i(...) <=@p 0 \)

@script:python depends on report@
i << r2.i;
p << r2.p;
@@
coccilib.report.print_report(p[0], "%s never returns a negative value" % i)

@script:python depends on org@
i << r2.i;
p << r2.p;
@@
cocci.print_main("%s never returns a negative value" % i, p)

virtual report
virtual context
virtual org

@r@
expression e;
position p;
@@
* va_start@p(e, ...)

@script:python depends on report@
p << r.p;
@@
print p[0].current_element

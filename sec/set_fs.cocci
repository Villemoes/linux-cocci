virtual context
virtual patch
virtual org
virtual report

@r depends on !patch@
expression old, ret, new;
@@
* old = get_fs();
  ...
* set_fs(new);
  ... when != set_fs(old);
(
* return ret;
|
* return;
)

@r2 depends on !patch@
expression ret, new;
identifier old;
type T;
@@
* T old = get_fs();
  ...
* set_fs(new);
  ... when != set_fs(old);
(
* return ret;
|
* return;
)

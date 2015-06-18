// Find instances where the library sort function is called with NULL
// for the swap function parameter, making sort use generic_swap.
//
// Used to gauge the impact of adding and usiing a swap64 function,
// when size==8 and swap==NULL.
//
// Options: --no-includes --include-headers

virtual context

@depends on context@
expression arr, count, size, cmp;
@@
* sort(arr, count, size, cmp, NULL)

// For finding the few instances where the swap argument is actually
// non-NULL.
//
// @depends on context@
// expression arr, count, size, cmp;
// expression swap != NULL;
// @@
// * sort(arr, count, size, cmp, swap)

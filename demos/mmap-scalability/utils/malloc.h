#ifndef __UTILS__MALLOC_H
#define __UTILS__MALLOC_H

#include <stdlib.h>

typedef struct {
    double (*function)(size_t length);
    char *name;
} test_malloc_t;

test_malloc_t find_malloc_t(test_malloc_t functions[], int n, const char* name);

void malloc_bench_harness(test_malloc_t func, int n, int length);
double malloc_init(size_t length);
double malloc_no_init(size_t length);
double malloc_init_no_free(size_t length);
double malloc_no_init_no_free(size_t length);

#endif
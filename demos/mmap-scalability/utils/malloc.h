#ifndef __UTILS__MALLOC_H
#define __UTILS__MALLOC_H

#include <stdlib.h>

typedef struct {
    void (*function)(int n, size_t length);
    char *name;
} test_malloc_t;

test_malloc_t find_malloc_t(test_malloc_t functions[], int n, const char* name);

double malloc_init_step(size_t length);
void malloc_init_bench(int n, size_t length);
double malloc_no_init_step(size_t length);
void malloc_no_init_bench(int n, size_t length);
double malloc_init_no_free_step(size_t length);
void malloc_init_no_free_bench(int n, size_t length);
double malloc_no_init_no_free_step(size_t length);
void malloc_no_init_no_free_bench(int n, size_t length);

#endif
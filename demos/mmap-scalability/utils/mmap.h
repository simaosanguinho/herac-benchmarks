#ifndef __UTILS__MMAP_H
#define __UTILS__MMAP_H

#include <stdlib.h>
#include <sys/types.h>

typedef struct {
    void (*function)(int n, size_t length, int prot, int flags, int fd, off_t offset);
    char *name;
} test_mmap_t;

test_mmap_t find_mmap_t(test_mmap_t functions[], int n, const char* name);

double mmap_init_step(size_t length, int prot, int flags, int fd, off_t offset);
void mmap_init_bench(int n, size_t length, int prot, int flags, int fd, off_t offset);
double mmap_no_init_step(size_t length, int prot, int flags, int fd, off_t offset);
void mmap_no_init_bench(int n, size_t length, int prot, int flags, int fd, off_t offset);
double mmap_init_no_unmap_step(size_t length, int prot, int flags, int fd, off_t offset);
void mmap_init_no_unmap_bench(int n, size_t length, int prot, int flags, int fd, off_t offset);
double mmap_no_init_no_unmap_step(size_t length, int prot, int flags, int fd, off_t offset);
void mmap_no_init_no_unmap_bench(int n, size_t length, int prot, int flags, int fd, off_t offset);

#endif

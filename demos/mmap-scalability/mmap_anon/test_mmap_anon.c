#include <stddef.h>
#define _GNU_SOURCE

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#define BILLION  1000000000L;

const size_t ALLOC_SIZE = 1024 * 1024;

double nanos(struct timespec start, struct timespec stop)
{
    return (stop.tv_sec - start.tv_sec) + (double)(stop.tv_nsec - start.tv_nsec) / BILLION; 
}

double mmap_init_step(size_t length, int prot, int flags, int fd, off_t offset) 
{
    struct timespec start, stop;
    
    assert(clock_gettime(CLOCK_MONOTONIC, &start) != -1);
        void *mem = mmap(NULL, length, prot, flags, fd, offset);
        assert(mem != MAP_FAILED);
        for(size_t i = 0; i < length; i++) {
            ((char *)mem)[i] = 0;
        }
    assert(clock_gettime(CLOCK_MONOTONIC, &stop) != -1);
    munmap(mem, length);

    return nanos(start, stop);
}

void mmap_init_bench(int n, size_t length, int prot, int flags, int fd, off_t offset) 
{
    double accum = 0;

    for (int i = 0; i < n; i++) {
        double t = mmap_init_step(length, prot, flags, fd, offset); 
        printf("%.9lf\n", t);
        accum += t; 
    }

    double avg = accum / n;
    printf("avg: %.9lf\n", avg);
}

double mmap_no_init_step(size_t length, int prot, int flags, int fd, off_t offset) 
{
    struct timespec start, stop;
    
    assert(clock_gettime(CLOCK_MONOTONIC, &start) != -1);
        void *mem = mmap(NULL, length, prot, flags, fd, offset);
        assert(mem != MAP_FAILED);
    assert(clock_gettime(CLOCK_MONOTONIC, &stop) != -1);
    munmap(mem, length);

    return nanos(start, stop);
}

void mmap_no_init_bench(int n, size_t length, int prot, int flags, int fd, off_t offset) 
{
    double accum = 0;

    for (int i = 0; i < n; i++) {
        double t = mmap_no_init_step(length, prot, flags, fd, offset); 
        printf("%.9lf\n", t);
        accum += t; 
    }

    double avg = accum / n;
    printf("avg: %.9lf\n", avg);
}

double mmap_init_no_unmap_step(size_t length, int prot, int flags, int fd, off_t offset) 
{
    struct timespec start, stop;
    
    assert(clock_gettime(CLOCK_MONOTONIC, &start) != -1);
        void *mem = mmap(NULL, length, prot, flags, fd, offset);
        assert(mem != MAP_FAILED);
        for(size_t i = 0; i < length; i++) {
            ((char *)mem)[i] = 0;
        }
    assert(clock_gettime(CLOCK_MONOTONIC, &stop) != -1);

    return nanos(start, stop);
}

void mmap_init_no_unmap_bench(int n, size_t length, int prot, int flags, int fd, off_t offset) 
{
    double accum = 0;

    for (int i = 0; i < n; i++) {
        double t = mmap_init_no_unmap_step(length, prot, flags, fd, offset); 
        printf("%.9lf\n", t);
        accum += t; 
    }

    double avg = accum / n;
    printf("avg: %.9lf\n", avg);
}

double mmap_no_init_no_unmap_step(size_t length, int prot, int flags, int fd, off_t offset) 
{
    struct timespec start, stop;
    
    assert(clock_gettime(CLOCK_MONOTONIC, &start) != -1);
        void *mem = mmap(NULL, length, prot, flags, fd, offset);
        assert(mem != MAP_FAILED);
    assert(clock_gettime(CLOCK_MONOTONIC, &stop) != -1);

    return nanos(start, stop);
}

void mmap_no_init_no_unmap_bench(int n, size_t length, int prot, int flags, int fd, off_t offset) 
{
    double accum = 0;

    for (int i = 0; i < n; i++) {
        double t = mmap_no_init_no_unmap_step(length, prot, flags, fd, offset); 
        printf("%.9lf\n", t);
        accum += t;
    }

    double avg = accum / n;
    printf("avg: %.9lf\n", avg);
}


typedef struct {
    void (*function)(int n, size_t length, int prot, int flags, int fd, off_t offset);
    char *name;
} test_function_t;


int main(int argc, char** argv) 
{
    if (argc < 3) {
        perror("expected test_case_name and iter_count");
        exit(EXIT_FAILURE);
    }

    test_function_t test_functions[] = {
        { mmap_no_init_bench, "mmap_no_init_bench" },
        { mmap_init_bench, "mmap_init_bench" },
        { mmap_no_init_no_unmap_bench, "mmap_no_init_no_unmap_bench" },
        { mmap_init_no_unmap_bench, "mmap_init_no_unmap_bench" },
    };

    const char *test_name = argv[1];
    test_function_t test = { NULL, "unknown" };
    for (size_t i = 0; i < sizeof(test_functions) / sizeof(test_functions[0]); i++) {
        if (strcmp(test_functions[i].name, test_name) == 0) {
            test = test_functions[i];
        }
    }
    assert(test.function != NULL);

    int n = atoi(argv[2]);
    int size = ALLOC_SIZE;  
    if (argc > 3) {
        size = atoi(argv[3]);
    }

    printf("config: %s , n=%d , size=%d\n", test_name, n, size);
    
    test.function(n, size, PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_PRIVATE, -1, 0);

    return 0;
}

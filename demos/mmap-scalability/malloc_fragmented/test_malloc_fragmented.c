#include "../utils/utils.h"
#include "../utils/malloc.h"
#include <stdlib.h>
#include <sys/sysinfo.h>

const int CHUNK_SIZE = 10*1024*1024;

void write_chunk(void* addr, size_t size) 
{
    for (size_t i = 0; i < size; i += 16) {
        *((char *)(addr + i)) = (char)i;
    }
}

void alloc_chunks(void *chunks[], int n)
{
    srand(time(NULL));

    unsigned long alloc_size = 0;
    for (int i = 0; i < n; i++) {
        chunks[i] = malloc(CHUNK_SIZE);
        assert_that(chunks[i] != NULL, "map chunk failed");
        write_chunk(chunks[i], CHUNK_SIZE);
        alloc_size += CHUNK_SIZE;
    }

    UTIL_LOGF("allocated %d chunks, size %ld", n, alloc_size);
}

void make_fragments(void *chunks[], int n, int fragment_count)
{
    int step = n / fragment_count;
    for (int i = 0; i < fragment_count; i += step) {
        free(chunks[i]);
        chunks[i] = NULL;
    }
}

void free_chunks(void *chunks[], int n)
{
    for (int i = 0; i < n; i++) {
        if (chunks[i] != NULL) {
            free(chunks[i]);
        }
    }
    free(chunks);
}

int main(int argc, char** argv) 
{
    assert_that(argc >= 3, "expected test_case_name and iter_count");

    test_malloc_t test_functions[] = {
        { malloc_no_init, "malloc_no_init" },
        { malloc_init, "malloc_init" },
        { malloc_no_init_no_free, "malloc_no_init_no_free" },
        { malloc_init_no_free, "malloc_init_no_free" },
    };

    test_malloc_t test = find_malloc_t(test_functions, sizeof(test_functions) / sizeof(test_functions[0]), argv[1]);

    int n = atoi(argv[2]);
    int size = ALLOC_SIZE;  
    if (argc > 3) {
        size = atoi(argv[3]);
    }

    struct sysinfo info;
    sysinfo(&info);

    int chunk_count = info.freeram / CHUNK_SIZE;
    void *chunks = malloc(chunk_count * sizeof(void*));
    assert_that(chunks != NULL, "map failed");
    
    alloc_chunks(chunks, chunk_count);
    make_fragments(chunks, chunk_count, n);

    UTIL_LOGF("config: %s , n=%d , size=%d", test.name, n, size);
    malloc_bench_harness(test, n, size);

    free_chunks(chunks, chunk_count);

    return 0;
}

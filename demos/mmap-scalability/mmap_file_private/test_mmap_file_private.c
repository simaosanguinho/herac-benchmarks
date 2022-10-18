#include <sys/mman.h>

#include "../utils/utils.h"
#include "../utils/mmap.h"

int main(int argc, char** argv) 
{
    assert_that(argc >= 3, "expected test_case_name and iter_count");

    test_mmap_t test_functions[] = {
        { mmap_no_init_bench, "mmap_no_init_bench" },
        { mmap_init_bench, "mmap_init_bench" },
        { mmap_no_init_no_unmap_bench, "mmap_no_init_no_unmap_bench" },
        { mmap_init_no_unmap_bench, "mmap_init_no_unmap_bench" },
    };

    test_mmap_t test = find_mmap_t(test_functions, sizeof(test_functions) / sizeof(test_functions[0]), argv[1]);

    int n = atoi(argv[2]);
    int size = ALLOC_SIZE;
    if (argc > 3) {
        size = atoi(argv[3]);
    }

    UTIL_LOGF("config: %s , n=%d , size=%d", test.name, n, size);
    
    int fd = create_temp_file("/tmp/bench_test_mmap_file.bin", ALLOC_SIZE);
    test.function(n, size, PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_PRIVATE, fd, 0);

    return 0;
}

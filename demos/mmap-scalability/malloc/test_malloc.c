#include "../utils/utils.h"
#include "../utils/malloc.h"

int main(int argc, char** argv) 
{
    assert_that(argc >= 3, "expected test_case_name and iter_count");

    test_malloc_t test_functions[] = {
        { malloc_no_init_bench, "malloc_no_init_bench" },
        { malloc_init_bench, "malloc_init_bench" },
        { malloc_no_init_no_free_bench, "malloc_no_init_no_free_bench" },
        { malloc_init_no_free_bench, "malloc_init_no_free_bench" },
    };

    test_malloc_t test = find_malloc_t(test_functions, sizeof(test_functions) / sizeof(test_functions[0]), argv[1]);

    int n = atoi(argv[2]);
    int size = ALLOC_SIZE;  
    if (argc > 3) {
        size = atoi(argv[3]);
    }

    UTIL_LOGF("config: %s , n=%d , size=%d", test.name, n, size);
    test.function(n, size);

    return 0;
}

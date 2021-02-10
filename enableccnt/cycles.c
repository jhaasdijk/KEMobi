#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

static inline uint64_t counter_read(void)
{
    uint64_t counter = 0;
    asm volatile("MRS %0, PMCCNTR_EL0" : "=r"(counter));
    return counter;
}

int main()
{
    uint64_t t0 = counter_read();
    uint64_t t1 = counter_read();
    printf("%" PRIu64 "\n", t1 - t0);
}
#include <stdio.h>
#include <stdint.h>

void convolution(uint32_t *A, uint32_t *B);
void polyPrint(uint32_t *A);
void polyMult(uint32_t *A, uint32_t *B, uint32_t *P);
void polyRedterm(uint32_t *P);
void polyRedcoef(uint32_t *P);

int main(void);
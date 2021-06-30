#include "speed_main.h"

unsigned char entropy_input[48];
unsigned char seed[1][48];

int main()
{
    int idx, ret_val;
    unsigned char *ct = 0, *ss = 0, *ss1 = 0, *pk = 0, *sk = 0;

    for (idx = 0; idx < 48; idx++)
    {
        entropy_input[idx] = idx;
    }

    randombytes_init(entropy_input, NULL, 256);

    for (idx = 0; idx < 1; idx++)
    {
        randombytes(seed[idx], 48);
    }

    if (!ct)
        ct = malloc(crypto_kem_CIPHERTEXTBYTES);
    if (!ct)
        abort();
    if (!ss)
        ss = malloc(crypto_kem_BYTES);
    if (!ss)
        abort();
    if (!ss1)
        ss1 = malloc(crypto_kem_BYTES);
    if (!ss1)
        abort();
    if (!pk)
        pk = malloc(crypto_kem_PUBLICKEYBYTES);
    if (!pk)
        abort();
    if (!sk)
        sk = malloc(crypto_kem_SECRETKEYBYTES);
    if (!sk)
        abort();

    randombytes_init(seed[idx], NULL, 256);

    /* Verify the correctness of the KEM */

    if ((ret_val = crypto_kem_keypair(pk, sk)) != 0)
    {
        return KAT_CRYPTO_FAILURE;
    }

    if ((ret_val = crypto_kem_enc(ct, ss, pk)) != 0)
    {
        return KAT_CRYPTO_FAILURE;
    }

    if ((ret_val = crypto_kem_dec(ss1, ct, sk)) != 0)
    {
        return KAT_CRYPTO_FAILURE;
    }

    if (memcmp(ss, ss1, crypto_kem_BYTES))
    {
        return KAT_CRYPTO_FAILURE;
    }

    /* Perform benchmarking on the individual components */

    uint64_t t0[NTESTS];
    for (size_t j = 0; j < NTESTS; j++)
    {
        t0[j] = counter_read();
        crypto_kem_keypair(pk, sk);
    }
    benchmark(t0, "crypto_kem_keypair");

    for (size_t j = 0; j < NTESTS; j++)
    {
        t0[j] = counter_read();
        crypto_kem_enc(ct, ss, pk);
    }
    benchmark(t0, "crypto_kem_enc(ct, ss, pk)");

    for (size_t j = 0; j < NTESTS; j++)
    {
        t0[j] = counter_read();
        crypto_kem_dec(ss1, ct, sk);
    }
    benchmark(t0, "crypto_kem_dec(ss1, ct, sk)");

    return KAT_SUCCESS;
}

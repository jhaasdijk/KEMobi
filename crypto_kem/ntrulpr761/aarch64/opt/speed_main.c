#include "speed_main.h"
#include "speed_kem.h"

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
    printf("|------------------------------------------|--------------------|\n");

    /* Benchmarking crypto_kem_keypair */

#define Inputs_bytes (I / 8)
#define Seeds_bytes 32
#define PublicKeys_bytes (Seeds_bytes + Rounded_bytes)

    Fq aG[p], A[p], G[p];
    small a[p];

    unsigned int i;

    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        crypto_kem_keypair(pk, sk);
    }
    benchmark(t0, "crypto_kem_keypair(pk, sk)");
    printf("|------------------------------------------|--------------------|\n");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Seeds_random(pk);
    }
    benchmark(t0, "Seeds_random()");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Generator(G, pk);
    }
    benchmark(t0, "Generator()");

    // ---
    printf("\n");
    // ---

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Short_random(a);
    }
    benchmark(t0, "Short_random()");
    // --------------------------------------------------
    uint32 L[p];
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Short_fromlist(a,L);
    }
    benchmark(t0, "Short_fromlist()");

    // ---
    printf("\n");
    // ---

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Rq_mult_small(aG, G, a);
    }
    benchmark(t0, "Rq_mult_small()");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Round(A, aG);
    }
    benchmark(t0, "Round()");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Rounded_encode(pk, A);
    }
    benchmark(t0, "Rounded_encode()");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Small_encode(sk, a);
    }
    benchmark(t0, "Small_encode()");

    /*----------------------------------------*/

    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        randombytes(sk, Inputs_bytes);
    }
    benchmark(t0, "randombytes()");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Hash_prefix(sk, 4, pk, PublicKeys_bytes);
    }
    benchmark(t0, "Hash_prefix()");

    printf("|------------------------------------------|--------------------|\n");
    unsigned char c[4*p];
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        randombytes(c,4*p);
    }
    benchmark(t0, "randombytes(c,4*p);");
    printf("|------------------------------------------|--------------------|\n");

    /* Benchmarking crypto_kem_enc */

    printf("|------------------------------------------|--------------------|\n");

#define Hash_bytes 32

    Inputs r;
    unsigned char r_enc[Inputs_bytes];
    unsigned char cache[Hash_bytes];

    Fq B[p];
    // Fq bG[p];
    // Fq bA[p];
    // small b[p];
    int8 T[I];

    for (size_t j = 0; j < NTESTS; j++)
    {
        t0[j] = counter_read();
        crypto_kem_enc(ct, ss, pk);
    }
    benchmark(t0, "crypto_kem_enc(ct, ss, pk)");
    printf("|------------------------------------------|--------------------|\n");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Hash_prefix(cache, 4, pk, PublicKeys_bytes);
    }
    benchmark(t0, "Hash_prefix()");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Inputs_random(r);
    }
    benchmark(t0, "Inputs_random()");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Hide(ct, r_enc, r, pk, cache);
    }
    benchmark(t0, "Hide()");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        HashSession(ss, 1, r_enc, ct);
    }
    benchmark(t0, "HashSession()");

    // // Hide
    // Inputs_encode(r_enc,r);
    //     // ZEncrypt
    //     Rounded_decode(A,pk+Seeds_bytes);
    //         // XEncrypt
    //         Generator(G,pk);
    //         HashShort(b,r);
    //             // Encrypt
    //             Rq_mult_small(bG,G,b);
    //             Round(B,bG);
    //             Rq_mult_small(bA,A,b);
    //     Rounded_encode(ct,B);
    //     Top_encode(ct,T);
    // HashConfirm(ct,r_enc,pk,cache);

    /* Benchmarking crypto_kem_dec */

    printf("|------------------------------------------|--------------------|\n");

    #define Confirm_bytes 32
    #define Top_bytes (I / 2)
    #define Rounded_bytes 1007
    #define Small_bytes ((p + 3) / 4)
    #define SecretKeys_bytes Small_bytes
    #define Ciphertexts_bytes (Rounded_bytes + Top_bytes)
    const unsigned char *pub = sk + SecretKeys_bytes;
    const unsigned char *rho = pk + PublicKeys_bytes;
    const unsigned char *ca = rho + Inputs_bytes;
    unsigned char cnew[Ciphertexts_bytes + Confirm_bytes];

    for (size_t j = 0; j < NTESTS; j++)
    {
        t0[j] = counter_read();
        crypto_kem_dec(ss1, ct, sk);
    }
    benchmark(t0, "crypto_kem_dec(ss1, ct, sk)");
    printf("|------------------------------------------|--------------------|\n");
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Small_decode(a,sk);
    }
    benchmark(t0, "Small_decode()");
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Rounded_decode(B,ct);
    }
    benchmark(t0, "Rounded_decode()");
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Top_decode(T,ct+Rounded_bytes);
    }
    benchmark(t0, "Top_decode()");
    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Decrypt(r, B, T, a);
    }
    benchmark(t0, "Decrypt()");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Hide(cnew, r_enc, r, pub, ca);
    }
    benchmark(t0, "Hide()");

    // --------------------------------------------------
    int mask = Ciphertexts_diff_mask(ct,cnew);
    for (i = 0;i < Inputs_bytes;++i) r_enc[i] ^= mask&(r_enc[i]^rho[i]);
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        HashSession(ss1,1+mask,r_enc,ct);
    }
    benchmark(t0, "HashSession()");

    printf("|------------------------------------------|--------------------|\n");

    /* Benchmarking Hide() */

    printf("|- Hide() ---------------------------------|--------------------|\n");

    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Inputs_encode(r_enc,r);
    }
    benchmark(t0, "Inputs_encode()");
    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Rounded_decode(B,ct);
    }
    benchmark(t0, "Rounded_decode()");
    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Generator(G, pk);
    }
    benchmark(t0, "Generator()");
    /*----------------------------------------*/
    small b[p];
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        HashShort(b,r);
    }
    benchmark(t0, "HashShort()");



    /*----------------------------------------*/
    unsigned char s[Inputs_bytes];
    unsigned char hh[Hash_bytes];

    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Inputs_encode(s,r);
    }
    benchmark(t0, "Inputs_encode()");
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Hash_prefix(hh,5,s,sizeof s);
    }
    benchmark(t0, "Hash_prefix()");
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Expand(L,hh);
    }
    benchmark(t0, "Expand()");
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Short_fromlist(b,L);
    }
    benchmark(t0, "Short_fromlist()");







    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Rq_mult_small(aG, G, a);
    }
    benchmark(t0, "Rq_mult_small()");
    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Round(A, aG);
    }
    benchmark(t0, "Round()");
    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Rq_mult_small(aG, G, a);
    }
    benchmark(t0, "Rq_mult_small()");
    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Rounded_encode(pk, A);
    }
    benchmark(t0, "Rounded_encode()");
    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        Top_encode(ct,T);
    }
    benchmark(t0, "Top_encode()");
    /*----------------------------------------*/
    for (i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        HashConfirm(ct,r_enc,pk,cache);
    }
    benchmark(t0, "HashConfirm()");

    return KAT_SUCCESS;
}

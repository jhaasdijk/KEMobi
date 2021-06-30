#ifndef KEM_H
#define KEM_H

#ifdef KAT
#include <stdio.h>
#endif

#include <stdlib.h> /* for abort() in case of OpenSSL failures */
#include "params.h"

#include "randombytes.h"
#include "crypto_hash_sha512.h"
#ifdef LPR
#include "crypto_stream_aes256ctr.h"
#endif

#include "int8.h"
#include "int16.h"
#include "int32.h"
#include "uint16.h"
#include "uint32.h"
#include "crypto_sort_uint32.h"
#include "Encode.h"
#include "Decode.h"

typedef int16_t Fq;
typedef int8_t small;
typedef int8 Inputs[I];

/* Provide function declarations */

void Seeds_random(unsigned char *s);
void Generator(Fq *G, const unsigned char *k);
void Short_random(small *out);
void Rq_mult_small(Fq *h, const Fq *f, const small *g);
void Round(Fq *out, const Fq *a);
void Rounded_encode(unsigned char *s, const Fq *r);
void Small_encode(unsigned char *s, const small *f);
void Hash_prefix(unsigned char *out, int b, const unsigned char *in, int inlen);

void Inputs_random(Inputs r);

void Inputs_encode(unsigned char *s, const Inputs r);
void Short_fromlist(small *out, const uint32 *in);
void Rounded_decode(Fq *r, const unsigned char *s);
void Top_encode(unsigned char *s, const int8 *T);
void Top_decode(int8 *T, const unsigned char *s);
void HashConfirm(unsigned char *h, const unsigned char *r, const unsigned char *pk, const unsigned char *cache);
void HashSession(unsigned char *k, int b, const unsigned char *y, const unsigned char *z);

void Hide(unsigned char *c, unsigned char *r_enc, const Inputs r, const unsigned char *pk, const unsigned char *cache);
void Decrypt(int8 *r, const Fq *B, const int8 *T, const small *a);

#endif

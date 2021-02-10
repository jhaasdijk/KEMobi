#ifndef crypto_kem_ntrulpr953_H
#define crypto_kem_ntrulpr953_H

#define crypto_kem_ntrulpr953_ref_SECRETKEYBYTES 1652
#define crypto_kem_ntrulpr953_ref_PUBLICKEYBYTES 1349
#define crypto_kem_ntrulpr953_ref_CIPHERTEXTBYTES 1477
#define crypto_kem_ntrulpr953_ref_BYTES 32
 
#ifdef __cplusplus
extern "C" {
#endif
extern int crypto_kem_ntrulpr953_ref_keypair(unsigned char *,unsigned char *);
extern int crypto_kem_ntrulpr953_ref_enc(unsigned char *,unsigned char *,const unsigned char *);
extern int crypto_kem_ntrulpr953_ref_dec(unsigned char *,const unsigned char *,const unsigned char *);
#ifdef __cplusplus
}
#endif

#define crypto_kem_ntrulpr953_keypair crypto_kem_ntrulpr953_ref_keypair
#define crypto_kem_ntrulpr953_enc crypto_kem_ntrulpr953_ref_enc
#define crypto_kem_ntrulpr953_dec crypto_kem_ntrulpr953_ref_dec
#define crypto_kem_ntrulpr953_PUBLICKEYBYTES crypto_kem_ntrulpr953_ref_PUBLICKEYBYTES
#define crypto_kem_ntrulpr953_SECRETKEYBYTES crypto_kem_ntrulpr953_ref_SECRETKEYBYTES
#define crypto_kem_ntrulpr953_BYTES crypto_kem_ntrulpr953_ref_BYTES
#define crypto_kem_ntrulpr953_CIPHERTEXTBYTES crypto_kem_ntrulpr953_ref_CIPHERTEXTBYTES

#endif

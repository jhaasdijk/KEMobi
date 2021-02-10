#ifndef crypto_kem_sntrup953_H
#define crypto_kem_sntrup953_H

#define crypto_kem_sntrup953_ref_SECRETKEYBYTES 2254
#define crypto_kem_sntrup953_ref_PUBLICKEYBYTES 1505
#define crypto_kem_sntrup953_ref_CIPHERTEXTBYTES 1349
#define crypto_kem_sntrup953_ref_BYTES 32
 
#ifdef __cplusplus
extern "C" {
#endif
extern int crypto_kem_sntrup953_ref_keypair(unsigned char *,unsigned char *);
extern int crypto_kem_sntrup953_ref_enc(unsigned char *,unsigned char *,const unsigned char *);
extern int crypto_kem_sntrup953_ref_dec(unsigned char *,const unsigned char *,const unsigned char *);
#ifdef __cplusplus
}
#endif

#define crypto_kem_sntrup953_keypair crypto_kem_sntrup953_ref_keypair
#define crypto_kem_sntrup953_enc crypto_kem_sntrup953_ref_enc
#define crypto_kem_sntrup953_dec crypto_kem_sntrup953_ref_dec
#define crypto_kem_sntrup953_PUBLICKEYBYTES crypto_kem_sntrup953_ref_PUBLICKEYBYTES
#define crypto_kem_sntrup953_SECRETKEYBYTES crypto_kem_sntrup953_ref_SECRETKEYBYTES
#define crypto_kem_sntrup953_BYTES crypto_kem_sntrup953_ref_BYTES
#define crypto_kem_sntrup953_CIPHERTEXTBYTES crypto_kem_sntrup953_ref_CIPHERTEXTBYTES

#endif

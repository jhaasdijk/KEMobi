#ifndef crypto_kem_sntrup761_H
#define crypto_kem_sntrup761_H

#define crypto_kem_sntrup761_ref_SECRETKEYBYTES 1763
#define crypto_kem_sntrup761_ref_PUBLICKEYBYTES 1158
#define crypto_kem_sntrup761_ref_CIPHERTEXTBYTES 1039
#define crypto_kem_sntrup761_ref_BYTES 32
 
#ifdef __cplusplus
extern "C" {
#endif
extern int crypto_kem_sntrup761_ref_keypair(unsigned char *,unsigned char *);
extern int crypto_kem_sntrup761_ref_enc(unsigned char *,unsigned char *,const unsigned char *);
extern int crypto_kem_sntrup761_ref_dec(unsigned char *,const unsigned char *,const unsigned char *);
#ifdef __cplusplus
}
#endif

#define crypto_kem_sntrup761_keypair crypto_kem_sntrup761_ref_keypair
#define crypto_kem_sntrup761_enc crypto_kem_sntrup761_ref_enc
#define crypto_kem_sntrup761_dec crypto_kem_sntrup761_ref_dec
#define crypto_kem_sntrup761_PUBLICKEYBYTES crypto_kem_sntrup761_ref_PUBLICKEYBYTES
#define crypto_kem_sntrup761_SECRETKEYBYTES crypto_kem_sntrup761_ref_SECRETKEYBYTES
#define crypto_kem_sntrup761_BYTES crypto_kem_sntrup761_ref_BYTES
#define crypto_kem_sntrup761_CIPHERTEXTBYTES crypto_kem_sntrup761_ref_CIPHERTEXTBYTES

#endif

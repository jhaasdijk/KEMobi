#ifndef crypto_kem_sntrup1013_H
#define crypto_kem_sntrup1013_H

#define crypto_kem_sntrup1013_ref_SECRETKEYBYTES 2417
#define crypto_kem_sntrup1013_ref_PUBLICKEYBYTES 1623
#define crypto_kem_sntrup1013_ref_CIPHERTEXTBYTES 1455
#define crypto_kem_sntrup1013_ref_BYTES 32
 
#ifdef __cplusplus
extern "C" {
#endif
extern int crypto_kem_sntrup1013_ref_keypair(unsigned char *,unsigned char *);
extern int crypto_kem_sntrup1013_ref_enc(unsigned char *,unsigned char *,const unsigned char *);
extern int crypto_kem_sntrup1013_ref_dec(unsigned char *,const unsigned char *,const unsigned char *);
#ifdef __cplusplus
}
#endif

#define crypto_kem_sntrup1013_keypair crypto_kem_sntrup1013_ref_keypair
#define crypto_kem_sntrup1013_enc crypto_kem_sntrup1013_ref_enc
#define crypto_kem_sntrup1013_dec crypto_kem_sntrup1013_ref_dec
#define crypto_kem_sntrup1013_PUBLICKEYBYTES crypto_kem_sntrup1013_ref_PUBLICKEYBYTES
#define crypto_kem_sntrup1013_SECRETKEYBYTES crypto_kem_sntrup1013_ref_SECRETKEYBYTES
#define crypto_kem_sntrup1013_BYTES crypto_kem_sntrup1013_ref_BYTES
#define crypto_kem_sntrup1013_CIPHERTEXTBYTES crypto_kem_sntrup1013_ref_CIPHERTEXTBYTES

#endif

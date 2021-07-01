# Prerequisites

We need to ensure that the OpenSSL development package has been installed. To do
this on the Raspberry Pi 4 execute `sudo apt install libssl-dev`.

# Reference implementation

The following are the benchmarks for the performance of the reference
implementation. They have been executed with `#define NTESTS 100`.

```shell
|------------------------------------------|--------------------|
| crypto_kem_keypair(pk, sk)               | med: 37537806      |
|------------------------------------------|--------------------|
| Seeds_random()                           | med: 11526         |
| Generator()                              | med: 70910         |
| Short_random()                           | med: 7207628       |
| Rq_mult_small()                          | med: 30133606      |
| Round()                                  | med: 42034         |
| Rounded_encode()                         | med: 14807         |
| Small_encode()                           | med: 613           |
| randombytes()                            | med: 11504         |
| Hash_prefix()                            | med: 8745          |
|------------------------------------------|--------------------|
| crypto_kem_enc(ct, ss, pk)               | med: 60747989      |
|------------------------------------------|--------------------|
| Hash_prefix(                             | med: 8745          |
| Inputs_random()                          | med: 12291         |
| Hide()                                   | med: 60719623      |
| HashSession()                            | med: 9835          |
|------------------------------------------|--------------------|
| crypto_kem_dec(ss1, ct, sk)              | med: 90930810      |
|------------------------------------------|--------------------|
| Decrypt()                                | med: 30159256      |
| Hide()                                   | med: 60710242      |
|------------------------------------------|--------------------|
```

# Optimized implementation

The following are the benchmarks for the performance of the optimized
implementation. They have been executed with `#define NTESTS 100`.

```shell
|------------------------------------------|--------------------|
| crypto_kem_keypair(pk, sk)               | med: 7761657       |
|------------------------------------------|--------------------|
| Seeds_random()                           | med: 11659         |
| Generator()                              | med: 70710         |
| Short_random()                           | med: 7324281       |
| Rq_mult_small()                          | med: 241769        |
| Round()                                  | med: 42034         |
| Rounded_encode()                         | med: 14857         |
| Small_encode()                           | med: 620           |
| randombytes()                            | med: 11713         |
| Hash_prefix()                            | med: 8746          |
|------------------------------------------|--------------------|
| crypto_kem_enc(ct, ss, pk)               | med: 996576        |
|------------------------------------------|--------------------|
| Hash_prefix()                            | med: 8746          |
| Inputs_random()                          | med: 12481         |
| Hide()                                   | med: 956928        |
| HashSession()                            | med: 9889          |
|------------------------------------------|--------------------|
| crypto_kem_dec(ss1, ct, sk)              | med: 1299607       |
|------------------------------------------|--------------------|
| Decrypt()                                | med: 271826        |
| Hide()                                   | med: 957394        |
|------------------------------------------|--------------------|
|- Short_random() -------------------------|--------------------|
| urandom32()               ( x 761 )      | med: 9332          |
| Short_fromlist()          ( x 1   )      | med: 187470        |
|------------------------------------------|--------------------|
```

Note that all depicted cycle counts are the median for a single execution of the
concerning function. The `( x 761 )` and `( x 1   )` notation is merely used to
illustrate how many times these routines are used within `Short_random()`.

Currently the only difference compared to the reference implementation is the
use of NTT based polynomial multiplication. This is most notable in the cost
comparison between `Rq_mult_small()`.

**In total** this means that the performance cost for the key generation,
encapsulation and decapsulation of the reference implementation is reduced by
79.32%, 98.36% and 98.57% respectively in the optimized implementation.

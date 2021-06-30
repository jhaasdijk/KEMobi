# Reference implementation

The following are the benchmarks for the performance of the reference
implementation. They have been executed with `#define NTESTS 100`.

```shell
|------------------------------------------|--------------------|
| crypto_kem_keypair(pk, sk)               | med: 37593660      |
|------------------------------------------|--------------------|
| Seeds_random()                           | med: 11523         |
| Generator()                              | med: 71280         |
| Short_random()                           | med: 7254952       |
| Rq_mult_small()                          | med: 30133944      |
| Round()                                  | med: 42034         |
| Rounded_encode()                         | med: 14846         |
| Small_encode()                           | med: 613           |
| randombytes()                            | med: 11523         |
| Hash_prefix()                            | med: 8744          |
|------------------------------------------|--------------------|
| crypto_kem_enc(ct, ss, pk)               | med: 60756027      |
|------------------------------------------|--------------------|
| Hash_prefix(                             | med: 8744          |
| Inputs_random()                          | med: 12317         |
| Hide()                                   | med: 60745593      |
| HashSession()                            | med: 9836          |
|------------------------------------------|--------------------|
| crypto_kem_dec(ss1, ct, sk)              | med: 90946276      |
|------------------------------------------|--------------------|
| Decrypt()                                | med: 30159316      |
| Hide()                                   | med: 60715631      |
|------------------------------------------|--------------------|
```

# Optimized implementation

The following are the benchmarks for the performance of the optimized
implementation. They have been executed with `#define NTESTS 100`.

```shell
|------------------------------------------|--------------------|
| crypto_kem_keypair(pk, sk)               | med: 7744107       |
|------------------------------------------|--------------------|
| Seeds_random()                           | med: 11746         |
| Generator()                              | med: 71237         |
| Short_random()                           | med: 7296954       |
| Rq_mult_small()                          | med: 249146        |
| Round()                                  | med: 42034         |
| Rounded_encode()                         | med: 15047         |
| Small_encode()                           | med: 620           |
| randombytes()                            | med: 11656         |
| Hash_prefix()                            | med: 8753          |
|------------------------------------------|--------------------|
| crypto_kem_enc(ct, ss, pk)               | med: 990034        |
|------------------------------------------|--------------------|
| Hash_prefix(                             | med: 8757          |
| Inputs_random()                          | med: 12472         |
| Hide()                                   | med: 952573        |
| HashSession()                            | med: 9854          |
|------------------------------------------|--------------------|
| crypto_kem_dec(ss1, ct, sk)              | med: 1292251       |
|------------------------------------------|--------------------|
| Decrypt()                                | med: 276801        |
| Hide()                                   | med: 954705        |
|------------------------------------------|--------------------|
|- Short_random() -------------------------|--------------------|
| urandom32()               ( x 761 )      | med: 9348          |
| Short_fromlist()          ( x 1   )      | med: 187410        |
|------------------------------------------|--------------------|
```

Note that all depicted cycle counts are the median for a single execution of the
concerning function. The `( x 761 )` and `( x 1   )` notation is merely used to
illustrate how many times these routines are used within `Short_random()`.

Currently the only difference compared to the reference implementation is the
use of NTT based polynomial multiplication. This is most notable in the cost
comparison between `Rq_mult_small()`.

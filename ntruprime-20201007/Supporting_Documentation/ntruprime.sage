sntrup = { # round1,p,q,w,lpr
  'sntrup4591761': (True,761,4591,286,False),
  'sntrup761':    (False,761,4591,286,False),
  'sntrup653':    (False,653,4621,288,False),
  'sntrup857':    (False,857,5167,322,False),
  'sntrup953':    (False,953,6343,396,False),
  'sntrup1013':   (False,1013,7177,448,False),
  'sntrup1277':   (False,1277,7879,492,False),
}

ntrulpr = { # round1,p,q,w,lpr,delta,tau0,tau1,tau2,tau3
  'ntrulpr4591761': (True,761,4591,250,True,292,2156,114,2007,287),
  'ntrulpr761':    (False,761,4591,250,True,292,2156,114,2007,287),
  'ntrulpr653':    (False,653,4621,252,True,289,2175,113,2031,290),
  'ntrulpr857':    (False,857,5167,281,True,329,2433,101,2265,324),
  'ntrulpr953':    (False,953,6343,345,True,404,2997,82,2798,400),
  'ntrulpr1013':   (False,1013,7177,392,True,450,3367,73,3143,449),
  'ntrulpr1277':   (False,1277,7879,429,True,502,3724,66,3469,496),
}

def setparameters(system,random8):
  global round1
  global p
  global q
  global w
  global lpr
  global delta
  global tau0
  global tau1
  global tau2
  global tau3

  global PublicKeys_bytes
  global SecretKeys_bytes
  global Ciphertexts_bytes
  global Inputs_bytes
  global Confirm_bytes
  global Hash_bytes
  global Rq_encode
  global Inputs_random
  global ZKeyGen
  global ZEncrypt
  global ZDecrypt

  if system in sntrup:
    round1,p,q,w,lpr = sntrup[system]
    assert lpr == False
  elif system in ntrulpr:
    round1,p,q,w,lpr,delta,tau0,tau1,tau2,tau3 = ntrulpr[system]
    assert lpr == True
  else:
    raise Exception('%s is not one of the selected parameter sets' % system)

  usecache = not round1
  # False to match round1 spec
  # True to match round2 spec
  # tests below also support False variant with round2

  # ----- parameter requirements
  # tested later: irreducibility of x^p-x-1 mod q
  # tested later: Top-Right requirements if lpr

  assert p.is_prime()
  assert q.is_prime()
  assert w > 0
  assert 2*p >= 3*w
  assert q >= 16*w+1
  assert q%6 == 1 # spec allows 5 but these tests do not
  assert p%4 == 1 # spec allows 3 but ref C code does not

  if lpr:
    I = 256
    assert I > 0
    assert I%8 == 0
    assert p >= I
    assert q >= 16*w+2*delta+3

  if round1: # encodings defined only for (761,4591)
    usecache = False
    assert p == 761
    assert q == 4591

  # ----- arithmetic mod 3

  if not lpr:
    F3 = GF(3)
    def ZZ_fromF3(c):
      assert c in F3
      return ZZ(c+1)-1

  # ----- arithmetic mod q

  Fq = GF(q)
  q12 = ZZ((q-1)/2)
  def ZZ_fromFq(c):
    assert c in Fq
    return ZZ(c+q12)-q12

  # ----- Top and Right

  if lpr:
    tau = 16

    global Top
    def Top(C):
      C = ZZ_fromFq(C)
      return floor((tau1*(C+tau0)+2^14)/2^15)

    for C in Fq:
      T = Top(C)
      assert T >= 0
      assert T < tau

    def Right(T):
      assert T >= 0
      assert T < tau
      return Fq(tau3*T-tau2)

    diff = [ZZ_fromFq(Right(Top(C))-C) for C in Fq]
    assert min(diff) == 0 # spec also allows >0
    assert max(diff) == delta # spec also allows <delta

  # ----- polynomials over integers

  global R

  Zx.<x> = ZZ[]
  R.<xp> = Zx.quotient(x^p-x-1)

  def Weightw_is(r):
    assert r in R
    return w == len([i for i in range(p) if r[i] != 0])

  def Small_is(r):
    assert r in R
    return all(abs(r[i]) <= 1 for i in range(p))

  def Short_is(r):
    return Small_is(r) and Weightw_is(r)

  # ----- polynomials mod 3

  if not lpr:
    F3x.<x3> = F3[]
    R3.<x3p> = F3x.quotient(x^p-x-1)

    def R_fromR3(r):
      assert r in R3
      return R([ZZ_fromF3(r[i]) for i in range(p)])

    def R3_fromR(r):
      assert r in R
      return R3([r[i] for i in range(p)])

  # ----- polynomials mod q

  Fqx.<xq> = Fq[]
  assert (xq^p-xq-1).is_irreducible()

  global Rq
  Rq.<xqp> = Fqx.quotient(x^p-x-1)

  global R_fromRq
  def R_fromRq(r):
    assert r in Rq
    return R([ZZ_fromFq(r[i]) for i in range(p)])

  global Rq_fromR
  def Rq_fromR(r):
    assert r in R
    return Rq([r[i] for i in range(p)])

  # ----- rounded polynomials mod q

  def Rounded_is(r):
    assert r in R
    return (all(r[i]%3 == 0 for i in range(p))
      and all(r[i] >= -q12 for i in range(p))
      and all(r[i] <= q12 for i in range(p)))

  def Round(a):
    assert a in Rq
    c = R_fromRq(a)
    r = [3*round(c[i]/3) for i in range(p)]
    assert all(abs(r[i]-c[i]) <= 1 for i in range(p))
    r = R(r)
    assert Rounded_is(r)
    return r

  # ----- sorting to generate short polynomial

  global Short_fromlist
  def Short_fromlist(L): # L is list of p uint32
    L = [L[i]&-2 for i in range(w)] + [(L[i]&-3)|1 for i in range(w,p)]
    assert all(L[i]%2 == 0 for i in range(w))
    assert all(L[i]%4 == 1 for i in range(w,p))
    L.sort()
    L = [(L[i]%4)-1 for i in range(p)]
    assert all(abs(L[i]) <= 1 for i in range(p))
    assert sum(abs(L[i]) for i in range(p)) == w
    r = R(L)
    assert Short_is(r)
    return r

  # ----- underlying hash function

  import hashlib

  global sha512
  def sha512(s):
    h = hashlib.sha512()
    h.update(s)
    return h.digest()

  if not round1:
    Hash_bytes = 32
    def Hash(s): return sha512(s)[:Hash_bytes]

    def Hash0(s): return Hash(chr(0)+s)
    def Hash1(s): return Hash(chr(1)+s)
    def Hash2(s): return Hash(chr(2)+s)
    if not lpr:
      def Hash3(s): return Hash(chr(3)+s)
    def Hash4(s): return Hash(chr(4)+s)
    if lpr:
      def Hash5(s): return Hash(chr(5)+s)

  # ----- higher-level randomness

  def urandom32():
    c0 = random8()
    c1 = random8()
    c2 = random8()
    c3 = random8()
    return c0 + 256*c1 + 65536*c2 + 16777216*c3

  global Short_random
  def Short_random(): # R element with w coeffs +-1
    if round1 and lpr:
      k = bytes(''.join(chr(random8()) for i in range(32)))
      L = Expand(k) # defined below
      L = [struct.unpack('<L',L[4*i:4*i+4])[0] for i in range(p)]
      return Short_fromlist(L)

    if round1:
      L = [urandom32() for i in range(p)]
      L = [L[i].__xor__(1<<31) for i in range(p)]
      return Short_fromlist(L)

    L = [urandom32() for i in range(p)]
    return Short_fromlist(L)

  if not lpr:
    def randomrange3():
      return ((urandom32() & 0x3fffffff) * 3) >> 30

    def Small_random():
      r = R([randomrange3()-1 for i in range(p)])
      assert Small_is(r)
      return r

  # ----- I-bit inputs

  if lpr:
    def Inputs_is(r):
      return len(r) == I and all(ri in [0,1] for ri in r)

  # ----- Top polynomials

  if lpr:
    def Top_is(T):
      return len(T) == I and all(Ti >= 0 and Ti < tau for Ti in T)

  # ----- Streamlined NTRU Prime Core and NTRU LPRime Core

  global KeyGen
  global Encrypt
  global Decrypt

  if not lpr:
    def KeyGen():
      while True:
        g = Small_random()
        if R3_fromR(g).is_unit(): break
      f = Short_random()
      h = Rq_fromR(g)/Rq_fromR(3*f)
      return h,(f,1/R3_fromR(g))

    def Encrypt(r,h):
      assert Short_is(r)
      assert h in Rq
      return Round(h*Rq_fromR(r))

    def Decrypt(c,k):
      f,v = k
      assert Rounded_is(c)
      assert Short_is(f)
      assert v in R3
      e = R3_fromR(R_fromRq(3*Rq_fromR(f)*Rq_fromR(c)))
      r = R_fromR3(e*v)
      if Weightw_is(r): return r
      return R([1]*w+[0]*(p-w))

  if lpr:
    # spec says uniform random G for Core, overridden in Expand
    def KeyGen(G):
      assert G in Rq
      a = Short_random()
      A = Round(Rq_fromR(a)*G)
      return (G,A),a

    # spec says uniform random b for Core, overridden in Expand
    def Encrypt(r,pk,b):
      assert Inputs_is(r)
      G,A = pk
      assert Rounded_is(A)
      assert G in Rq
      assert Short_is(b)
      B = Round(Rq_fromR(b)*G)
      bA = Rq_fromR(b)*Rq_fromR(A)
      T = [Top(bA[j]+r[j]*q12) for j in range(I)]
      return B,T

    def Decrypt(c,a):
      B,T = c
      assert Rounded_is(B)
      assert Top_is(T)
      assert Short_is(a)
      aB = Rq_fromR(a)*Rq_fromR(B)
      r = [ZZ_fromFq(Right(T[j])-aB[j]+4*w+1) < 0 for j in range(I)]
      assert Inputs_is(r)
      return r

  # ----- strings

  global tostring
  def tostring(s):
    return ''.join(chr(si) for si in s)

  def fromstring(s):
    return [ord(si) for si in s]

  # ----- encoding I-bit inputs

  if lpr:
    Inputs_bytes = ZZ(I/8)

    def Inputs_encode(r):
      assert Inputs_is(r)
      s = [sum(r[8*i+j]*2^j for j in range(8)) for i in range(32)]
      s = tostring(s)
      assert len(s) == Inputs_bytes
      return s

  # ----- Expand

  if lpr:
    from Crypto.Cipher import AES
    from Crypto.Util import Counter
    def Expand(k):
      assert len(k) == 32
      s = AES.new(k,AES.MODE_CTR,counter=Counter.new(128,initial_value=0))
      return s.encrypt('\0'*(4*p))

  # ----- Seeds

  if lpr:
    Seeds_bytes = 32

    def Seeds_random():
      seed = [random8() for i in range(Seeds_bytes)]
      return tostring(seed)

  # ----- Generator, HashShort

  if lpr:
    import struct

    def Generator(k):
      X = Expand(k)
      X = [struct.unpack('<L',X[4*i:4*i+4])[0] for i in range(p)]
      X = [X[i]%q for i in range(p)]
      X = [X[i]-q12 for i in range(p)]
      return Rq(X)

    def HashShort(r):
      r = Inputs_encode(r)
      if round1:
        k12 = sha512(r)
        k1,k2 = k12[:32],k12[32:]
        r = k1
      else:
        r = Hash5(r)
      X = Expand(r)
      X = [struct.unpack('<L',X[4*i:4*i+4])[0] for i in range(p)]
      return Short_fromlist(X)

  # ----- NTRU LPRime Expand

  if lpr:
    global XKeyGen
    global XEncrypt
    global XDecrypt

    def XKeyGen(): # KeyGen' in spec
      S = Seeds_random()
      G = Generator(S)
      pk,a = KeyGen(G)
      assert pk[0] == G
      return (S,pk[1]),a

    def XEncrypt(r,pk): # Encrypt' in spec
      assert Inputs_is(r)
      S,A = pk
      assert Rounded_is(A)
      G = Generator(S)
      return Encrypt(r,(G,A),HashShort(r))

    XDecrypt = Decrypt

  # ----- encoding small polynomials (including short polynomials)

  Small_bytes = ceil(p/4)

  def Small_encode(r):
    assert Small_is(r)
    R = [r[i]+1 for i in range(p)]
    while len(R) < 4*Small_bytes: R += [0]
    assert all(R[i] >= 0 for i in range(4*Small_bytes))
    assert all(R[i] <= 2 for i in range(4*Small_bytes))
    assert len(R) >= p
    assert len(R)%4 == 0
    S = [R[i]+4*R[i+1]+16*R[i+2]+64*R[i+3] for i in range(0,len(R),4)]
    return tostring(S)

  def Small_decode(s):
    S = fromstring(s)
    r = [(S[i//4]//4^(i%4))%4 for i in range(p)]
    assert all(r[i] >= 0 for i in range(p))
    assert all(r[i] <= 2 for i in range(p))
    r = [r[i]-1 for i in range(p)]
    return R(r)

  # ----- infrastructure for more general encoding

  if round1:
    import itertools
    def concat(lists): return list(itertools.chain.from_iterable(lists))

    def int2str(u,bytes):
      return ''.join(chr((u//256^i)%256) for i in range(bytes))

    def str2int(s):
      return sum(ord(s[i])*256^i for i in range(len(s)))

    def seq2str(u,radix,batch,bytes): # radix^batch <= 256^bytes
      return ''.join(int2str(sum(u[i+t]*radix^t for t in range(batch)),bytes)
                     for i in range(0,len(u),batch))

    def str2seq(s,radix,batch,bytes):
      u = [str2int(s[i:i+bytes]) for i in range(0,len(s),bytes)]
      return concat([(u[i]//radix^j)%radix for j in range(batch)] for i in range(len(u)))

  else:
    limit = 16384

    def Encode(R,M):
      if len(M) == 0: return []
      S = []
      if len(M) == 1:
        r,m = R[0],M[0]
        while m > 1:
          S += [r%256]
          r,m = r//256,(m+255)//256
        return S
      R2,M2 = [],[]
      for i in range(0,len(M)-1,2):
        m,r = M[i]*M[i+1],R[i]+M[i]*R[i+1]
        while m >= limit:
          S += [r%256]
          r,m = r//256,(m+255)//256
        R2 += [r]
        M2 += [m]
      if len(M)&1:
        R2 += [R[-1]]
        M2 += [M[-1]]
      return S+Encode(R2,M2)

    def Decode(S,M):
      if len(M) == 0: return []
      if len(M) == 1: return [sum(S[i]*256**i for i in range(len(S)))%M[0]]
      k = 0
      bottom,M2 = [],[]
      for i in range(0,len(M)-1,2):
        m,r,t = M[i]*M[i+1],0,1
        while m >= limit:
          r,t,k,m = r+S[k]*t,t*256,k+1,(m+255)//256
        bottom += [(r,t)]
        M2 += [m]
      if len(M)&1:
        M2 += [M[-1]]
      R2 = Decode(S[k:],M2)
      R = []
      for i in range(0,len(M)-1,2):
        r,t = bottom[i//2]
        r += t*R2[i//2]
        R += [r%M[i]]
        R += [(r//M[i])%M[i+1]]
      if len(M)&1:
        R += [R2[-1]]
      return R

  # ----- encoding general polynomials

  if not lpr:
    if round1:
      def Rq_encode(h):
        h = [q12 + ZZ_fromFq(h[i]) for i in range(p)] + [0]*(-p % 5)
        return seq2str(h,6144,5,8)[:1218]

      def Rq_decode(hstr):
        h = str2seq(hstr,6144,5,8)
        if max(h) >= q: raise Exception('pk out of range')
        return Rq([h[i]-q12 for i in range(p)])

    else:
      def Rq_encode(r):
        assert r in Rq
        R = [ZZ_fromFq(r[i])+q12 for i in range(p)]
        M = [q]*p
        assert all(0 <= R[i] for i in range(p))
        assert all(R[i] < M[i] for i in range(p))
        return tostring(Encode(R,M))

      def Rq_decode(s):
        assert len(s) == Rq_bytes
        M = [q]*p
        R = Decode(fromstring(s),M)
        assert all(0 <= R[i] for i in range(p))
        assert all(R[i] < M[i] for i in range(p))
        r = [R[i]-q12 for i in range(p)]
        return Rq(r)

    global Rq_bytes
    Rq_bytes = len(Rq_encode(Rq(0)))

  # ----- encoding rounded polynomials

  if round1:
    q61 = ZZ((q-1)/6)

    def Rounded_encode(c):
      c = [q61 + ZZ(c[i]/3) for i in range(p)] + [0]*(-p % 6)
      return seq2str(c,1536,3,4)[:1015]

    def Rounded_decode(cstr):
      c = str2seq(cstr,1536,3,4)
      c = [ci%(q61*2+1) for ci in c]
      return 3*R([c[i]-q61 for i in range(p)])

  else:
    def Rounded_encode(r):
      assert Rounded_is(r)
      R = [ZZ((ZZ_fromFq(r[i])+q12)/3) for i in range(p)]
      M = [ZZ((q-1)/3+1)]*p
      assert all(0 <= R[i] for i in range(p))
      assert all(R[i] < M[i] for i in range(p))
      return tostring(Encode(R,M))

    def Rounded_decode(s):
      assert len(s) == Rounded_bytes
      M = [ZZ((q-1)/3+1)]*p
      r = Decode(fromstring(s),M)
      assert all(0 <= r[i] for i in range(p))
      assert all(r[i] < M[i] for i in range(p))
      r = [3*r[i]-q12 for i in range(p)]
      return R(r)

  global Rounded_bytes
  Rounded_bytes = len(Rounded_encode(R(0)))

  # ----- encoding top polynomials

  if lpr:
    Top_bytes = ZZ(I/2)

    def Top_encode(T):
      s = [T[2*i]+16*T[2*i+1] for i in range(Top_bytes)]
      return tostring(s)

    def Top_decode(s):
      s = fromstring(s)
      return [(s[i//2]//16^(i%2))&15 for i in range(I)]

  # ----- Streamlined NTRU Prime Core plus encoding

  if not lpr:
    Inputs_random = Short_random
    Inputs_encode = Small_encode
    Inputs_bytes = Small_bytes

    Ciphertexts_bytes = Rounded_bytes
    SecretKeys_bytes = 2*Small_bytes
    PublicKeys_bytes = Rq_bytes

    if not round1:
      def Inputs_randomenc():
        rho = [random8() for i in range(Small_bytes)]
        return tostring(rho)

    def ZKeyGen():
      h,(f,v) = KeyGen()
      return Rq_encode(h),Small_encode(f)+Small_encode(R_fromR3(v))

    def ZEncrypt(r,pk):
      assert len(pk) == PublicKeys_bytes
      h = Rq_decode(pk)
      return Rounded_encode(Encrypt(r,h))

    def ZDecrypt(c,sk):
      assert len(sk) == SecretKeys_bytes
      assert len(c) == Ciphertexts_bytes
      f = Small_decode(sk[:Small_bytes])
      v = R3_fromR(Small_decode(sk[Small_bytes:]))
      c = Rounded_decode(c)
      return Decrypt(c,(f,v))

  # ----- NTRU LPRime Expand plus encoding

  if lpr:
    Ciphertexts_bytes = Rounded_bytes+Top_bytes
    SecretKeys_bytes = Small_bytes
    PublicKeys_bytes = Seeds_bytes+Rounded_bytes

    def Inputs_random():
      s = [random8() for i in range(ZZ(I/8))]
      return [(s[i//8]//2^(i%8))&1 for i in range(I)]

    if not round1:
      def Inputs_randomenc():
        return Inputs_encode(Inputs_random())

    def ZKeyGen():
      (S,A),a = XKeyGen()
      return S+Rounded_encode(A),Small_encode(a)

    def ZEncrypt(r,pk):
      assert len(pk) == PublicKeys_bytes
      S = pk[:Seeds_bytes]
      A = Rounded_decode(pk[Seeds_bytes:])
      B,T = XEncrypt(r,(S,A))
      return Rounded_encode(B)+Top_encode(T)

    def ZDecrypt(c,sk):
      assert len(sk) == SecretKeys_bytes
      assert len(c) == Ciphertexts_bytes
      a = Small_decode(sk)
      B = Rounded_decode(c[:Rounded_bytes])
      T = Top_decode(c[Rounded_bytes:])
      return XDecrypt((B,T),a)

  # ----- confirmation hash

  Confirm_bytes = 32

  def HashConfirm(r,K,cache=None):
    assert len(r) == Inputs_bytes
    assert len(K) == PublicKeys_bytes
    if round1:
      if lpr:
        k12 = sha512(r)
        k1,k2 = k12[:32],k12[32:]
        k34 = sha512(k2)
        k3,k4 = k34[:32],k34[32:]
        return k3
      return sha512(r)[:32]
    if not cache: cache = Hash4(K)
    assert cache == Hash4(K)
    if not lpr: r = Hash3(r)
    return Hash2(r+cache)

  # ----- session-key hash

  global HashSession
  def HashSession(b,y,z):
    assert len(y) == Inputs_bytes
    assert len(z) == Ciphertexts_bytes+Confirm_bytes
    assert b in [0,1]
    if round1:
      assert b == 1
      if lpr:
        k12 = sha512(y)
        k1,k2 = k12[:32],k12[32:]
        k34 = sha512(k2)
        k3,k4 = k34[:32],k34[32:]
        return k4
      return sha512(y)[32:]
    if not lpr: y = Hash3(y)
    if b == 1: return Hash1(y+z)
    return Hash0(y+z)

  # ----- Streamlined NTRU Prime and NTRU LPRime

  # KeyGen' in Streamlined NTRU Prime spec
  # KeyGen'' in NTRU LPRime spec
  global KEM_KeyGen
  def KEM_KeyGen():
    pk,sk = ZKeyGen()
    sk += pk
    if not round1:
      rho = Inputs_randomenc()
      sk += rho
    if usecache: sk += Hash4(pk)
    return pk,sk

  global Hide
  def Hide(r,pk,cache=None):
    r_enc = Inputs_encode(r)
    c = ZEncrypt(r,pk)
    gamma = HashConfirm(r_enc,pk,cache)
    if round1:
      c = gamma+c
    else:
      c = c+gamma
    return c,r_enc

  global Encap
  def Encap(pk):
    r = Inputs_random()
    C,r_enc = Hide(r,pk)
    return C,HashSession(1,r_enc,C)

  global Decap
  def Decap(C,sk):
    Corig = C
    if round1: gamma,C = C[:Confirm_bytes],C[Confirm_bytes:]
    c_inner,C = C[:Ciphertexts_bytes],C[Ciphertexts_bytes:]
    if not round1: gamma,C = C[:Confirm_bytes],C[Confirm_bytes:]
    assert len(C) == 0

    sk_inner,sk = sk[:SecretKeys_bytes],sk[SecretKeys_bytes:]
    pk,sk = sk[:PublicKeys_bytes],sk[PublicKeys_bytes:]
    if not round1: rho,sk = sk[:Inputs_bytes],sk[Inputs_bytes:]
    cache = None
    if usecache: cache,sk = sk[:Hash_bytes],sk[Hash_bytes:]
    assert len(sk) == 0

    r = ZDecrypt(c_inner,sk_inner)
    Cnew,r_enc = Hide(r,pk,cache)

    assert len(r_enc) == Inputs_bytes
    if not round1: assert len(rho) == Inputs_bytes

    if Cnew == Corig: return HashSession(1,r_enc,Corig)
    if round1: return False
    return HashSession(0,rho,Corig)

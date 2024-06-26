{-# LANGUAGE CPP #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE MagicHash #-}
{-# LANGUAGE PolyKinds #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE ConstraintKinds #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE NoStarIsType #-}
-- | Utilities for working with 'KnownNat' constraints.
--
-- This module is only available on GHC 8.0 or later.
module Data.Constraint.Nat
  ( Min, Max, Lcm, Gcd, Divides, Div, Mod, Log2
  , plusNat, minusNat, timesNat, powNat, minNat, maxNat, gcdNat, lcmNat, divNat, modNat, log2Nat
  , plusZero, minusZero, timesZero, timesOne, powZero, powOne, maxZero, minZero, gcdZero, gcdOne, lcmZero, lcmOne
  , plusAssociates, timesAssociates, minAssociates, maxAssociates, gcdAssociates, lcmAssociates
  , plusCommutes, timesCommutes, minCommutes, maxCommutes, gcdCommutes, lcmCommutes
  , plusDistributesOverTimes, timesDistributesOverPow, timesDistributesOverGcd, timesDistributesOverLcm
  , minDistributesOverPlus, minDistributesOverTimes, minDistributesOverPow1, minDistributesOverPow2, minDistributesOverMax
  , maxDistributesOverPlus, maxDistributesOverTimes, maxDistributesOverPow1, maxDistributesOverPow2, maxDistributesOverMin
  , gcdDistributesOverLcm, lcmDistributesOverGcd
  , minIsIdempotent, maxIsIdempotent, lcmIsIdempotent, gcdIsIdempotent
  , plusIsCancellative, timesIsCancellative
  , dividesPlus, dividesTimes, dividesMin, dividesMax, dividesPow, dividesGcd, dividesLcm
  , plusMonotone1, plusMonotone2
  , timesMonotone1, timesMonotone2
  , powMonotone1, powMonotone2
  , minMonotone1, minMonotone2
  , maxMonotone1, maxMonotone2
  , divMonotone1, divMonotone2
  , euclideanNat
  , plusMod, timesMod
  , modBound
  , log2Pow
  , dividesDef
  , timesDiv
  , eqLe, leEq, leId, leTrans
  , leZero, zeroLe
  , plusMinusInverse1, plusMinusInverse2, plusMinusInverse3
  ) where

import Data.Constraint
import Data.Constraint.Unsafe
import Data.Proxy
import Data.Type.Bool
import GHC.TypeNats
import qualified Numeric.Natural as Nat

#if MIN_VERSION_base(4,15,0)
import GHC.Num.Natural (naturalLog2)
#else
import GHC.Exts (Int(..))
import GHC.Integer.Logarithms (integerLog2#)
#endif

#if !MIN_VERSION_base(4,18,0)
import Unsafe.Coerce
#endif

type family Min (m::Nat) (n::Nat) :: Nat where
    Min m n = If (n <=? m) n m
type family Max (m::Nat) (n::Nat) :: Nat where
    Max m n = If (n <=? m) m n
type family Gcd (m::Nat) (n::Nat) :: Nat where
    Gcd m m = m
type family Lcm (m::Nat) (n::Nat) :: Nat where
   Lcm m m = m

type Divides n m = n ~ Gcd n m

#if !MIN_VERSION_base(4,18,0)
newtype Magic n = Magic (KnownNat n => Dict (KnownNat n))
#endif

magicNNN :: forall n m o. (Nat.Natural -> Nat.Natural -> Nat.Natural) -> (KnownNat n, KnownNat m) :- KnownNat o
#if MIN_VERSION_base(4,18,0)
magicNNN f = Sub $ withKnownNat @o (unsafeSNat (natVal (Proxy @n) `f` natVal (Proxy @m))) Dict
#else
magicNNN f = Sub $ unsafeCoerce (Magic Dict) (natVal (Proxy @n) `f` natVal (Proxy @m))
#endif

magicNN :: forall n m. (Nat.Natural -> Nat.Natural) -> KnownNat n :- KnownNat m
#if MIN_VERSION_base(4,18,0)
magicNN f = Sub $ withKnownNat @m (unsafeSNat (f (natVal (Proxy @n)))) Dict
#else
magicNN f = Sub $ unsafeCoerce (Magic Dict) (f (natVal (Proxy :: Proxy n)))
#endif

axiomLe :: forall (a :: Nat) (b :: Nat). Dict (a <= b)
axiomLe = unsafeAxiom

eqLe :: forall (a :: Nat) (b :: Nat). (a ~ b) :- (a <= b)
eqLe = Sub Dict

dividesGcd :: forall a b c. (Divides a b, Divides a c) :- Divides a (Gcd b c)
dividesGcd = Sub unsafeAxiom

dividesLcm :: forall a b c. (Divides a c, Divides b c) :- Divides (Lcm a b) c
dividesLcm = Sub unsafeAxiom

gcdCommutes :: forall a b. Dict (Gcd a b ~ Gcd b a)
gcdCommutes = unsafeAxiom

lcmCommutes :: forall a b. Dict (Lcm a b ~ Lcm b a)
lcmCommutes = unsafeAxiom

gcdZero :: forall a. Dict (Gcd 0 a ~ a)
gcdZero = unsafeAxiom

gcdOne :: forall a. Dict (Gcd 1 a ~ 1)
gcdOne = unsafeAxiom

lcmZero :: forall a. Dict (Lcm 0 a ~ 0)
lcmZero = unsafeAxiom

lcmOne :: forall a. Dict (Lcm 1 a ~ a)
lcmOne = unsafeAxiom

gcdNat :: forall n m. (KnownNat n, KnownNat m) :- KnownNat (Gcd n m)
gcdNat = magicNNN gcd

lcmNat :: forall n m. (KnownNat n, KnownNat m) :- KnownNat (Lcm n m)
lcmNat = magicNNN lcm

plusNat :: forall n m. (KnownNat n, KnownNat m) :- KnownNat (n + m)
plusNat = magicNNN (+)

minusNat :: forall n m. (KnownNat n, KnownNat m, m <= n) :- KnownNat (n - m)
minusNat = Sub $ case magicNNN @n @m (-) of Sub r -> r

minNat   :: forall n m. (KnownNat n, KnownNat m) :- KnownNat (Min n m)
minNat = magicNNN min

maxNat   :: forall n m. (KnownNat n, KnownNat m) :- KnownNat (Max n m)
maxNat = magicNNN max

timesNat  :: forall n m. (KnownNat n, KnownNat m) :- KnownNat (n * m)
timesNat = magicNNN (*)

powNat :: forall n m. (KnownNat n, KnownNat m) :- KnownNat (n ^ m)
powNat = magicNNN (^)

divNat :: forall n m. (KnownNat n, KnownNat m, 1 <= m) :- KnownNat (Div n m)
divNat = Sub $ case magicNNN @n @m div of Sub r -> r

modNat :: forall n m. (KnownNat n, KnownNat m, 1 <= m) :- KnownNat (Mod n m)
modNat = Sub $ case magicNNN @n @m mod of Sub r -> r

log2Nat :: forall n. (KnownNat n, 1 <= n) :- KnownNat (Log2 n)
log2Nat = Sub $ case magicNN @n log2 of Sub r -> r
  where
    log2 :: Nat.Natural -> Nat.Natural
#if MIN_VERSION_base(4,15,0)
    log2 n = fromIntegral (naturalLog2 n)
#else
    log2 n = fromIntegral (I# (integerLog2# (toInteger n)))
#endif

plusZero :: forall n. Dict ((n + 0) ~ n)
plusZero = Dict

minusZero :: forall n. Dict ((n - 0) ~ n)
minusZero = Dict

timesZero :: forall n. Dict ((n * 0) ~ 0)
timesZero = Dict

timesOne :: forall n. Dict ((n * 1) ~ n)
timesOne = Dict

minZero :: forall n. Dict (Min n 0 ~ 0)
#if MIN_VERSION_base(4,16,0)
minZero = unsafeAxiom
#else
minZero = Dict
#endif

maxZero :: forall n. Dict (Max n 0 ~ n)
#if MIN_VERSION_base(4,16,0)
maxZero = unsafeAxiom
#else
maxZero = Dict
#endif

powZero :: forall n. Dict ((n ^ 0) ~ 1)
powZero = Dict

leZero :: forall a. (a <= 0) :- (a ~ 0)
leZero = Sub unsafeAxiom

zeroLe :: forall (a :: Nat). Dict (0 <= a)
#if MIN_VERSION_base(4,16,0)
zeroLe = unsafeAxiom
#else
zeroLe = Dict
#endif

plusMinusInverse1 :: forall n m. Dict (((m + n) - n) ~ m)
plusMinusInverse1 = unsafeAxiom

plusMinusInverse2 :: forall n m. (m <= n) :- (((m + n) - m) ~ n)
plusMinusInverse2 = Sub unsafeAxiom

plusMinusInverse3 :: forall n m. (n <= m) :- (((m - n) + n) ~ m)
plusMinusInverse3 = Sub unsafeAxiom

plusMonotone1 :: forall a b c. (a <= b) :- (a + c <= b + c)
plusMonotone1 = Sub unsafeAxiom

plusMonotone2 :: forall a b c. (b <= c) :- (a + b <= a + c)
plusMonotone2 = Sub unsafeAxiom

powMonotone1 :: forall a b c. (a <= b) :- ((a^c) <= (b^c))
powMonotone1 = Sub unsafeAxiom

powMonotone2 :: forall a b c. (b <= c) :- ((a^b) <= (a^c))
powMonotone2 = Sub unsafeAxiom

divMonotone1 :: forall a b c. (a <= b) :- (Div a c <= Div b c)
divMonotone1 = Sub unsafeAxiom

divMonotone2 :: forall a b c. (b <= c) :- (Div a c <= Div a b)
divMonotone2 = Sub unsafeAxiom

timesMonotone1 :: forall a b c. (a <= b) :- (a * c <= b * c)
timesMonotone1 = Sub unsafeAxiom

timesMonotone2 :: forall a b c. (b <= c) :- (a * b <= a * c)
timesMonotone2 = Sub unsafeAxiom

minMonotone1 :: forall a b c. (a <= b) :- (Min a c <= Min b c)
minMonotone1 = Sub unsafeAxiom

minMonotone2 :: forall a b c. (b <= c) :- (Min a b <= Min a c)
minMonotone2 = Sub unsafeAxiom

maxMonotone1 :: forall a b c. (a <= b) :- (Max a c <= Max b c)
maxMonotone1 = Sub unsafeAxiom

maxMonotone2 :: forall a b c. (b <= c) :- (Max a b <= Max a c)
maxMonotone2 = Sub unsafeAxiom

powOne :: forall n. Dict ((n ^ 1) ~ n)
powOne = unsafeAxiom

plusMod :: forall a b c. (1 <= c) :- (Mod (a + b) c ~ Mod (Mod a c + Mod b c) c)
plusMod = Sub unsafeAxiom

timesMod :: forall a b c. (1 <= c) :- (Mod (a * b) c ~ Mod (Mod a c * Mod b c) c)
timesMod = Sub unsafeAxiom

modBound :: forall m n. (1 <= n) :- (Mod m n <= n)
modBound = Sub unsafeAxiom

log2Pow :: forall n. Dict (Log2 (2 ^ n) ~ n)
log2Pow = unsafeAxiom

euclideanNat :: (1 <= c) :- (a ~ (c * Div a c + Mod a c))
euclideanNat = Sub unsafeAxiom

plusCommutes :: forall n m. Dict ((m + n) ~ (n + m))
plusCommutes = unsafeAxiom

timesCommutes :: forall n m. Dict ((m * n) ~ (n * m))
timesCommutes = unsafeAxiom

minCommutes :: forall n m. Dict (Min m n ~ Min n m)
minCommutes = unsafeAxiom

maxCommutes :: forall n m. Dict (Max m n ~ Max n m)
maxCommutes = unsafeAxiom

plusAssociates :: forall m n o. Dict (((m + n) + o) ~ (m + (n + o)))
plusAssociates = unsafeAxiom

timesAssociates :: forall m n o. Dict (((m * n) * o) ~ (m * (n * o)))
timesAssociates = unsafeAxiom

minAssociates :: forall m n o. Dict (Min (Min m n) o ~ Min m (Min n o))
minAssociates = unsafeAxiom

maxAssociates :: forall m n o. Dict (Max (Max m n) o ~ Max m (Max n o))
maxAssociates = unsafeAxiom

gcdAssociates :: forall a b c. Dict (Gcd (Gcd a b) c  ~ Gcd a (Gcd b c))
gcdAssociates = unsafeAxiom

lcmAssociates :: forall a b c. Dict (Lcm (Lcm a b) c ~ Lcm a (Lcm b c))
lcmAssociates = unsafeAxiom

minIsIdempotent :: forall n. Dict (Min n n ~ n)
minIsIdempotent = Dict

maxIsIdempotent :: forall n. Dict (Max n n ~ n)
maxIsIdempotent = Dict

gcdIsIdempotent :: forall n. Dict (Gcd n n ~ n)
gcdIsIdempotent = Dict

lcmIsIdempotent :: forall n. Dict (Lcm n n ~ n)
lcmIsIdempotent = Dict

minDistributesOverPlus :: forall n m o. Dict ((n + Min m o) ~ Min (n + m) (n + o))
minDistributesOverPlus = unsafeAxiom

minDistributesOverTimes :: forall n m o. Dict ((n * Min m o) ~ Min (n * m) (n * o))
minDistributesOverTimes = unsafeAxiom

minDistributesOverPow1 :: forall n m o. Dict ((Min n m ^ o) ~ Min (n ^ o) (m ^ o))
minDistributesOverPow1 = unsafeAxiom

minDistributesOverPow2 :: forall n m o. Dict ((n ^ Min m o) ~ Min (n ^ m) (n ^ o))
minDistributesOverPow2 = unsafeAxiom

minDistributesOverMax :: forall n m o. Dict (Max n (Min m o) ~ Min (Max n m) (Max n o))
minDistributesOverMax = unsafeAxiom

maxDistributesOverPlus :: forall n m o. Dict ((n + Max m o) ~ Max (n + m) (n + o))
maxDistributesOverPlus = unsafeAxiom

maxDistributesOverTimes :: forall n m o. Dict ((n * Max m o) ~ Max (n * m) (n * o))
maxDistributesOverTimes = unsafeAxiom

maxDistributesOverPow1 :: forall n m o. Dict ((Max n m ^ o) ~ Max (n ^ o) (m ^ o))
maxDistributesOverPow1 = unsafeAxiom

maxDistributesOverPow2 :: forall n m o. Dict ((n ^ Max m o) ~ Max (n ^ m) (n ^ o))
maxDistributesOverPow2 = unsafeAxiom

maxDistributesOverMin :: forall n m o. Dict (Min n (Max m o) ~ Max (Min n m) (Min n o))
maxDistributesOverMin = unsafeAxiom

plusDistributesOverTimes :: forall n m o. Dict ((n * (m + o)) ~ (n * m + n * o))
plusDistributesOverTimes = unsafeAxiom

timesDistributesOverPow  :: forall n m o. Dict ((n ^ (m + o)) ~ (n ^ m * n ^ o))
timesDistributesOverPow = unsafeAxiom

timesDistributesOverGcd :: forall n m o. Dict ((n * Gcd m o) ~ Gcd (n * m) (n * o))
timesDistributesOverGcd = unsafeAxiom

timesDistributesOverLcm :: forall n m o. Dict ((n * Lcm m o) ~ Lcm (n * m) (n * o))
timesDistributesOverLcm = unsafeAxiom

plusIsCancellative :: forall n m o. ((n + m) ~ (n + o)) :- (m ~ o)
plusIsCancellative = Sub unsafeAxiom

timesIsCancellative :: forall n m o. (1 <= n, (n * m) ~ (n * o)) :- (m ~ o)
timesIsCancellative = Sub unsafeAxiom

gcdDistributesOverLcm :: forall a b c. Dict (Gcd (Lcm a b) c ~ Lcm (Gcd a c) (Gcd b c))
gcdDistributesOverLcm = unsafeAxiom

lcmDistributesOverGcd :: forall a b c. Dict (Lcm (Gcd a b) c ~ Gcd (Lcm a c) (Lcm b c))
lcmDistributesOverGcd = unsafeAxiom

dividesPlus :: (Divides a b, Divides a c) :- Divides a (b + c)
dividesPlus = Sub unsafeAxiom

dividesTimes :: Divides a b :- Divides a (b * c)
dividesTimes = Sub unsafeAxiom

dividesMin :: (Divides a b, Divides a c) :- Divides a (Min b c)
dividesMin = Sub unsafeAxiom

dividesMax :: (Divides a b, Divides a c) :- Divides a (Max b c)
dividesMax = Sub unsafeAxiom

-- This `dividesDef` is simpler and more convenient than Divides a b :- ((a * Div b a) ~ b)
-- because the latter can be easily derived via 'euclideanNat', but not vice versa.

dividesDef :: forall a b. Divides a b :- (Mod b a ~ 0)
dividesDef = Sub unsafeAxiom

dividesPow :: (1 <= n, Divides a b) :- Divides a (b^n)
dividesPow = Sub unsafeAxiom

timesDiv :: forall a b. Dict ((a * Div b a) <= b)
timesDiv = unsafeAxiom

-- (<=) is an internal category in the category of constraints.

leId :: forall (a :: Nat). Dict (a <= a)
leId = Dict

leEq :: forall (a :: Nat) (b :: Nat). (a <= b, b <= a) :- (a ~ b)
leEq = Sub unsafeAxiom

leTrans :: forall (a :: Nat) (b :: Nat) (c :: Nat). (b <= c, a <= b) :- (a <= c)
leTrans = Sub (axiomLe @a @c)

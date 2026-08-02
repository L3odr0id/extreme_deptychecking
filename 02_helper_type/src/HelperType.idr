module HelperType

import Data.Fin

import Data.Fuel
import Test.DepTyCheck.Gen

import public Common

%default total

{-
  Helper-type pattern

  Task: split a given long `FinsList` into exactly four groups such that
    - no fin is repeated across the four groups, and
    - every fin from the source list appears in exactly one group
      (i.e. the four groups form a partition / permutation of `src`).

  NaivePartition asks DepTyCheck to create four lists and a permutation proof at once.

  FillInto4 places each source element in order into one of the four buckets (Fin 4),
  so coverage and uniqueness follow by construction from walking `src` once.
  It also uses the second-fuel pattern: an additional `Nat` (`steps`).
  At the top level `steps` must be given as `src.length`.
-}

---------------------------------------------------------------
-- Domain
---------------------------------------------------------------

public export
record FourGroups (n : Nat) where
  constructor MkFour
  g0 : FinsList n
  g1 : FinsList n
  g2 : FinsList n
  g3 : FinsList n

%name FourGroups buckets

public export
flat4 : FourGroups n -> FinsList n
flat4 (MkFour a b c d) = a ++ b ++ c ++ d

---------------------------------------------------------------
-- Naive implementation
---------------------------------------------------------------

||| Proof that `x` occurs in `xs`, with the remainder after removing one occurrence.
public export
data Remove : Fin n -> FinsList n -> FinsList n -> Type where
  RemHere  : Remove x (x :: xs) xs
  RemThere : Remove x xs ys -> Remove x (y :: xs) (y :: ys)

||| `xs` is a permutation of `ys` (same elements with the same multiplicities).
public export
data IsPermutation : FinsList n -> FinsList n -> Type where
  PermNil  : IsPermutation [] []
  PermCons : Remove x ys ys' ->
             IsPermutation xs ys' ->
             IsPermutation (x :: xs) ys

||| Split `src` into four groups whose concatenation is a permutation of `src`.
||| The generator must create the four lists and the permutation proof together.
public export
data NaivePartition : {n : Nat} -> (src : FinsList n) -> Type where
  MkNaive : (buckets : FourGroups n) ->
            (0 ok : IsPermutation src (flat4 buckets)) ->
            NaivePartition src

export
genNaivePartition : Fuel -> {n : Nat} -> (src : FinsList n) -> Gen MaybeEmpty $ NaivePartition src

---------------------------------------------------------------
-- Helper type implementation
---------------------------------------------------------------

public export
emptyFour : FourGroups n
emptyFour = MkFour [] [] [] []

public export
addToBucket : FourGroups n -> Fin 4 -> Fin n -> FourGroups n
addToBucket (MkFour a b c d) FZ                      f = MkFour (f :: a) b c d
addToBucket (MkFour a b c d) (FS FZ)                 f = MkFour a (f :: b) c d
addToBucket (MkFour a b c d) (FS (FS FZ))            f = MkFour a b (f :: c) d
addToBucket (MkFour a b c d) (FS (FS (FS FZ)))       f = MkFour a b c (f :: d)
addToBucket (MkFour a b c d) (FS (FS (FS (FS i))))   f = absurd i

||| Given buckets `pre`, place elements of `src` into `mid`.
|||
||| Uses the second-fuel pattern (`ConsumersListFNat`-style):
||| - `left` — `Fin` index stepped with `weaken` / `FS`
||| - `steps` — additional `Nat` fuel; pass `src.length` at the top level
|||
||| - `FEnd` — nothing left (`left = FZ`, `steps = 0`), result equals `pre`
||| - `FPut` — put `src[i]` into bucket `target`, consume one Fin unit and one Nat
public export
data FillInto4 : {n : Nat} ->
                 (src : FinsList n) ->
                 (pre : FourGroups n) ->
                 (left : Fin (S src.length)) ->
                 (steps : Nat) ->
                 (mid : FourGroups n) ->
                 Type where
  FEnd : FillInto4 src pre FZ 0 pre
  FPut : {i : Fin src.length} ->
         {k : Nat} ->
         (recur : FillInto4 src pre (weaken i) k mid) ->
         (target : Fin 4) ->
         FillInto4 src pre (FS i) (S k) (addToBucket mid target (index src i))

||| Partition of `src` into four groups, built only via `FillInto4`.
||| Start from `emptyFour` with `left = last` and `steps = src.length`
||| (the Nat must be the length of the input list).
public export
data HelperPartition : {n : Nat} -> (src : FinsList n) -> (steps : Nat) -> Type where
  MkHelper : {buckets : FourGroups n} ->
             FillInto4 src HelperType.emptyFour Data.Fin.last steps buckets ->
             HelperPartition src steps

export
genHelperPartition : Fuel ->
                     {n : Nat} ->
                     (src : FinsList n) ->
                     (steps : Nat) ->
                     Gen MaybeEmpty $ HelperPartition src steps

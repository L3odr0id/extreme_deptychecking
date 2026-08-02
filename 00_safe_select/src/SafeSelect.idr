module SafeSelect

import Data.Fin
import Data.List
import Data.Vect

import Data.Fuel
import Test.DepTyCheck.Gen

import public Common

%default total

{-
  Safe-select pattern

  Task: for each `a` in an `AList`, pick an index into `bs` that is compatible with `a`.

  BoolPred is the simplest pick: `Fin` plus `So (isCompatible ...)`.
  SimpleDepTyPred uses an inductive `IsCompatible` proof instead.
  CompValues / FuncPred / DepTyPred shrink the choice set first
  (by values, by boolean filter on fins, or by a constructive filter),
  then pick into that set.
-}

---------------------------------------------------------------
-- BoolPred: Fin into full list + boolean So witness
---------------------------------------------------------------

||| Pick `fb` and require `isCompatible` as a boolean `So` proof.
public export
data BoolPredResult : A -> BsList -> Type where
  BPR : (fb : Fin bs.length) -> (pred : So (isCompatible a (index bs fb))) -> BoolPredResult a bs

namespace BoolPredResultList

  public export
  data BoolPredResultList : AList -> BsList -> Type where
    Nil  : BoolPredResultList [] bs
    (::) : BoolPredResult a bs -> BoolPredResultList as bs -> BoolPredResultList (a::as) bs

  %name BoolPredResultList bprs

  public export
  length : BoolPredResultList as bs -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : BoolPredResultList as bs -> Nat
  (.length) = length

export
genBoolPredResults : Fuel -> (as : AList) -> (bs : BsList) -> Gen MaybeEmpty $ BoolPredResultList as bs

---------------------------------------------------------------
-- SimpleDepTyPred: Fin into full list + compatibility proof
---------------------------------------------------------------

||| Pick `fb` into `bs` and prove `a` is compatible with that element.
public export
data SimpleDepTyPredResult : A -> BsList -> Type where
  SDTPR : (fb : Fin bs.length) -> IsCompatible a (index bs fb) -> SimpleDepTyPredResult a bs

namespace SimpleDepTyPredResultList

  public export
  data SimpleDepTyPredResultList : AList -> BsList -> Type where
    Nil  : SimpleDepTyPredResultList [] bs
    (::) : SimpleDepTyPredResult a bs -> SimpleDepTyPredResultList as bs -> SimpleDepTyPredResultList (a::as) bs

  %name SimpleDepTyPredResultList sdtprs

  public export
  length : SimpleDepTyPredResultList as bs -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : SimpleDepTyPredResultList as bs -> Nat
  (.length) = length

export
genSimpleDepTyPredResults : Fuel -> (as : AList) -> (bs : BsList) -> Gen MaybeEmpty $ SimpleDepTyPredResultList as bs

---------------------------------------------------------------
-- CompValues: filter to compatible values, then Fin into that list
---------------------------------------------------------------

||| Keep only `B`s compatible with `a`
public export
findCompatible : A -> (allBs : BsList) -> BsList
findCompatible a bs = fromList $ foldr (\b, acc => if isCompatible a b then b::acc else acc) [] $ toList bs

||| Pick into the already-filtered compatible values
public export
data CompValuesResult : A -> BsList -> Type where
  MkCompValues : (fb' : Fin (findCompatible a bs).length) -> CompValuesResult a bs

namespace CompValuesResultList

  public export
  data CompValuesResultList : AList -> BsList -> Type where
    Nil  : CompValuesResultList [] bs
    (::) : CompValuesResult a bs -> CompValuesResultList as bs -> CompValuesResultList (a::as) bs

  %name CompValuesResultList cvs

  public export
  length : CompValuesResultList as bs -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : CompValuesResultList as bs -> Nat
  (.length) = length

export
genCompValuesResults : Fuel -> (as : AList) -> (bs : BsList) -> Gen MaybeEmpty $ CompValuesResultList as bs

---------------------------------------------------------------
-- FuncPred: filter to good Fins via boolean check, then Fin into that
---------------------------------------------------------------

||| Indices into `bs` whose element is compatible with `a`
public export
goodFins : A -> (bs : BsList) -> FinsList bs.length
goodFins a bs = fromList $ foldr (\fb, acc => if isCompatible a (index bs fb) then fb::acc else acc) [] $
                  toList $ Data.Vect.allFins bs.length

||| Pick into the filtered index list produced by `goodFins`
public export
data FuncPredResult : A -> BsList -> Type where
  MkFuncPred : (fb' : Fin (goodFins a bs).length) -> FuncPredResult a bs

namespace FuncPredResultList

  public export
  data FuncPredResultList : AList -> BsList -> Type where
    Nil  : FuncPredResultList [] bs
    (::) : FuncPredResult a bs -> FuncPredResultList as bs -> FuncPredResultList (a::as) bs

  %name FuncPredResultList fps

  public export
  length : FuncPredResultList as bs -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : FuncPredResultList as bs -> Nat
  (.length) = length

export
genFuncPredResults : Fuel -> (as : AList) -> (bs : BsList) -> Gen MaybeEmpty $ FuncPredResultList as bs

---------------------------------------------------------------
-- DepTyPred: constructive filter, then Fin into the kept fins
---------------------------------------------------------------

||| `Keep` compatible heads, `Drop` the rest
public export
data FilteredCompatibleFins : A -> (bs : BsList) -> FinsList bs.length -> Type where
  Nil  : FilteredCompatibleFins a [] []
  Keep : IsCompatible a b ->
         FilteredCompatibleFins a bs rest ->
         FilteredCompatibleFins a (b :: bs) (FZ :: weakenFins rest)
  Drop : NotCompatible a b ->
         FilteredCompatibleFins a bs rest ->
         FilteredCompatibleFins a (b :: bs) (weakenFins rest)

||| Build a filtered fin list constructively, then pick into it
public export
data DepTyPredResult : A -> BsList -> Type where
  MkDepTyPred : (a : A) ->
                {0 goodBFins : FinsList bs.length} ->
                (0 filtered : FilteredCompatibleFins a bs goodBFins) ->
                (finalFinB : Fin goodBFins.length) ->
                DepTyPredResult a bs

namespace DepTyPredResultList

  public export
  data DepTyPredResultList : AList -> BsList -> Type where
    Nil  : DepTyPredResultList [] bs
    (::) : DepTyPredResult a bs -> DepTyPredResultList as bs -> DepTyPredResultList (a::as) bs

  %name DepTyPredResultList dts

  public export
  length : DepTyPredResultList as bs -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : DepTyPredResultList as bs -> Nat
  (.length) = length

export
genDepTyPredResults : Fuel -> (as : AList) -> (bs : BsList) -> Gen MaybeEmpty $ DepTyPredResultList as bs

module ConstructivePredicate

import Data.Fin
import Data.List
import Data.Vect

import Data.Fuel
import Test.DepTyCheck.Gen

import Deriving.DepTyCheck.Gen

import public Common

%default total

{-
  Constructive-predicate pattern

  Task: for each `a`, pick a compatible element of `bs` (or of a fin-tagged view of `bs`).

  Compares four ways:
  - DepTyPred — naive: `Fin` + inductive `IsCompatible`
  - FuncPred — `goodFins` boolean filter, then `Fin` into that
  - FilteredFins — constructive filter of `bs`, then pick into kept fins
  - ConstructiveDepTyPred — compatibility witness + filter over a `FinB2List`
-}

---------------------------------------------------------------
-- DepTyPred: naive Fin + IsCompatible
---------------------------------------------------------------

||| Pick `fb` and prove compatibility with `IsCompatible`.
public export
data DepTyPredResult : A -> BsList -> Type where
  DTPR : (fb : Fin bs.length) -> (pred : IsCompatible a (index bs fb)) -> DepTyPredResult a bs

namespace DepTyPredResultList

  public export
  data DepTyPredResultList : AList -> BsList -> Type where
    Nil  : DepTyPredResultList [] bs
    (::) : DepTyPredResult a bs -> DepTyPredResultList asl bs -> DepTyPredResultList (a::asl) bs

  %name DepTyPredResultList dtprs

  public export
  length : DepTyPredResultList asl bs -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : DepTyPredResultList asl bs -> Nat
  (.length) = length

export
genDepTyPredResultList : Fuel -> (asl : AList) -> (bs : BsList) -> Gen0 $ DepTyPredResultList asl bs

---------------------------------------------------------------
-- FuncPred: goodFins boolean filter, then Fin into that
---------------------------------------------------------------

||| Indices into `bs` whose element is compatible with `a`.
public export
goodFins : A -> (bs : BsList) -> FinsList bs.length
goodFins a bs = fromList $ foldr (\fb, acc => if isCompatible a (index bs fb) then fb::acc else acc) [] $
                  toList $ Data.Vect.allFins bs.length

||| Pick into the filtered index list produced by `goodFins`.
public export
data FuncPredResult : A -> BsList -> Type where
  MkFuncPred : (fb' : Fin (goodFins a bs).length) -> FuncPredResult a bs

namespace FuncPredResultList

  public export
  data FuncPredResultList : AList -> BsList -> Type where
    Nil  : FuncPredResultList [] bs
    (::) : FuncPredResult a bs -> FuncPredResultList asl bs -> FuncPredResultList (a::asl) bs

  %name FuncPredResultList fps

  public export
  length : FuncPredResultList asl bs -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : FuncPredResultList asl bs -> Nat
  (.length) = length

export
genFuncPredResultList : Fuel -> (asl : AList) -> (bs : BsList) -> Gen0 $ FuncPredResultList asl bs

---------------------------------------------------------------
-- FilteredFins: constructive filter of bs, then Fin into kept fins
---------------------------------------------------------------

namespace FilteredCompatibleFins

  ||| Filter of `bs` into the fins of compatible elements
  public export
  data FilteredCompatibleFins : A -> (bs : BsList) -> FinsList bs.length -> Type where
    Nil  : FilteredCompatibleFins a [] []
    Keep : IsCompatible a b ->
           FilteredCompatibleFins a bs rest ->
           FilteredCompatibleFins a (b :: bs) (FZ :: weakenFins rest)
    Drop : NotCompatible a b ->
           FilteredCompatibleFins a bs rest ->
           FilteredCompatibleFins a (b :: bs) (weakenFins rest)

||| Filter first, then pick into the filtered fin list
public export
data FilteredFinsResult : A -> BsList -> Type where
  MkFilteredFins : (a : A) ->
                   {0 goodBFins : FinsList bs.length} ->
                   (0 filtered : FilteredCompatibleFins a bs goodBFins) ->
                   (finalFinB : Fin goodBFins.length) ->
                   FilteredFinsResult a bs

namespace FilteredFinsResultList

  public export
  data FilteredFinsResultList : AList -> BsList -> Type where
    Nil  : FilteredFinsResultList [] bs
    (::) : FilteredFinsResult a bs -> FilteredFinsResultList asl bs -> FilteredFinsResultList (a::asl) bs

  %name FilteredFinsResultList ffrs

  public export
  length : FilteredFinsResultList asl bs -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : FilteredFinsResultList asl bs -> Nat
  (.length) = length

export
genFilteredFinsResultList : Fuel -> (asl : AList) -> (bs : BsList) -> Gen0 $ FilteredFinsResultList asl bs

---------------------------------------------------------------
-- ConstructiveDepTyPred: compatibility + filter over FinB2List
---------------------------------------------------------------

namespace BsVect

  public export
  data BsVect : Nat -> Type where
    Nil  : BsVect Z
    (::) : B -> BsVect n -> BsVect (S n)

  %name BsVect bv

  public export
  length : BsVect n -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : BsVect n -> Nat
  (.length) = length

  public export
  index : (fs : BsVect n) -> Fin fs.length -> B
  index (f::_ ) FZ     = f
  index (_::fs) (FS i) = index fs i

public export
data FinB : Type where
  MkFinB : Fin n -> B -> FinB

namespace FinBList

  public export
  data FinBList : Type where
    Nil  : FinBList
    (::) : FinB -> FinBList -> FinBList

  %name FinBList fbs

  public export
  length : FinBList -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : FinBList -> Nat
  (.length) = length

  public export
  index : (fs : FinBList) -> Fin fs.length -> FinB
  index (f::_ ) FZ     = f
  index (_::fs) (FS i) = index fs i

public export
data FinA : Type where
  MkFinA : Fin n -> A -> FinA

namespace FinAList

  public export
  data FinAList : Type where
    Nil  : FinAList
    (::) : FinA -> FinAList -> FinAList

  %name FinAList fbs

  public export
  length : FinAList -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : FinAList -> Nat
  (.length) = length

  public export
  index : (fs : FinAList) -> Fin fs.length -> FinA
  index (f::_ ) FZ     = f
  index (_::fs) (FS i) = index fs i

public export
data FinB2 : Nat -> Type where
  MkFinB2 : Fin n -> B -> FinB2 n

namespace FinB2List

  public export
  data FinB2List : Nat -> Type where
    Nil  : FinB2List n
    (::) : FinB2 n -> FinB2List n -> FinB2List n

  %name FinBList fbs

  public export
  length : FinB2List n -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : FinB2List n -> Nat
  (.length) = length

  public export
  index : (fs : FinB2List n) -> Fin fs.length -> FinB2 n
  index (f::_ ) FZ     = f
  index (_::fs) (FS i) = index fs i

public export
data BeqB : B -> B -> Type where
  BEQ1 : BeqB MkB1 MkB1
  BEQ2 : BeqB MkB2 MkB2
  BEQ3 : BeqB MkB3 MkB3
  BEQ4 : BeqB MkB4 MkB4

public export
data BneqB : B -> B -> Type where
  B12 : BneqB MkB1 MkB2
  B13 : BneqB MkB1 MkB3
  B14 : BneqB MkB1 MkB4
  B21 : BneqB MkB2 MkB1
  B23 : BneqB MkB2 MkB3
  B24 : BneqB MkB2 MkB4
  B31 : BneqB MkB3 MkB1
  B32 : BneqB MkB3 MkB2
  B34 : BneqB MkB3 MkB4
  B41 : BneqB MkB4 MkB1
  B42 : BneqB MkB4 MkB2
  B43 : BneqB MkB4 MkB3

||| Filter `FinB2List` to fins whose `B` equals a chosen `b`
public export
data FilteredBFinss : B -> (bs : FinB2List fullBs) -> FinsList fullBs -> Type where
  Nil   : FilteredBFinss b [] []
  Eq    : BeqB b b'  -> FilteredBFinss b finsb rest -> FilteredBFinss b ((MkFinB2 f b')::finsb) (f::rest)
  NotEq : BneqB b b' -> FilteredBFinss b finsb rest -> FilteredBFinss b ((MkFinB2 f b')::finsb) rest

||| Pick `b` compatible with `a`, filter the fin-tagged list to that `b`, then pick into the filtered fins
public export
data ConstructiveDepTyPredResult : A -> FinB2List fullBs -> Type where
  CDTPR : {0 b : B} -> {0 goodBFins : FinsList fullBs} ->
          (0 pred : IsCompatible a b) ->
          (0 filteredAsHelper : FilteredBFinss b finbs goodBFins) ->
          (finalFinB : Fin goodBFins.length) ->
          ConstructiveDepTyPredResult a finbs

GenOrderTuning "CDTPR".dataCon where
  isConstructor = itIsConstructor
  deriveFirst _ _ = [`{pred}, `{b}, `{filteredAsHelper}, `{goodBFins}, `{finalFinB}]

namespace ConstructiveDepTyPredResultList

  public export
  data ConstructiveDepTyPredResultList : AList -> FinB2List fullBs -> Type where
    Nil  : ConstructiveDepTyPredResultList [] fbs
    (::) : ConstructiveDepTyPredResult a fbs -> ConstructiveDepTyPredResultList asl fbs -> ConstructiveDepTyPredResultList (a::asl) fbs

  %name ConstructiveDepTyPredResultList cdtprs

  public export
  length : ConstructiveDepTyPredResultList asl fbs -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : ConstructiveDepTyPredResultList asl fbs -> Nat
  (.length) = length

export
genConstructiveDepTyPredResultList : Fuel -> (asl : AList) -> {fullBs : Nat} -> (fbs : FinB2List fullBs) -> Gen0 $ ConstructiveDepTyPredResultList asl fbs

module Common

import Data.Fin

%default total

public export
data A : Type where
  MkA1 : A
  MkA2 : A
  MkA3 : A
  MkA4 : A

public export
data B : Type where
  MkB1 : B
  MkB2 : B
  MkB3 : B
  MkB4 : B

namespace AList

  public export
  data AList : Type where
    Nil  : AList
    (::) : A -> AList -> AList

  %name AList as

  public export
  length : AList -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : AList -> Nat
  (.length) = length

  public export
  index : (fs : AList) -> Fin fs.length -> A
  index (f::_ ) FZ     = f
  index (_::fs) (FS i) = index fs i

namespace BsList

  public export
  data BsList : Type where
    Nil  : BsList
    (::) : B -> BsList -> BsList

  %name BsList bs

  public export
  length : BsList -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : BsList -> Nat
  (.length) = length

  public export
  index : (fs : BsList) -> Fin fs.length -> B
  index (f::_ ) FZ     = f
  index (_::fs) (FS i) = index fs i

  public export
  toList : BsList -> List B
  toList []      = []
  toList (x::xs) = x :: toList xs

  public export
  fromList : List B -> BsList
  fromList []      = []
  fromList (x::xs) = x :: fromList xs

namespace FinsList

  public export
  data FinsList : Nat -> Type where
    Nil  : FinsList n
    (::) : Fin n -> FinsList n -> FinsList n

  %name FinsList fs

  public export
  toList : FinsList n -> List $ Fin n
  toList []      = []
  toList (x::xs) = x :: toList xs

  public export
  fromList : List (Fin n) -> FinsList n
  fromList []      = []
  fromList (x::xs) = x :: fromList xs

  public export
  length : FinsList n -> Nat
  length []      = 0
  length (x::xs) = S $ length xs

  public export %inline
  (.length) : FinsList n -> Nat
  (.length) = length

  public export
  index : (fs : FinsList s) -> Fin fs.length -> Fin s
  index (f::_ ) FZ     = f
  index (_::fs) (FS i) = index fs i

  public export
  weakenFins : FinsList n -> FinsList (S n)
  weakenFins []      = []
  weakenFins (f::fs) = FS f :: weakenFins fs

  public export
  (++) : FinsList n -> FinsList n -> FinsList n
  []      ++ ys = ys
  (x::xs) ++ ys = x :: xs ++ ys

public export
data IsCompatible : A -> B -> Type where
  C11 : IsCompatible MkA1 MkB1
  C22 : IsCompatible MkA2 MkB2
  C33 : IsCompatible MkA3 MkB3
  C44 : IsCompatible MkA4 MkB4

public export
data NotCompatible : A -> B -> Type where
  N12 : NotCompatible MkA1 MkB2
  N13 : NotCompatible MkA1 MkB3
  N14 : NotCompatible MkA1 MkB4
  N21 : NotCompatible MkA2 MkB1
  N23 : NotCompatible MkA2 MkB3
  N24 : NotCompatible MkA2 MkB4
  N31 : NotCompatible MkA3 MkB1
  N32 : NotCompatible MkA3 MkB2
  N34 : NotCompatible MkA3 MkB4
  N41 : NotCompatible MkA4 MkB1
  N42 : NotCompatible MkA4 MkB2
  N43 : NotCompatible MkA4 MkB3

public export
isCompatible : A -> B -> Bool
isCompatible MkA1 MkB1 = True
isCompatible MkA2 MkB2 = True
isCompatible MkA3 MkB3 = True
isCompatible MkA4 MkB4 = True
isCompatible _    _    = False

public export
aFromNat : Nat -> A
aFromNat 0 = MkA1
aFromNat 1 = MkA2
aFromNat 2 = MkA3
aFromNat _ = MkA4

public export
asOfLength : Nat -> AList
asOfLength n = go 0 n
  where
    go : Nat -> Nat -> AList
    go _ Z     = []
    go i (S k) = aFromNat (i `mod` 4) :: go (S i) k

public export
predefinedBs : BsList
predefinedBs =
  [ MkB1, MkB2, MkB3, MkB4
  , MkB1, MkB2, MkB3, MkB4
  , MkB1, MkB2, MkB3, MkB4
  ]

module SecondFuel

import Data.Fin

import Data.Fuel
import Test.DepTyCheck.Gen

import public Common

%default total

{-
  Second-fuel pattern

  Task: build a list whose length is tied to a `Fin` index 
  (each step "consumes" one unit of that index).

  ConsumersListFin uses only the `Fin`.

  ConsumersListFNat also tracks a separate `Nat` length.
-}

---------------------------------------------------------------
-- Payload consumed at each step
---------------------------------------------------------------

public export
data FinConsumer : Fin n -> Type where
  Consume : FinConsumer f

---------------------------------------------------------------
-- Length from Fin alone
---------------------------------------------------------------

namespace ConsumersListFin

  ||| List length equals `finToNat` of the index; `weaken` steps down the Fin.
  public export
  data ConsumersListFin : Fin (S n) -> Type where
    Nil  : ConsumersListFin FZ
    (::) : FinConsumer f -> ConsumersListFin (weaken i) -> ConsumersListFin (FS i)

export
genConsumersListFin : Fuel -> {n' : Nat} -> (f : Fin $ S n') -> Gen MaybeEmpty $ ConsumersListFin f

---------------------------------------------------------------
-- Fin index plus a separate Nat length
---------------------------------------------------------------

namespace ConsumersListFNat

  ||| Same spine as `ConsumersListFin`, but length is also indexed by a `Nat`.
  ||| `Nat` works as a second Fuel.
  ||| Useful only when that `Nat` matches the `Fin`; otherwise the gen fails.
  public export
  data ConsumersListFNat : Fin (S n) -> Nat -> Type where
    Nil  : ConsumersListFNat FZ Z
    (::) : FinConsumer f -> ConsumersListFNat (weaken i) k -> ConsumersListFNat (FS i) (S k)

export
genConsumersListFNat : Fuel -> {n' : Nat} -> (f : Fin $ S n') -> (k : Nat) -> Gen MaybeEmpty $ ConsumersListFNat f k

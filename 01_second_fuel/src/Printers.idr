module Printers

import Data.Fin
import Test.DepTyCheck.Gen
import Text.PrettyPrint.Bernardy

import Pretty
import SecondFuel

%default total

consumersListFinItems : ConsumersListFin f -> List String
consumersListFinItems []              = []
consumersListFinItems (Consume :: xs) = "Consume" :: consumersListFinItems xs

ConsumersListFNatItems : ConsumersListFNat f k -> List String
ConsumersListFNatItems []              = []
ConsumersListFNatItems (Consume :: xs) = "Consume" :: ConsumersListFNatItems xs

export
printConsumersListFin : {opts : LayoutOpts} ->
                        ConsumersListFin f -> Gen0 $ Doc opts
printConsumersListFin xs = printAny $ consumersListFinItems xs

export
printConsumersListFNat : {opts : LayoutOpts} ->
                        ConsumersListFNat f k -> Gen0 $ Doc opts
printConsumersListFNat xs = printAny $ ConsumersListFNatItems xs

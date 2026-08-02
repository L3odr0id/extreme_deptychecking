module Main

import Data.Fin
import Data.Fuel

import Test.DepTyCheck.Gen
import Text.PrettyPrint.Bernardy

import Cli
import ConsumersListFin.Derived
import ConsumersListFNat.Derived
import Printers

%default total

data Mode = ConsumersListFinMode | ConsumersListFNatMode

parseMode : String -> Either String Mode
parseMode "consumerslistfin" = Right ConsumersListFinMode
parseMode "ConsumersListFNat" = Right ConsumersListFNatMode
parseMode mode               = Left $ "unknown generator `" ++ mode ++ "`. Expected consumerslistfin or ConsumersListFNat"

defaultConfig : Cfg Mode
defaultConfig = MkConfig 10 (limit 4) ConsumersListFinMode 10

covering
runSelected : Cfg Mode -> IO ()
runSelected cfg = case cfg.selected of
  ConsumersListFinMode => run cfg.testsCnt printConsumersListFin $ genConsumersListFin cfg.modelFuel {n' = cfg.size} last
  ConsumersListFNatMode => run cfg.testsCnt printConsumersListFNat $ genConsumersListFNat cfg.modelFuel {n' = cfg.size} last cfg.size

covering
main : IO ()
main = mainWith
  "Usage: second_fuel [OPTIONS]"
  parseMode
  " <consumerslistfin|ConsumersListFNat>"
  defaultConfig
  runSelected

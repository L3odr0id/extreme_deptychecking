module Main

import Data.Fin
import Data.Fuel

import Test.DepTyCheck.Gen
import Text.PrettyPrint.Bernardy

import Cli
import Common
import DepTyPred.Derived
import FuncPred.Derived
import FilteredFins.Derived
import ConstructiveDepTyPred.Derived
import Printers
import ConstructivePredicate

%default total

weakenFinBs : FinB2List n -> FinB2List (S n)
weakenFinBs [] = []
weakenFinBs (MkFinB2 f b :: xs) = MkFinB2 (FS f) b :: weakenFinBs xs

fromBsList : (bs : BsList) -> FinB2List (BsList.length bs)
fromBsList []        = []
fromBsList (b :: bs) = MkFinB2 FZ b :: weakenFinBs (fromBsList bs)

predefinedFinBs : FinB2List 12
predefinedFinBs = fromBsList predefinedBs

data Mode = DepTyPredMode | FuncPredMode | FilteredFinsMode | ConstructiveDepTyPredMode

parseMode : String -> Either String Mode
parseMode "deptypred"             = Right DepTyPredMode
parseMode "funcpred"              = Right FuncPredMode
parseMode "filteredfins"          = Right FilteredFinsMode
parseMode "constructivedeptypred" = Right ConstructiveDepTyPredMode
parseMode mode                    = Left $ "unknown generator `" ++ mode ++ "`. Expected deptypred, funcpred, filteredfins, or constructivedeptypred"

defaultConfig : Cfg Mode
defaultConfig = MkConfig 10 (limit 4) DepTyPredMode 10

covering
runSelected : Cfg Mode -> IO ()
runSelected cfg =
  let as = asOfLength cfg.size
  in case cfg.selected of
    DepTyPredMode             => run cfg.testsCnt printDepTyPred             $ genDepTyPredResultList             cfg.modelFuel as predefinedBs
    FuncPredMode              => run cfg.testsCnt printFuncPred              $ genFuncPredResultList              cfg.modelFuel as predefinedBs
    FilteredFinsMode          => run cfg.testsCnt printFilteredFins          $ genFilteredFinsResultList          cfg.modelFuel as predefinedBs
    ConstructiveDepTyPredMode => run cfg.testsCnt printConstructiveDepTyPred $ genConstructiveDepTyPredResultList cfg.modelFuel as predefinedFinBs

covering
main : IO ()
main = mainWith
  "Usage: constructive_predicate [OPTIONS]"
  parseMode
  " <deptypred|funcpred|filteredfins|constructivedeptypred>"
  defaultConfig
  runSelected

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
import ImageDepTyPred.Derived
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

data Mode = DepTyPredMode | FuncPredMode | FilteredFinsMode | ImageDepTyPredMode

parseMode : String -> Either String Mode
parseMode "deptypred"             = Right DepTyPredMode
parseMode "funcpred"              = Right FuncPredMode
parseMode "filteredfins"          = Right FilteredFinsMode
parseMode "imagedeptypred" = Right ImageDepTyPredMode
parseMode mode                    = Left $ "unknown generator `" ++ mode ++ "`. Expected deptypred, funcpred, filteredfins, or imagedeptypred"

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
    ImageDepTyPredMode => run cfg.testsCnt printImageDepTyPred $ genImageDepTyPredResultList cfg.modelFuel as predefinedFinBs

covering
main : IO ()
main = mainWith
  "Usage: constructive_predicate [OPTIONS]"
  parseMode
  " <deptypred|funcpred|filteredfins|imagedeptypred>"
  defaultConfig
  runSelected

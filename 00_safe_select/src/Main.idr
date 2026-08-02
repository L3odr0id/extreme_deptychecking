module Main

import Data.Fuel

import Test.DepTyCheck.Gen
import Text.PrettyPrint.Bernardy

import Cli
import Common
import BoolPred.Derived
import SimpleDepTyPred.Derived
import CompValues.Derived
import FuncPred.Derived
import DepTyPred.Derived
import Printers

%default total

data Mode = BoolPredMode | SimpleDepTyPredMode | CompValuesMode | FuncPredMode | DepTyPredMode

parseMode : String -> Either String Mode
parseMode "boolpred"        = Right BoolPredMode
parseMode "simpledeptypred" = Right SimpleDepTyPredMode
parseMode "compvalues"      = Right CompValuesMode
parseMode "funcpred"        = Right FuncPredMode
parseMode "deptypred"       = Right DepTyPredMode
parseMode mode              = Left $ "unknown generator `" ++ mode ++ "`. Expected boolpred, simpledeptypred, compvalues, funcpred, or deptypred"

defaultConfig : Cfg Mode
defaultConfig = MkConfig 10 (limit 4) BoolPredMode 10

covering
runSelected : Cfg Mode -> IO ()
runSelected cfg =
  let as = asOfLength cfg.size
  in case cfg.selected of
    BoolPredMode         => run cfg.testsCnt printBoolPred         $ genBoolPredResults         cfg.modelFuel as predefinedBs
    SimpleDepTyPredMode  => run cfg.testsCnt printSimpleDepTyPred  $ genSimpleDepTyPredResults  cfg.modelFuel as predefinedBs
    CompValuesMode       => run cfg.testsCnt printCompValues       $ genCompValuesResults       cfg.modelFuel as predefinedBs
    FuncPredMode         => run cfg.testsCnt printFuncPred         $ genFuncPredResults         cfg.modelFuel as predefinedBs
    DepTyPredMode        => run cfg.testsCnt printDepTyPred        $ genDepTyPredResults        cfg.modelFuel as predefinedBs

covering
main : IO ()
main = mainWith
  "Usage: safe_select [OPTIONS]"
  parseMode
  " <boolpred|simpledeptypred|compvalues|funcpred|deptypred>"
  defaultConfig
  runSelected

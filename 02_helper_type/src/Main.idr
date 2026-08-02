module Main

import Data.Fin
import Data.Fuel
import Data.List

import Test.DepTyCheck.Gen
import Text.PrettyPrint.Bernardy

import Cli
import Common
import Naive.Derived
import Helper.Derived
import Printers

%default total

||| Source list to partition: every `Fin n` once, in order.
srcOfSize : (n : Nat) -> FinsList n
srcOfSize n = fromList (allFins n)

data Mode = NaiveMode | HelperMode

parseMode : String -> Either String Mode
parseMode "naive"  = Right NaiveMode
parseMode "helper" = Right HelperMode
parseMode mode     = Left $ "unknown generator `" ++ mode ++ "`. Expected naive or helper"

defaultConfig : Cfg Mode
defaultConfig = MkConfig 10 (limit 4) HelperMode 10

covering
runSelected : Cfg Mode -> IO ()
runSelected cfg =
  let src = srcOfSize cfg.size
  in case cfg.selected of
    NaiveMode  => run cfg.testsCnt printNaivePartition  $ genNaivePartition  cfg.modelFuel src
    -- Second fuel: `steps` must be `src.length` (here equal to `cfg.size`).
    HelperMode => run cfg.testsCnt printHelperPartition $ genHelperPartition cfg.modelFuel src src.length

covering
main : IO ()
main = mainWith
  "Usage: helper_type [OPTIONS]"
  parseMode
  " <naive|helper>"
  defaultConfig
  runSelected

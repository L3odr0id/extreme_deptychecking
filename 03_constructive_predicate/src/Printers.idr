module Printers

import Data.Fin
import Test.DepTyCheck.Gen
import Text.PrettyPrint.Bernardy

import Common
import Pretty
import ConstructivePredicate

%default total

depTyPredItems : {bs : BsList} -> DepTyPredResultList asl bs -> List String
depTyPredItems []                     = []
depTyPredItems (DTPR fb _ :: results) = finValue fb (index bs fb) :: depTyPredItems results

funcPredItems : {asl : AList} -> {bs : BsList} -> FuncPredResultList asl bs -> List String
funcPredItems [] = []
funcPredItems {asl = a :: _} (MkFuncPred fin' :: results) =
  let fin = index (goodFins a bs) fin'
  in finValue fin (index bs fin) :: funcPredItems results

filteredFinsItems : FilteredFinsResultList asl bs -> List String
filteredFinsItems []                                        = []
filteredFinsItems (MkFilteredFins _ _ finalFinB :: results) = filteredFinValue finalFinB :: filteredFinsItems results

constructiveDepTyPredItems : ConstructiveDepTyPredResultList asl fbs -> List String
constructiveDepTyPredItems []                        = []
constructiveDepTyPredItems (CDTPR _ _ fb :: results) = filteredFinValue fb :: constructiveDepTyPredItems results

export
printDepTyPred : {opts : LayoutOpts} -> {bs : BsList} ->
                 DepTyPredResultList asl bs -> Gen0 $ Doc opts
printDepTyPred {bs} results = printAny $ depTyPredItems {bs} results

export
printFuncPred : {opts : LayoutOpts} -> {asl : AList} -> {bs : BsList} ->
                FuncPredResultList asl bs -> Gen0 $ Doc opts
printFuncPred {asl} {bs} results = printAny $ funcPredItems {asl} {bs} results

export
printFilteredFins : {opts : LayoutOpts} ->
                    FilteredFinsResultList asl bs -> Gen0 $ Doc opts
printFilteredFins results = printAny $ filteredFinsItems results

export
printConstructiveDepTyPred : {opts : LayoutOpts} ->
                             ConstructiveDepTyPredResultList asl fbs -> Gen0 $ Doc opts
printConstructiveDepTyPred results = printAny $ constructiveDepTyPredItems results

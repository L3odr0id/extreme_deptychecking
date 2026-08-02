module Printers

import Data.Fin
import Test.DepTyCheck.Gen
import Text.PrettyPrint.Bernardy

import Common
import Pretty
import SafeSelect

%default total

boolPredItems : {bs : BsList} -> BoolPredResultList as bs -> List String
boolPredItems []                    = []
boolPredItems (BPR fb _ :: results) = finValue fb (index bs fb) :: boolPredItems results

simpleDepTyPredItems : {bs : BsList} -> SimpleDepTyPredResultList as bs -> List String
simpleDepTyPredItems []                       = []
simpleDepTyPredItems (SDTPR fin _ :: results) = finValue fin (index bs fin) :: simpleDepTyPredItems results

compValuesItems : {as : AList} -> {bs : BsList} -> CompValuesResultList as bs -> List String
compValuesItems [] = []
compValuesItems {as = a :: _} (MkCompValues fin :: results) =
  noFinValue (index (findCompatible a bs) fin) :: compValuesItems results

funcPredItems : {as : AList} -> {bs : BsList} -> FuncPredResultList as bs -> List String
funcPredItems [] = []
funcPredItems {as = a :: _} (MkFuncPred fin' :: results) =
  let fin = index (goodFins a bs) fin'
  in finValue fin (index bs fin) :: funcPredItems results

depTyPredItems : DepTyPredResultList as bs -> List String
depTyPredItems []                                     = []
depTyPredItems (MkDepTyPred _ _ finalFinB :: results) = filteredFinValue finalFinB :: depTyPredItems results

export
printBoolPred : {opts : LayoutOpts} -> {bs : BsList} ->
                BoolPredResultList as bs -> Gen0 $ Doc opts
printBoolPred {bs} results = printAny $ boolPredItems {bs} results

export
printSimpleDepTyPred : {opts : LayoutOpts} -> {bs : BsList} ->
                       SimpleDepTyPredResultList as bs -> Gen0 $ Doc opts
printSimpleDepTyPred {bs} results = printAny $ simpleDepTyPredItems {bs} results

export
printCompValues : {opts : LayoutOpts} -> {as : AList} -> {bs : BsList} ->
                  CompValuesResultList as bs -> Gen0 $ Doc opts
printCompValues {as} {bs} results = printAny $ compValuesItems {as} {bs} results

export
printFuncPred : {opts : LayoutOpts} -> {as : AList} -> {bs : BsList} ->
                FuncPredResultList as bs -> Gen0 $ Doc opts
printFuncPred {as} {bs} results = printAny $ funcPredItems {as} {bs} results

export
printDepTyPred : {opts : LayoutOpts} ->
                 DepTyPredResultList as bs -> Gen0 $ Doc opts
printDepTyPred results = printAny $ depTyPredItems results

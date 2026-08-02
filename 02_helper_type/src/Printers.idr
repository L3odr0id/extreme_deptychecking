module Printers

import Data.Fin
import Test.DepTyCheck.Gen
import Text.PrettyPrint.Bernardy

import Common
import Pretty
import HelperType

%default total

finsItems : FinsList n -> List String
finsItems []        = []
finsItems (f :: fs) = show (finToNat f) :: finsItems fs

fourGroupItems : FourGroups n -> List String
fourGroupItems (MkFour a b c d) =
  [ renderList (finsItems a)
  , renderList (finsItems b)
  , renderList (finsItems c)
  , renderList (finsItems d)
  ]

export
printNaivePartition : {opts : LayoutOpts} ->
                      NaivePartition src -> Gen0 $ Doc opts
printNaivePartition (MkNaive buckets _) = printAny $ fourGroupItems buckets

export
printHelperPartition : {opts : LayoutOpts} ->
                       HelperPartition src steps -> Gen0 $ Doc opts
printHelperPartition (MkHelper {buckets} _) = printAny $ fourGroupItems buckets

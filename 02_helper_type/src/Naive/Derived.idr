module Naive.Derived

import public HelperType

import Deriving.DepTyCheck.Gen

%default total

%logging "deptycheck.derive" 20

HelperType.genNaivePartition = deriveGen

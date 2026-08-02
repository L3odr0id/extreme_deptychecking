module DepTyPred.Derived

import public SafeSelect

import Deriving.DepTyCheck.Gen

%default total

%logging "deptycheck.derive" 20

SafeSelect.genDepTyPredResults = deriveGen

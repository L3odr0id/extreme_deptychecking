module DepTyPred.Derived

import public ConstructivePredicate

import Deriving.DepTyCheck.Gen

%default total

%logging "deptycheck.derive" 20

ConstructivePredicate.genDepTyPredResultList = deriveGen

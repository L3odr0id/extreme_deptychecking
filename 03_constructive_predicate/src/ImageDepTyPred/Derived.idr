module ImageDepTyPred.Derived

import public ConstructivePredicate

import Deriving.DepTyCheck.Gen

%default total

%logging "deptycheck.derive" 20

ConstructivePredicate.genImageDepTyPredResultList = deriveGen

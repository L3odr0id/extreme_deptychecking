module FuncPred.Derived

import public ConstructivePredicate

import Deriving.DepTyCheck.Gen

%default total

%logging "deptycheck.derive" 20

ConstructivePredicate.genFuncPredResultList = deriveGen

module FilteredFins.Derived

import public ConstructivePredicate

import Deriving.DepTyCheck.Gen

%default total

%logging "deptycheck.derive" 20

ConstructivePredicate.genFilteredFinsResultList = deriveGen

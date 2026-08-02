module CompValues.Derived

import public SafeSelect

import Deriving.DepTyCheck.Gen

%default total

%logging "deptycheck.derive" 20

SafeSelect.genCompValuesResults = deriveGen

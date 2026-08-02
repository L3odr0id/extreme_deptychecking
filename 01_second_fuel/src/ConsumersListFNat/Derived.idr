module ConsumersListFNat.Derived

import public SecondFuel

import Deriving.DepTyCheck.Gen

%default total

%logging "deptycheck.derive" 20

SecondFuel.genConsumersListFNat = deriveGen

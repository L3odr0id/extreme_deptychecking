module Pretty

import Data.Fin
import Test.DepTyCheck.Gen
import Text.PrettyPrint.Bernardy

import Common

%default total

public export
Show A where
  show MkA1 = "A1"
  show MkA2 = "A2"
  show MkA3 = "A3"
  show MkA4 = "A4"

public export
Show B where
  show MkB1 = "B1"
  show MkB2 = "B2"
  show MkB3 = "B3"
  show MkB4 = "B4"

public export
finValue : Fin n -> B -> String
finValue fin value = "{f: " ++ show (finToNat fin) ++ ", v: " ++ show value ++ "}"

public export
noFinValue : B -> String
noFinValue value = "{f: no, v: " ++ show value ++ "}"

public export
filteredFinValue : Fin n -> String
filteredFinValue fin = "{f': " ++ show (finToNat fin) ++ "}"

public export
renderList : List String -> String
renderList []        = "[]"
renderList (x :: xs) = "[" ++ x ++ renderTail xs
  where
    renderTail : List String -> String
    renderTail []        = "]"
    renderTail (x :: xs) = ", " ++ x ++ renderTail xs

export
printAny : {opts : LayoutOpts} -> List String -> Gen0 $ Doc opts
printAny strs = pure $ line $ renderList strs

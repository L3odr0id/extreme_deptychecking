# Extreme DepTyCheck patterns

The same domain task can be solved by using very different dependent types.
The ways to implement dependent types differ in how comfortable they are for a developer to write,
how fast DepTyCheck can **derive** a generator, and how fast that generator can **produce** values.

This repository presents design patterns representing these trade-offs,
featuring minimal examples, benchmarks, and some practical rules and debugging tips.

## Rules of DepTyChecking

1. Do not use hand-written generators.
2. Do not use hand-written generators.
3. Do not use implicits in type indexes. If you accidentally fail to pass a value, it will break the entire generation process. (It is acceptable to use implicits only for types that are heavily used outside the generator.)
4. Do not invent complex structures. DepTyCheck works best with flat lists. Represent your domain using them.
5. Do not design the model in isolation. Real specifications are printer-centric. Structure your model so that it can be easily printed.
6. Do not use functions by default. Model your specification using dependent types first.
7. Do not hesitate to add auxiliary arguments to constructors. Even if they aren't needed for value generation, they can be used to pattern match on them later.
8. If this is your first time using DepTyCheck, see [pil-fun](https://github.com/buzden/deptycheck/tree/master/examples/pil-fun) implementation for reference.

## Debugging tips

- If derivation or generation suspiciously freezes, try converting complex dependent types into standard functions and replace predicates with So + Bool functions.
- Never leave anonymous arguments in constructors. Giving every argument an explicit name makes reading derivation logs and tracking arguments order significantly easier.
- If you are unsure whether a specific type can actually be constructed, try instantiating its value manually. Use auto implicit arguments so the compiler handles the routine boilerplate for you.
- When verifying if a specific dependent type value can actually be constructed, use auto implicit auxiliary arguments to manually inject values for testing.
- If derivation hangs on a specific constructor for an unusually long time, do not wait for it to finish. Cancel the process and begin debugging that constructor.
- If nothing works, recreate a minimal, bare-bones version of the model in a clean test project. Verify that basic generation works, then add features back step-by-step.

## Notes

All example types in this repo are sized to work with **fuel 4**, and all generators in this repo are run with fuel 4 by default.
Other fuel values are possible, but fuel 4 was chosen as a sensible default based on practical experience.

## Patterns

### [`00_safe_select`](00_safe_select/) — shrink the choice set before picking

Instead of picking into the full list and proving compatibility afterward, narrow the search space to only valid candidates before choosing a `Fin`.

**Task:** for each `a`, pick an index into `bs` that is compatible with `a`.

**BoolPred** — simplest pick: `Fin` + boolean `So (isCompatible …)`:

```idris
data BoolPredResult : A -> BsList -> Type where
  BPR : (fb : Fin bs.length) -> (pred : So (isCompatible a (index bs fb))) -> BoolPredResult a bs
```

**SimpleDepTyPred** — `Fin` into the full list + `IsCompatible` proof:

```idris
data SimpleDepTyPredResult : A -> BsList -> Type where
  SDTPR : (fb : Fin bs.length) -> IsCompatible a (index bs fb) -> SimpleDepTyPredResult a bs
```

**CompValues** — filter to compatible values, then `Fin` into that list:

```idris
data CompValuesResult : A -> BsList -> Type where
  MkCompValues : (fb' : Fin (findCompatible a bs).length) -> CompValuesResult a bs
```

**FuncPred** — filter to fins of compatible values via a boolean check, then `Fin` into that:

```idris
data FuncPredResult : A -> BsList -> Type where
  MkFuncPred : (fb' : Fin (goodFins a bs).length) -> FuncPredResult a bs
```
- ✅ Fastest and most comfortable solution.

**DepTyPred** — filter compatible values with fins using dependent types, then `Fin` into the kept fins:

```idris
data DepTyPredResult : A -> BsList -> Type where
  MkDepTyPred : {0 goodBFins : FinsList bs.length} ->
                (0 filtered : FilteredCompatibleFins a bs goodBFins) ->
                (finalFinB : Fin goodBFins.length) ->
                DepTyPredResult a bs
```
- ✅ Uses only dependent types.

### [`01_second_fuel`](01_second_fuel/) — a `Nat` used like extra fuel

Sometimes generators for even simple recursive structures are not total.
Index a recursive structure by `Nat` so generation can follow the `Nat` without exhausting primary model fuel.

**Task:** build a list whose length is tied to a `Fin` index (each step consumes one unit).

**ConsumersListFin** — length is determined solely by the `Fin`:

```idris
data ConsumersListFin : Fin (S n) -> Type where
  Nil  : ConsumersListFin FZ
  (::) : FinConsumer f -> ConsumersListFin (weaken i) -> ConsumersListFin (FS i)
```
- ⚠️ Does not generate values for `Fin` > `Fuel` because it consumes fuel on each element.

**ConsumersListFNat** — uses a separate `Nat` length, which works like an alternative fuel:

```idris
data ConsumersListFNat : Fin (S n) -> Nat -> Type where
  Nil  : ConsumersListFNat FZ Z
  (::) : FinConsumer f -> ConsumersListFNat (weaken i) k -> ConsumersListFNat (FS i) (S k)
```
- ✅ Always works.

### [`02_helper_type`](02_helper_type/) — generate using an additional utility type

Replace a hard-to-generate invariant with a helper type that builds a correct value step by step.
The helper type does not represent the domain logic, it just helps generator to build values you need.

**Task:** split a source `FinsList` into exactly four groups that form a partition of it.

**Naive** — create four lists + a permutation proof at once:

```idris
data NaivePartition : {n : Nat} -> (src : FinsList n) -> Type where
  MkNaive : (buckets : FourGroups n) ->
            (0 ok : IsPermutation src (flat4 buckets)) ->
            NaivePartition src
```

**Helper** — walk the source once (`FillInto4`); each step puts one element into a `Fin 4` bucket.
It also uses the `second-fuel` pattern: a `Fin` index paired with an additional `Nat` (`steps`),
which must be given as `src.length`:

```idris
data FillInto4 : {n : Nat} ->
                 (src : FinsList n) ->
                 (pre : FourGroups n) ->
                 (left : Fin (S src.length)) ->
                 (steps : Nat) ->
                 (mid : FourGroups n) ->
                 Type where
  FEnd : FillInto4 src pre FZ 0 pre
  FPut : {i : Fin src.length} ->
         {k : Nat} ->
         (recur : FillInto4 src pre (weaken i) k mid) ->
         (target : Fin 4) ->
         FillInto4 src pre (FS i) (S k) (addToBucket mid target (index src i))
```

### [`03_constructive_predicate`](03_constructive_predicate/) — how compatibility is witnessed

Compare ways to declare predicate and fin.

**Task:** for each `a`, pick a compatible element of `bs` (or a fin-tagged view of it).

**DepTyPred** — naive: `Fin` + inductive `IsCompatible`:

```idris
data DepTyPredResult : A -> BsList -> Type where
  DTPR : (fb : Fin bs.length) -> (pred : IsCompatible a (index bs fb)) -> DepTyPredResult a bs
```

**FuncPred** — `goodFins` boolean filter, then `Fin` into that:

```idris
data FuncPredResult : A -> BsList -> Type where
  MkFuncPred : (fb' : Fin (goodFins a bs).length) -> FuncPredResult a bs
```

**FilteredFins** — constructive filter of `bs`, then pick into kept fins:

```idris
data FilteredFinsResult : A -> BsList -> Type where
  MkFilteredFins : (a : A) ->
                   {0 goodBFins : FinsList bs.length} ->
                   (0 filtered : FilteredCompatibleFins a bs goodBFins) ->
                   (finalFinB : Fin goodBFins.length) ->
                   FilteredFinsResult a bs
```

**ConstructiveDepTyPred** — compatibility witness + filter over a pairs fin ** elem:

```idris
data ConstructiveDepTyPredResult : A -> FinB2List fullBs -> Type where
  CDTPR : {0 b : B} -> {0 goodBFins : FinsList fullBs} ->
          (0 pred : IsCompatible a b) ->
          (0 filteredAsHelper : FilteredBFinss b finbs goodBFins) ->
          (finalFinB : Fin goodBFins.length) ->
          ConstructiveDepTyPredResult a finbs
```

## Benchmarks

```bash
./scripts/run_benchmarks.sh                  # all packages
./scripts/run_benchmarks.sh 02_helper_type   # one package
```

Results are written under `results/` as JSON and summarized as tables (also into `$GITHUB_STEP_SUMMARY` in CI).

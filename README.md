# Extreme DepTyChecking

The same domain task can be solved by using very different dependent types.
The ways to implement dependent types differ in how comfortable they are for a developer to write,
how fast DepTyCheck can **derive** a generator, and how fast that generator can **produce** values.

This repository presents design patterns representing these trade-offs,
featuring minimal examples, benchmarks, and some practical rules and debugging tips.

## Rules of Extreme DepTyChecking

1. Do not use hand-written generators.
2. Do not use hand-written generators.
3. Do not leave implicits unhandled. Make sure that implicit indexes of all types are passed successfully (or pass them explicitly). Otherwise they may be just generated and fail the whole generation process.
4. Do not invent complex structures. DepTyCheck works best with flat lists. Represent your domain using them.
5. Do not design the specification in isolation. Real specifications are printer-centric. Structure your model so that it can be easily printed.
6. Do not use functions by default. Model your specification using dependent types first.
7. Do not hesitate to add auxiliary arguments to constructors. Even if they aren't needed for value generation, they can be used to pattern match on them later.
8. If this is your first time using DepTyCheck, you have to see [pil-fun](https://github.com/buzden/deptycheck/tree/master/examples/pil-fun) implementation for reference.

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
See the sources to understand how to declare generators for the types presented here and how to run them.

## Patterns

### [`00_safe_select`](00_safe_select/) — shrink the choice set before picking

**Task:** There are lists of `A` and `B`. For each `A`, pick an index into `Bs` that is compatible with `A`.
This is a very common task when writing specifications for DepTyCheck.

All examples follow the same pattern: a list of `A`s is given as an index, and for each value of `A` a `Fin` into `Bs` is generated.

The most trivial way to solve the task is to declare a function `isCompatible` and use it with `So` to create a filter predicate.

```idris
isCompatible : A -> B -> Bool

data BoolPredResult : A -> BsList -> Type where
  BPR : (fb : Fin bs.length) -> (pred : So (isCompatible a (index bs fb))) -> BoolPredResult a bs
```

It is preferable to work with dependent types rather than functions.
So it is better to declare a predicate `IsCompatible` and use it to filter incompatible options.

```idris
data IsCompatible : A -> B -> Type

data SimpleDepTyPredResult : A -> BsList -> Type where
  SDTPR : (fb : Fin bs.length) -> IsCompatible a (index bs fb) -> SimpleDepTyPredResult a bs
```

**Idea:** To get much better generation performance, instead of picking into the full list and proving compatibility afterward, narrow the search space to only valid candidates before choosing a `Fin`.

The naive approach to make generation faster is to declare a function that keeps only values compatible with a given `A`, then choose a `Fin` into that list.
The downside of this approach is that we get the compatible value of `B`, but not its index in the original list.

```idris
findCompatible : A -> (allBs : BsList) -> BsList

data CompValuesResult : A -> BsList -> Type where
  MkCompValues : (fb' : Fin (findCompatible a bs).length) -> CompValuesResult a bs
```

To preserve the original fins, a `goodFins` function can be declared. It should return the fins of `B`s that are compatible with a given `A`.
Then another `Fin` into that `FinsList` can be generated to choose any fin of a compatible `B`. This solution gives the best derivation and generation performance.

```idris
goodFins : A -> (bs : BsList) -> FinsList bs.length

data FuncPredResult : A -> BsList -> Type where
  MkFuncPred : (fb' : Fin (goodFins a bs).length) -> FuncPredResult a bs
```

It is also possible to solve this task using only dependent types.
`FilteredCompatibleFins` can be declared to take a given `A` and `Bs` list, and expose as a generated index the list of fins into `Bs` that are compatible with that `A`.

```idris
data FilteredCompatibleFins : A -> (bs : BsList) -> FinsList bs.length -> Type

data DepTyPredResult : A -> BsList -> Type where
  MkDepTyPred : {0 goodBFins : FinsList bs.length} ->
                (0 filtered : FilteredCompatibleFins a bs goodBFins) ->
                (finalFinB : Fin goodBFins.length) ->
                DepTyPredResult a bs
```

### [`01_second_fuel`](01_second_fuel/) — a `Nat` used like extra fuel

Sometimes generators for even recursive structures are not total.
This happens when derivator can't prove that there is a decreasing index.
Such a recursive structure can be indexed by `Nat` so generation can follow the `Nat` without exhausting primary model fuel.

**Task:** build a list whose length is tied to a `Fin` index (each step consumes one unit).

In the trivial implementation, length is determined solely by the `Fin`.
It uses `weaken` so that `Fin n` keeps its `n` across all iterations.
However, it **does not generate** values for `Fin` > `Fuel`, because it consumes fuel on each element.
Without `weaken`, such a structure would not consume fuel.

```idris
data ConsumersListFin : Fin (S n) -> Type where
  Nil  : ConsumersListFin FZ
  (::) : FinConsumer f -> ConsumersListFin (weaken i) -> ConsumersListFin (FS i)
```

To work with `weaken`, the type can be indexed by a separate `Nat` length, which acts as alternative fuel.
It is crucial that this `Nat` equals the size of the `Fin`.

```idris
data ConsumersListFNat : Fin (S n) -> Nat -> Type where
  Nil  : ConsumersListFNat FZ Z
  (::) : FinConsumer f -> ConsumersListFNat (weaken i) k -> ConsumersListFNat (FS i) (S k)
```

### [`02_helper_type`](02_helper_type/) — use an additional utility type

There is a common task in developing specifications for DepTyCheck when you need to make a predicate on some large dependent type.
It's always better to break your structure into smaller components and create small predicates to validate them.
But sometimes you need a predicate over a large structure.

**Task:** for example, split a given `FinsList` into exactly four groups that form a partition of it.

The naive approach is to implement a data type holding four lists and a permutation proof for these groups.
A generator for `NaivePartition` will not produce any values.

```idris
record FourGroups (n : Nat) where
  constructor MkFour
  g0 : FinsList n
  g1 : FinsList n
  g2 : FinsList n
  g3 : FinsList n

flat4 : FourGroups n -> FinsList n
flat4 (MkFour a b c d) = a ++ b ++ c ++ d

data IsPermutation : FinsList n -> FinsList n -> Type where

data NaivePartition : {n : Nat} -> (src : FinsList n) -> Type where
  MkNaive : (buckets : FourGroups n) ->
            (0 ok : IsPermutation src (flat4 buckets)) ->
            NaivePartition src
```

To solve the problem, replace a hard-to-generate invariant with a helper type that builds a correct value step by step.
The helper type does not represent the domain logic.
It just helps the generator build the values you need.

`FillInto4` walks the source once.
Each step puts one element into a `Fin 4` bucket.
It also uses the second-fuel pattern: a `Fin` index paired with an additional `Nat` (`steps`), which must be given as `src.length`.

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

### [`03_constructive_predicate`](03_constructive_predicate/) — place predicate before `Fin` using only dependent types

Constructive predicates are valuable when the desirable arguments order is unknown, so depthcheck determine it.
While the resulting order may not be optimal, the selection process is entirely automated, which is very comfortable for the developer.

Here we compare ways to declare a predicate and a `Fin`.

**Task:** for each given `A`, pick a compatible element of the given `Bs`.

The naive approach is to generate a `Fin` first and then check compatibility using a predicate written in dependent types.

```idris
data DepTyPredResult : A -> BsList -> Type where
  DTPR : (fb : Fin bs.length) -> (pred : IsCompatible a (index bs fb)) -> DepTyPredResult a bs
```

The best performing approach is to select the `Fin`s of compatible `B`s using functions and then generate a `Fin` into them.
But this approach does not use dependent types.

```idris
data FuncPredResult : A -> BsList -> Type where
  MkFuncPred : (fb' : Fin (goodFins a bs).length) -> FuncPredResult a bs
```

The idea of filtering the list before `Fin` generation can be written using only dependent types.
The type `FilteredCompatibleFins` takes a given `A` and the initial `Bs` and returns a generated `FinsList` of `B`s compatible with that `A`.
Then a `Fin` can be generated into the filtered list.

This approach derives and generates values much more slowly than `FuncPredResult`, but it is implemented using dependent types almost entirely.

```idris
||| Proof that `A` and `B` are not compatible with each other
data NotCompatible : A -> B -> Type

weakenFins : FinsList n -> FinsList (S n)
weakenFins []      = []
weakenFins (f::fs) = FS f :: weakenFins fs

data FilteredCompatibleFins : A -> (bs : BsList) -> FinsList bs.length -> Type where
  Nil  : FilteredCompatibleFins a [] []
  Keep : IsCompatible a b ->
         FilteredCompatibleFins a bs rest ->
         FilteredCompatibleFins a (b :: bs) (FZ :: weakenFins rest)
  Drop : NotCompatible a b ->
         FilteredCompatibleFins a bs rest ->
         FilteredCompatibleFins a (b :: bs) (weakenFins rest)

data FilteredFinsResult : A -> BsList -> Type where
  MkFilteredFins : (a : A) ->
                   {0 goodBFins : FinsList bs.length} ->
                   (0 filtered : FilteredCompatibleFins a bs goodBFins) ->
                   (finalFinB : Fin goodBFins.length) ->
                   FilteredFinsResult a bs
```

There is also one interesting idea. If `IsCompatible a b` is very heavy, that argument can be generated first to obtain a generated index `b`.
This `b` can then be used as an image to compare with other `B`s when filtering those compatible with a given `A`.
Such image doesn't have to be the exact type of `B`, it can be a simplified holder of some most important properties of `B`.
Although this doesn't make much sense in the presented trivial example, such an idea may be useful in more complex structures.

```idris
data FinB2 : Nat -> Type where
  MkFinB2 : Fin n -> B -> FinB2 n

data FinB2List : Nat -> Type

data FilteredBFinss : B -> (bs : FinB2List fullBs) -> FinsList fullBs -> Type

data ImageDepTyPredResult : A -> FinB2List fullBs -> Type where
  IDTPR : {0 b : B} -> {0 goodBFins : FinsList fullBs} ->
          (0 pred : IsCompatible a b) ->
          (0 filteredAsHelper : FilteredBFinss b finbs goodBFins) ->
          (finalFinB : Fin goodBFins.length) ->
          ImageDepTyPredResult a finbs

GenOrderTuning "IDTPR".dataCon where
  isConstructor = itIsConstructor
  deriveFirst _ _ = [`{pred}, `{b}, `{filteredAsHelper}, `{goodBFins}, `{finalFinB}]
```

## Benchmarks

```bash
./scripts/run_benchmarks.sh                  # all packages
./scripts/run_benchmarks.sh 02_helper_type   # one package
```

Results are written under `results/` as JSON and summarized as tables (also into `$GITHUB_STEP_SUMMARY` in CI).

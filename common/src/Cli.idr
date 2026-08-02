module Cli

import Data.Fuel
import Data.List.Lazy
import Data.String
import System
import System.GetOpts
import System.Random.Pure.StdGen

import Test.DepTyCheck.Gen
import Text.PrettyPrint.Bernardy

%default total

public export
data Config : (Type -> Type) -> Type -> Type where
  MkConfig : (testsCnt : m Nat) ->
             (modelFuel : m Fuel) ->
             (selected : m modeTy) ->
             (size : m Nat) ->
             Config m modeTy

public export
(.testsCnt) : Config m modeTy -> m Nat
(.testsCnt) (MkConfig tc _ _ _) = tc

public export
(.modelFuel) : Config m modeTy -> m Fuel
(.modelFuel) (MkConfig _ mf _ _) = mf

public export
(.selected) : Config m modeTy -> m modeTy
(.selected) (MkConfig _ _ md _) = md

public export
(.size) : Config m modeTy -> m Nat
(.size) (MkConfig _ _ _ s) = s

public export
Cfg : Type -> Type
Cfg modeTy = Config Prelude.id modeTy

public export
allNothing : Config Maybe modeTy
allNothing = MkConfig Nothing Nothing Nothing Nothing

public export
mergeCfg : (forall a. m a -> n a -> k a) ->
           Config m modeTy -> Config n modeTy -> Config k modeTy
mergeCfg f (MkConfig tc mf md s) (MkConfig tc' mf' md' s') =
  MkConfig (f tc tc') (f mf mf') (f md md') (f s s')

covering
mapSuccessful : (a -> Maybe b) -> Stream a -> Stream b
mapSuccessful f (x :: xs) = case f x of
  Just y  => y :: mapSuccessful f xs
  Nothing => mapSuccessful f xs

covering
for_ : LazyList a -> (a -> IO ()) -> IO ()
for_ [] _ = pure ()
for_ (x :: xs) f = f x >> for_ xs f

covering
printValue : (a -> Gen0 (Doc $ Opts 152)) -> a -> IO ()
printValue printer value = do
  Just doc <- pick $ printer value
    | Nothing => die "The printer could not produce a value."
  putStr $ render (Opts 152) doc

export covering
run : Nat -> (a -> Gen0 (Doc $ Opts 152)) -> Gen0 a -> IO ()
run count printer generator = do
  seed <- the (IO StdGen) initSeed
  let values = take (limit count) $ mapSuccessful id $ unGenTryAll seed generator
  for_ values $ printValue printer

withTestsCnt : Nat -> Config Maybe modeTy
withTestsCnt n = MkConfig (Just n) Nothing Nothing Nothing

withModelFuel : Fuel -> Config Maybe modeTy
withModelFuel f = MkConfig Nothing (Just f) Nothing Nothing

withSelected : modeTy -> Config Maybe modeTy
withSelected md = MkConfig Nothing Nothing (Just md) Nothing

withSize : Nat -> Config Maybe modeTy
withSize n = MkConfig Nothing Nothing Nothing (Just n)

export
parseTestsCount : String -> Either String (Config Maybe modeTy)
parseTestsCount str = case parsePositive str of
  Just n  => Right $ withTestsCnt n
  Nothing => Left "can't parse given count of values"

export
parseModelFuel : String -> Either String (Config Maybe modeTy)
parseModelFuel str = case parsePositive str of
  Just n  => Right $ withModelFuel $ limit n
  Nothing => Left "can't parse given model fuel"

export
parseSize : String -> Either String (Config Maybe modeTy)
parseSize str = case parsePositive str of
  Just n  => Right $ withSize n
  Nothing => Left "can't parse given size"

export
parseGeneratorMode : (String -> Either String modeTy) ->
                     String -> Either String (Config Maybe modeTy)
parseGeneratorMode parseMode str = do
  parsedMode <- parseMode str
  Right $ withSelected parsedMode

export
standardOpts : (String -> Either String modeTy) ->
               (modeHelp : String) ->
               List (OptDescr (Config Maybe modeTy))
standardOpts parseMode modeHelp =
  [ MkOpt ['n'] ["values-count"]
      (ReqArg' parseTestsCount " ")
      "Sets the count of values to generate (default: 10)."
  , MkOpt [] ["model-fuel"]
      (ReqArg' parseModelFuel " ")
      "Sets how much fuel there is for generation of the model (default: 4)."
  , MkOpt ['m'] ["mode"]
      (ReqArg' (parseGeneratorMode parseMode) modeHelp)
      "Sets the generator mode."
  , MkOpt ['s'] ["size"]
      (ReqArg' parseSize " ")
      "Sets the input size (default: 10)."
  ]

tail' : List a -> List a
tail' []        = []
tail' (_ :: xs) = xs

export
parseCommandLine : List (OptDescr (Config Maybe modeTy)) ->
                   Cfg modeTy ->
                   List String ->
                   Either String (Cfg modeTy)
parseCommandLine cliOpts defaultConfig args = case getOpt Permute cliOpts $ tail' args of
  MkResult options [] [] [] => do
    let overrides = foldl (mergeCfg (\x, y => x <|> y)) allNothing options
    let cfg = mergeCfg (\override, fallback => fromMaybe fallback override) overrides defaultConfig
    Right cfg
  MkResult {errors = errors@(_ :: _), _}        => Left $ "argument parse errors: " ++ show errors
  MkResult {unrecognized = options@(_ :: _), _} => Left $ "unrecognized options: " ++ show options
  MkResult {nonOptions, _}                      => Left $ "unrecognized arguments: " ++ show nonOptions

export covering
mainWith : (usageHeader : String) ->
           (parseMode : String -> Either String modeTy) ->
           (modeHelp : String) ->
           (defaultConfig : Cfg modeTy) ->
           (runSelected : Cfg modeTy -> IO ()) ->
           IO ()
mainWith usageHeader parseMode modeHelp defaultConfig runSelected = do
  let cliOpts = standardOpts parseMode modeHelp
  let usage = usageInfo usageHeader cliOpts
  args <- getArgs
  Right cfg <- pure $ parseCommandLine cliOpts defaultConfig args | Left error => die $ error ++ "\n" ++ usage
  runSelected cfg

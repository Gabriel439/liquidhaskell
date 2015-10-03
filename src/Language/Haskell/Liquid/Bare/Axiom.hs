module Language.Haskell.Liquid.Bare.Axiom (makeAxiom) where

import CoreSyn
import DataCon
import Id
import Name
import Type hiding (isFunTy)
import Var

import Prelude hiding (mapM)
import Control.Arrow ((&&&))
import Control.Applicative ((<$>), (<*>))
import Control.Monad hiding (forM, mapM)
import Control.Monad.Error hiding (Error, forM, mapM)
import Control.Monad.State hiding (forM, mapM)
import Data.Bifunctor
import Data.Maybe
import Data.Char (toUpper)
import Data.Monoid
import Data.Traversable (forM, mapM)
import Text.PrettyPrint.HughesPJ (text)
import Text.Parsec.Pos (SourcePos)

import qualified Data.List as L

import qualified Data.HashMap.Strict as M
import qualified Data.HashSet        as S

<<<<<<< HEAD
import Language.Fixpoint.Misc (mlookup, sortNub, snd3, traceShow)
=======
import Language.Fixpoint.Misc (mlookup, sortNub, snd3)
>>>>>>> 9d57e783384d170e81e62fb4ad116c554d60f458
import Language.Fixpoint.Names
import Language.Fixpoint.Types (Expr(..))
import Language.Fixpoint.Sort (isFirstOrder)

import qualified Language.Fixpoint.Types as F

import Language.Haskell.Liquid.CoreToLogic
import Language.Haskell.Liquid.Misc
import Language.Haskell.Liquid.GhcMisc (getSourcePos, getSourcePosE, sourcePosSrcSpan, isDataConId)
import Language.Haskell.Liquid.RefType (dataConSymbol, generalize, ofType, uRType, typeSort)
import Language.Haskell.Liquid.Types
import Language.Haskell.Liquid.Bounds
<<<<<<< HEAD
import Language.Haskell.Liquid.WiredIn
=======
>>>>>>> 9d57e783384d170e81e62fb4ad116c554d60f458

import qualified Language.Haskell.Liquid.Measure as Ms

import Language.Haskell.Liquid.Bare.Env
import Language.Haskell.Liquid.Bare.Misc       (simpleSymbolVar, hasBoolResult)
import Language.Haskell.Liquid.Bare.Expand
import Language.Haskell.Liquid.Bare.Lookup
import Language.Haskell.Liquid.Bare.OfType
import Language.Haskell.Liquid.Bare.Resolve
import Language.Haskell.Liquid.Bare.RefToLogic

<<<<<<< HEAD


=======
>>>>>>> 9d57e783384d170e81e62fb4ad116c554d60f458
makeAxiom :: LogicMap -> [CoreBind] -> GhcSpec -> Ms.BareSpec -> LocSymbol 
          -> BareM ((Symbol, Located SpecType), [(Var, Located SpecType)])
makeAxiom lmap cbs _ _ x
  = case filter ((val x `elem`) . map (dropModuleNames . simplesymbol) . binders) cbs of
<<<<<<< HEAD
    (NonRec v def:_)   -> return (traceShow ("AXIOMATIZE NonRec\n" ++ show def) (val x, makeType v), [])
    (Rec [(v, def)]:_) -> return (traceShow ("AXIOMATIZE Rec   \n" ++ show def) (val x, makeType v), [])
=======
    (NonRec v def:_)   -> return ((val x, makeType v), [])
    (Rec [(v, def)]:_) -> return ((val x, makeType v), [])
>>>>>>> 9d57e783384d170e81e62fb4ad116c554d60f458
    _                  -> throwError $ mkError "Cannot extract measure from haskell function"
  where
    binders (NonRec x _) = [x]
    binders (Rec xes)    = fst <$> xes

<<<<<<< HEAD
    _coreToDef' x v def = case runToLogic lmap mkError $ coreToDef x v def of
                            Left l  -> return     l
                            Right e -> throwError e
=======
    coreToDef' x v def = case runToLogic lmap mkError $ coreToDef x v def of
                           Left l  -> return     l
                           Right e -> throwError e
>>>>>>> 9d57e783384d170e81e62fb4ad116c554d60f458

    mkError :: String -> Error
    mkError str = ErrHMeas (sourcePosSrcSpan $ loc x) (val x) (text str)

    makeType v = x{val = axiomType $ varType v}


axiomType :: (F.Reftable r) => Type -> RRType r
<<<<<<< HEAD
axiomType τ = fromRTypeRep $ t{ty_res = res, ty_args = [], ty_binds = [], ty_refts = []}  
  where 
    t    = toRTypeRep $ ofType τ 
    args = dropWhile isClassType $ ty_args t
    res  = mkType args $ ty_res t

    mkType []     tr = tr 
    mkType (t:ts) tr = arrowType t $ mkType ts tr
=======
axiomType τ = fromRTypeRep $ t{ty_res = res, ty_binds = binds, ty_args = args, ty_refts = refts}
  where 
    t   = toRTypeRep $ ofType τ 
    res = mkResType $ ty_res t
    (binds, args, refts) = unzip3 $ dropWhile (isClassType.snd3) $ zip3 (ty_binds t) (ty_args t) (ty_refts t)
    

    mkResType t 
     | isBool t   = propType
     | otherwise  = t

    propType = undefined
    boolTyCon = undefined 

isBool _ = False


>>>>>>> 9d57e783384d170e81e62fb4ad116c554d60f458

{-
makeMeasureDefinition :: LogicMap -> [CoreBind] -> LocSymbol -> BareM (Measure SpecType DataCon)
makeMeasureDefinition lmap cbs x
  = case filter ((val x `elem`) . map (dropModuleNames . simplesymbol) . binders) cbs of
    (NonRec v def:_)   -> Ms.mkM x (logicType $ varType v) <$> coreToDef' x v def
    (Rec [(v, def)]:_) -> Ms.mkM x (logicType $ varType v) <$> coreToDef' x v def
    _                  -> throwError $ mkError "Cannot extract measure from haskell function"
  where
    binders (NonRec x _) = [x]
    binders (Rec xes)    = fst <$> xes

    coreToDef' x v def = case runToLogic lmap mkError $ coreToDef x v def of
                           Left l  -> return     l
                           Right e -> throwError e

    mkError :: String -> Error
    mkError str = ErrHMeas (sourcePosSrcSpan $ loc x) (val x) (text str)
-}

simplesymbol :: CoreBndr -> Symbol
simplesymbol = symbol . getName

-- | This module contains the code for Incremental checking, which finds the 
--   part of a target file (the subset of the @[CoreBind]@ that have been 
--   modified since it was last checked (as determined by a diff against
--   a saved version of the file. 

module Language.Haskell.Liquid.DiffCheck (slice, save) where

import            Control.Applicative          ((<$>))
import            Data.Algorithm.Diff
import            CoreSyn                      
import            Name
import            SrcLoc  
-- import            Outputable 
import            Var 
import qualified  Data.HashSet                 as S    
import qualified  Data.HashMap.Strict          as M    
import qualified  Data.List                    as L
import            Data.Function                (on)
import            System.Directory             (copyFile, doesFileExist)

import            Language.Fixpoint.Files
import            Language.Haskell.Liquid.GhcInterface
import            Language.Haskell.Liquid.GhcMisc
import            Text.Parsec.Pos              (sourceLine) 
import            Control.Monad(forM)


-------------------------------------------------------------------------
-- Data Types -----------------------------------------------------------
-------------------------------------------------------------------------

data Def  = D { start  :: Int
              , end    :: Int
              , binder :: Var 
              } 
            deriving (Eq, Ord)
              
instance Show Def where 
  show (D i j x) = showPpr x ++ " start: " ++ show i ++ " end: " ++ show j



-- | `slice` returns a subset of the @[CoreBind]@ of the input `target` 
--    file which correspond to top-level binders whose code has changed 
--    and their transitive dependencies.
-------------------------------------------------------------------------
slice :: FilePath -> [CoreBind] -> IO [CoreBind] 
-------------------------------------------------------------------------
slice target cbs
  = do let saved = extFileName Saved target
       ex  <- doesFileExist saved 
       if ex then do is      <- {- tracePpr "INCCHECK: changed lines" <$> -} lineDiff target saved
                     let dfs  = coreDefs cbs
                     forM dfs $ putStrLn . ("INCCHECK: Def " ++) . show 
                     let xs   = diffVars is dfs   
                     putStrLn $ "INCCHECK: Changed Top-Binders" ++ showPpr xs
                     let ys   = dependentVars (coreDeps cbs) (S.fromList xs)
                     putStrLn $ "INCCHECK: Dependent Top-Binders" ++ showPpr ys
                     return   $ filterBinds cbs ys
             else return cbs 

-------------------------------------------------------------------------
filterBinds        :: [CoreBind] -> S.HashSet Var -> [CoreBind]
-------------------------------------------------------------------------
filterBinds cbs ys = filter f cbs
  where 
    f (NonRec x _) = x `S.member` ys 
    f (Rec xes)    = any (`S.member` ys) $ fst <$> xes 

-------------------------------------------------------------------------
coreDefs     :: [CoreBind] -> [Def]
-------------------------------------------------------------------------
coreDefs cbs = L.sort [D l l' x | b <- cbs, let (l, l') = coreDef b, x <- bindersOf b]
coreDef b    = -- tracePpr ("INCCHECK: coreDef " ++ showPpr (bindersOf b)) $ 
               lineSpan $ catSpans b $ bindSpans b 
 
lineSpan (RealSrcSpan sp) = (srcSpanStartLine sp, srcSpanEndLine sp)
lineSpan _                = error "INCCHECK: lineSpan unexpected dummy span in lineSpan"

catSpans b []             = error $ "INCCHECK: catSpans: no spans found for " ++ showPpr b
catSpans b xs             = foldr1 combineSrcSpans xs

bindSpans (NonRec x e)    = getSrcSpan x : exprSpans e
bindSpans (Rec    xes)    = map getSrcSpan xs ++ concatMap exprSpans es
  where 
    (xs, es)              = unzip xes
exprSpans (Tick t _)      = [tickSrcSpan t]
exprSpans (Var x)         = [getSrcSpan x]
exprSpans (Lam x e)       = getSrcSpan x : exprSpans e 
exprSpans (App e a)       = exprSpans e ++ exprSpans a 
exprSpans (Let b e)       = bindSpans b ++ exprSpans e
exprSpans (Cast e _)      = exprSpans e
exprSpans (Case e x _ cs) = getSrcSpan x : exprSpans e ++ concatMap altSpans cs 
exprSpans e               = [] 

altSpans (_, xs, e)       = map getSrcSpan xs ++ exprSpans e


-- coreDefs cbs = mkDefs lxs 
--   where
--     lxs      = coreDefs' cbs
--     -- lxs      = L.sortBy (compare `on` fst) [(line x, x) | x <- xs ]
--     -- xs       = concatMap bindersOf cbs
--     -- line     = sourceLine . getSourcePos 
-- 
-- mkDefs []          = []
-- mkDefs ((l,x):lxs) = case lxs of
--                        []       -> [D l Nothing x]
--                        (l',_):_ -> (D l (Just l') x) : mkDefs lxs
-- 
-- coreDefs' cbs = L.sort [(l, x) | b <- cbs, let (l, l') = coreDef b, x <- bindersOf b]


-------------------------------------------------------------------------
coreDeps  :: [CoreBind] -> Deps
-------------------------------------------------------------------------
coreDeps  = M.fromList . concatMap bindDep 

bindDep b = [(x, ys) | x <- bindersOf b]
  where 
    ys    = S.fromList $ freeVars S.empty b

type Deps = M.HashMap Var (S.HashSet Var)

-------------------------------------------------------------------------
dependentVars :: Deps -> S.HashSet Var -> S.HashSet Var
-------------------------------------------------------------------------
dependentVars d xs = {- tracePpr "INCCHECK: tx changed vars" $ -} 
                     go S.empty $ {- tracePpr "INCCHECK: seed changed vars" -} xs
  where 
    pre            = S.unions . fmap deps . S.toList
    deps x         = M.lookupDefault S.empty x d
    go seen new 
      | S.null new = seen
      | otherwise  = let seen' = S.union seen new
                         new'  = pre new `S.difference` seen'
                     in go seen' new'

-------------------------------------------------------------------------
diffVars :: [Int] -> [Def] -> [Var]
-------------------------------------------------------------------------
diffVars lines defs  = -- tracePpr ("INCCHECK: diffVars lines = " ++ show lines ++ " defs= " ++ show defs) $ 
                       go (L.sort lines) (L.sort defs)
  where 
    go _      []     = []
    go []     _      = []
    go (i:is) (d:ds) 
      | i < start d  = go is (d:ds)
      | i > end d    = go (i:is) ds
      | otherwise    = binder d : go (i:is) ds 

-------------------------------------------------------------------------
-- Diff Interface -------------------------------------------------------
-------------------------------------------------------------------------

-- | `save` creates an .saved version of the `target` file, which will be 
--    used to find what has changed the /next time/ `target` is checked.
-------------------------------------------------------------------------
save :: FilePath -> IO ()
-------------------------------------------------------------------------
save target = copyFile target $ extFileName Saved target


-- | `lineDiff src dst` compares the contents of `src` with `dst` 
--   and returns the lines of `src` that are different. 
-------------------------------------------------------------------------
lineDiff :: FilePath -> FilePath -> IO [Int]
-------------------------------------------------------------------------
lineDiff src dst 
  = do s1      <- getLines src 
       s2      <- getLines dst
       let ns   = diffLines 1 $ getGroupedDiff s1 s2
       putStrLn $ "INCCHECK: diff lines = " ++ show ns
       return ns

diffLines _ []              = []
diffLines n (Both ls _ : d) = diffLines n' d                         where n' = n + length ls
diffLines n (First ls : d)  = [n .. (n' - 1)] ++ diffLines n' d      where n' = n + length ls
diffLines n (Second _ : d)  = diffLines n d 

getLines = fmap lines . readFile

module Eval where

import qualified Data.Set as S

{-@ measure keys @-}
keys :: (Ord k) => [(k, v)] -> S.Set k
keys []       = S.empty
keys (kv:kvs) = (S.singleton (fst kv)) `S.union` (keys kvs)

-- this is fine

{-@ measure okeys  :: [(a, b)] -> (S.Set a)
    okeys ([])     = (Set_empty 0)
    okeys (kv:kvs) = (Set_cup (Set_sng (fst kv)) (okeys kvs))
  @-}

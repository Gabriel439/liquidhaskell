-- |   A first example in equalional reasoning.
-- |  From the definition of append we should be able to
-- |  semi-automatically prove the two axioms.

-- | Note for soundness we need
-- | totallity: all the cases should be covered
-- | termination: we cannot have diverging things into proofs

{-@ LIQUID "--totality" @-}

module Append where

import Equational
import Arrow


data L a = N |  C a (L a) deriving (Eq)

{-@ N :: {v:L a | llen v == 0 && v == N } @-}
{-@ C :: x:a -> xs:L a -> {v:L a | llen v == llen xs + 1 && v == C x xs } @-}

{-@ data L [llen] @-}
{-@ invariant {v: L a | llen v >= 0} @-}

{-@ measure llen :: L a -> Int @-}
llen :: L a -> Int
llen N = 0
llen (C x xs) = 1 + llen xs


append :: L a -> L a -> L a
append N xs        = xs
append (C y ys) xs = C y (append ys xs)


-- | All the followin will be autocatically generated by the definition of append
-- |  and a liquid annotation
-- |
-- |  axiomatize append
-- |

{-@ measure append :: Arrow (L a) (Arrow (L a) (L a)) @-}
{-@ assume append :: xs:L a -> ys:L a -> {v:L a | v == runFun (runFun append xs) ys } @-}

{-@ assume axiom_append_nil :: xs:L a -> {v:Proof | (runFun (runFun append N) xs) == xs} @-}
axiom_append_nil :: L a -> Proof
axiom_append_nil xs = Proof

{-@ assume axiom_append_cons :: x:a -> xs: L a -> ys: L a
          -> {v:Proof | runFun (runFun append (C x xs)) ys == C x (runFun (runFun append xs) ys) } @-}
axiom_append_cons :: a -> L a -> L a -> Proof
axiom_append_cons x xs ys = Proof


-- | Proof 1: N is neutral element

{-@ prop_foo :: xs:L a -> {v: L a | v == runFun (runFun append xs) N } @-}
prop_foo     :: L a -> L a -- (Arrow (L a) (L a))
prop_foo     =  undefined



{-@ prop_nil :: xs:L a -> {v:Proof | (runFun (runFun append xs) N == xs) } @-}
prop_nil     :: Eq a => L a -> Proof
prop_nil N   =  axiom_append_nil N

prop_nil (C x xs) = toProof e1 $ ((
  e1 === e2) pr1
     === e3) pr2
   where
   	e1  = append (C x xs) N
   	pr1 = axiom_append_cons x xs N
   	e2  = C x (append xs N)
   	pr2 = prop_nil xs
   	e3  = C x xs

{-@ prop_app_nil :: ys:L a -> {v:Proof | runFun (runFun append ys) N == ys} @-}
prop_app_nil N =  axiom_append_nil N

prop_app_nil (C x xs)
  = refl (append (C x xs) N)
                                      -- (C x xs) ++ N
      `by` (axiom_append_cons x xs N)
                                      -- == C x (xs ++ N)
      `by` (prop_app_nil xs)
                                      -- == C x xs

-- | Proof 2: append is associative



{-@ prop_assoc :: xs:L a -> ys:L a -> zs:L a
               -> {v:Proof | ( runFun (runFun append (runFun ( runFun append xs) ys)) zs == runFun (runFun append xs) (runFun (runFun append ys) zs))} @-}
prop_assoc :: Eq a => L a -> L a -> L a -> Proof

{-
prop_assoc N ys zs =
  toProof (append (append N ys) zs) $ ((
    append (append N ys) zs === append ys zs)             (axiom_append_nil ys)
                            === append N (append ys zs))  (axiom_append_nil (append ys zs))
-}

prop_assoc N ys zs =
  refl (append (append N ys) zs)
  `by` axiom_append_nil ys             -- == append ys zs
  `by` axiom_append_nil (append ys zs) -- == append N (append ys zs)

prop_assoc (C x xs) ys zs =
  refl e1
    `by` pr1 `by` pr2 `by` pr3 `by` pr4
  where
    e1  = append (append (C x xs) ys) zs
    pr1 = axiom_append_cons x xs ys
    e2  = append (C x (append xs ys)) zs
    pr2 = axiom_append_cons x (append xs ys) zs
    e3  = C x (append (append xs ys) zs)
    pr3 = prop_assoc xs ys zs
    e4  = C x (append xs (append ys zs))
    pr4 = axiom_append_cons x xs (append ys zs)
    e5  = append (C x xs) (append ys zs)
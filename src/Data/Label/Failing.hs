{-| Lenses for getters and updates that can potentially fail with some error
value. Like partial lenses, failing lenses are useful for creating accessor
labels for multi constructor data types where projection and modification of
fields will not always succeed. The error value can be used to report what
caused the failure.
-}

{-# LANGUAGE TypeOperators, TupleSections #-}

module Data.Label.Failing
( Lens
, lens
, get
, modify
, set
, embed

-- * Seemingly total modifications.
, set'
, modify'
)
where

import Data.Label.Poly ((:->))

import qualified Data.Label.Poly  as Poly
import qualified Data.Label.Total as Total

{-# INLINE lens    #-}
{-# INLINE get     #-}
{-# INLINE modify  #-}
{-# INLINE set     #-}
{-# INLINE embed   #-}
{-# INLINE set'    #-}
{-# INLINE modify' #-}

-- | Lens type for situations in which the accessor functions can fail with
-- some error information.

type Lens e f o = Poly.Lens (Either e) f o

-------------------------------------------------------------------------------

-- | Create a lens that can fail from a getter and a modifier that can
-- themselves potentially fail.

lens :: (f -> Either e o)                       -- ^ Getter.
     -> ((o -> Either e i) -> f -> Either e g)  -- ^ Modifier.
     -> Lens e (f -> g) (o -> i)
lens = Poly.lens

-- | Getter for a lens that can fail. When the field to which the lens points
-- is not accessible the getter returns 'Nothing'.

get :: Lens e (f -> g) (o -> i) -> f -> Either e o
get = Poly.get

-- | Modifier for a lens that can fail. When the field to which the lens points
-- is not accessible this function returns 'Left'.

modify :: Lens e (f -> g) (o -> i) -> (o -> i) -> f -> Either e g
modify l m = Poly.modify l (return . m)

-- | Setter for a lens that can fail. When the field to which the lens points
-- is not accessible this function returns 'Left'.

set :: Lens e (f -> g) (o -> i) -> i -> f -> Either e g
set l v = Poly.set l (return v)

-- | Embed a total lens that points to an `Either` field into a lens that might
-- fail.

embed :: (f -> g) :-> (Either e o -> Either e i)
      -> Lens e (f -> g) (o -> i)
embed l = lens (Total.get l)
               (\m -> return . Total.modify l (either Left m))

-------------------------------------------------------------------------------

-- | Like 'modify' but return behaves like the identity function when the field
-- could not be set.

modify' :: Lens e (f -> f) (o -> o) -> (o -> o) -> f -> f
modify' l m f = either (const f) id (modify l m f)

-- | Like 'set' but return behaves like the identity function when the field
-- could not be set.

set' :: Lens e (f -> f) (o -> o) -> o -> f -> f
set' l v f = either (const f) id (set l v f)


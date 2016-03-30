module spec Data.ByteString.Internal where

measure bLength     :: ByteString -> Int
bLength (PS p o l)  = l

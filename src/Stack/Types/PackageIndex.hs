{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveDataTypeable #-}

module Stack.Types.PackageIndex
    ( PackageDownload (..)
    , PackageCache (..)
    , PackageCacheMap (..)
    ) where

import           Control.DeepSeq (NFData)
import           Control.Monad (mzero)
import           Data.Aeson.Extended
import           Data.ByteString (ByteString)
import           Data.Data (Data, Typeable)
import           Data.Int (Int64)
import           Data.Map (Map)
import qualified Data.Map.Strict as Map
import           Data.Store (Store)
import           Data.Text (Text)
import           Data.Text.Encoding (encodeUtf8)
import           Data.Word (Word64)
import           GHC.Generics (Generic)
import           Stack.Types.PackageIdentifier

data PackageCache = PackageCache
    { pcOffset :: !Int64
    -- ^ offset in bytes into the 00-index.tar file for the .cabal file contents
    , pcSize :: !Int64
    -- ^ size in bytes of the .cabal file
    , pcDownload :: !(Maybe PackageDownload)
    }
    deriving (Generic, Eq, Show, Data, Typeable)

instance Store PackageCache
instance NFData PackageCache

newtype PackageCacheMap = PackageCacheMap (Map PackageIdentifier PackageCache)
    deriving (Generic, Store, NFData, Eq, Show, Data, Typeable)

data PackageDownload = PackageDownload
    { pdSHA512 :: !ByteString
    , pdUrl    :: !ByteString
    , pdSize   :: !Word64
    }
    deriving (Show, Generic, Eq, Data, Typeable)
instance Store PackageDownload
instance NFData PackageDownload
instance FromJSON PackageDownload where
    parseJSON = withObject "Package" $ \o -> do
        hashes <- o .: "package-hashes"
        sha512 <- maybe mzero return (Map.lookup ("SHA512" :: Text) hashes)
        locs <- o .: "package-locations"
        url <-
            case reverse locs of
                [] -> mzero
                x:_ -> return x
        size <- o .: "package-size"
        return PackageDownload
            { pdSHA512 = encodeUtf8 sha512
            , pdUrl = encodeUtf8 url
            , pdSize = size
            }

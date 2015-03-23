{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RecordWildCards #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}

-- Autogenerated Mavlink v1.0 implementation: see smavgen_haskell.py

module SMACCMPilot.Mavlink.Native.Messages.GpsRawInt where

import Data.Word
import Data.Int
import Data.Sized.Matrix (Vector)
import Data.Serialize
import SMACCMPilot.Mavlink.Native.Serialize

gpsRawIntMsgId :: Word8
gpsRawIntMsgId = 24

gpsRawIntCrcExtra :: Word8
gpsRawIntCrcExtra = 24

data GpsRawIntMsg =
  GpsRawIntMsg
    { time_usec :: Word64
    , lat :: Int16
    , lon :: Int16
    , alt :: Int16
    , eph :: Word16
    , epv :: Word16
    , vel :: Word16
    , cog :: Word16
    , fix_type :: Word8
    , satellites_visible :: Word8
    }

getGpsRawIntMsg :: Get GpsRawIntMsg
getGpsRawIntMsg = do
  time_usec <- get
  lat <- get
  lon <- get
  alt <- get
  eph <- get
  epv <- get
  vel <- get
  cog <- get
  fix_type <- get
  satellites_visible <- get
  return GpsRawIntMsg{..}

putGpsRawIntMsg :: GpsRawIntMsg -> Put
putGpsRawIntMsg GpsRawIntMsg{..} = do
  put time_usec
  put lat
  put lon
  put alt
  put eph
  put epv
  put vel
  put cog
  put fix_type
  put satellites_visible

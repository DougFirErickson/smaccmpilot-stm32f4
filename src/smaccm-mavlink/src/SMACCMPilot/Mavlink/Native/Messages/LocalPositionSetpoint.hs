{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RecordWildCards #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}

-- Autogenerated Mavlink v1.0 implementation: see smavgen_haskell.py

module SMACCMPilot.Mavlink.Native.Messages.LocalPositionSetpoint where

import Data.Word
import Data.Int
import Data.Sized.Matrix (Vector)
import Data.Serialize
import SMACCMPilot.Mavlink.Native.Serialize

localPositionSetpointMsgId :: Word8
localPositionSetpointMsgId = 51

localPositionSetpointCrcExtra :: Word8
localPositionSetpointCrcExtra = 223

data LocalPositionSetpointMsg =
  LocalPositionSetpointMsg
    { x :: Float
    , y :: Float
    , z :: Float
    , yaw :: Float
    , coordinate_frame :: Word8
    }

getLocalPositionSetpointMsg :: Get LocalPositionSetpointMsg
getLocalPositionSetpointMsg = do
  x <- get
  y <- get
  z <- get
  yaw <- get
  coordinate_frame <- get
  return LocalPositionSetpointMsg{..}

putLocalPositionSetpointMsg :: LocalPositionSetpointMsg -> Put
putLocalPositionSetpointMsg LocalPositionSetpointMsg{..} = do
  put x
  put y
  put z
  put yaw
  put coordinate_frame

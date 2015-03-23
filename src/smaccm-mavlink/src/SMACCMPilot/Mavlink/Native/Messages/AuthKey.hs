{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RecordWildCards #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}

-- Autogenerated Mavlink v1.0 implementation: see smavgen_haskell.py

module SMACCMPilot.Mavlink.Native.Messages.AuthKey where

import Data.Word
import Data.Int
import Data.Sized.Matrix (Vector)
import Data.Serialize
import SMACCMPilot.Mavlink.Native.Serialize

authKeyMsgId :: Word8
authKeyMsgId = 7

authKeyCrcExtra :: Word8
authKeyCrcExtra = 119

data AuthKeyMsg =
  AuthKeyMsg
    { key :: Vector 32 Word8
    }

getAuthKeyMsg :: Get AuthKeyMsg
getAuthKeyMsg = do
  key <- get
  return AuthKeyMsg{..}

putAuthKeyMsg :: AuthKeyMsg -> Put
putAuthKeyMsg AuthKeyMsg{..} = do
  put key

{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- Autogenerated Mavlink v1.0 implementation: see smavgen_ivory.py

module SMACCMPilot.Mavlink.Ivory.Messages.SafetyAllowedArea where

import Ivory.Language
import Ivory.Serialize
import SMACCMPilot.Mavlink.Ivory.Send
import SMACCMPilot.Mavlink.Ivory.Unpack

safetyAllowedAreaMsgId :: Uint8
safetyAllowedAreaMsgId = 55

safetyAllowedAreaCrcExtra :: Uint8
safetyAllowedAreaCrcExtra = 3

safetyAllowedAreaModule :: Module
safetyAllowedAreaModule = package "mavlink_safety_allowed_area_msg" $ do
  depend serializeModule
  depend mavlinkSendModule
  incl mkSafetyAllowedAreaSender
  incl safetyAllowedAreaUnpack
  defStruct (Proxy :: Proxy "safety_allowed_area_msg")
  wrappedPackMod safetyAllowedAreaWrapper

[ivory|
struct safety_allowed_area_msg
  { p1x :: Stored IFloat
  ; p1y :: Stored IFloat
  ; p1z :: Stored IFloat
  ; p2x :: Stored IFloat
  ; p2y :: Stored IFloat
  ; p2z :: Stored IFloat
  ; frame :: Stored Uint8
  }
|]

mkSafetyAllowedAreaSender ::
  Def ('[ ConstRef s0 (Struct "safety_allowed_area_msg")
        , Ref s1 (Stored Uint8) -- seqNum
        , Ref s1 (Struct "mavlinkPacket") -- tx buffer/length
        ] :-> ())
mkSafetyAllowedAreaSender = makeMavlinkSender "safety_allowed_area_msg" safetyAllowedAreaMsgId safetyAllowedAreaCrcExtra

instance MavlinkUnpackableMsg "safety_allowed_area_msg" where
    unpackMsg = ( safetyAllowedAreaUnpack , safetyAllowedAreaMsgId )

safetyAllowedAreaUnpack :: Def ('[ Ref s1 (Struct "safety_allowed_area_msg")
                             , ConstRef s2 (CArray (Stored Uint8))
                             ] :-> () )
safetyAllowedAreaUnpack = proc "mavlink_safety_allowed_area_unpack" $ \ msg buf -> body $ packGet packRep buf 0 msg

safetyAllowedAreaWrapper :: WrappedPackRep (Struct "safety_allowed_area_msg")
safetyAllowedAreaWrapper = wrapPackRep "mavlink_safety_allowed_area" $ packStruct
  [ packLabel p1x
  , packLabel p1y
  , packLabel p1z
  , packLabel p2x
  , packLabel p2y
  , packLabel p2z
  , packLabel frame
  ]

instance Packable (Struct "safety_allowed_area_msg") where
  packRep = wrappedPackRep safetyAllowedAreaWrapper
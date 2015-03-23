{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- Autogenerated Mavlink v1.0 implementation: see smavgen_ivory.py

module SMACCMPilot.Mavlink.Ivory.Messages.MissionSetCurrent where

import Ivory.Language
import Ivory.Serialize
import SMACCMPilot.Mavlink.Ivory.Send
import SMACCMPilot.Mavlink.Ivory.Unpack

missionSetCurrentMsgId :: Uint8
missionSetCurrentMsgId = 41

missionSetCurrentCrcExtra :: Uint8
missionSetCurrentCrcExtra = 28

missionSetCurrentModule :: Module
missionSetCurrentModule = package "mavlink_mission_set_current_msg" $ do
  depend serializeModule
  depend mavlinkSendModule
  incl mkMissionSetCurrentSender
  incl missionSetCurrentUnpack
  defStruct (Proxy :: Proxy "mission_set_current_msg")
  wrappedPackMod missionSetCurrentWrapper

[ivory|
struct mission_set_current_msg
  { mission_set_current_seq :: Stored Uint16
  ; target_system :: Stored Uint8
  ; target_component :: Stored Uint8
  }
|]

mkMissionSetCurrentSender ::
  Def ('[ ConstRef s0 (Struct "mission_set_current_msg")
        , Ref s1 (Stored Uint8) -- seqNum
        , Ref s1 (Struct "mavlinkPacket") -- tx buffer/length
        ] :-> ())
mkMissionSetCurrentSender = makeMavlinkSender "mission_set_current_msg" missionSetCurrentMsgId missionSetCurrentCrcExtra

instance MavlinkUnpackableMsg "mission_set_current_msg" where
    unpackMsg = ( missionSetCurrentUnpack , missionSetCurrentMsgId )

missionSetCurrentUnpack :: Def ('[ Ref s1 (Struct "mission_set_current_msg")
                             , ConstRef s2 (CArray (Stored Uint8))
                             ] :-> () )
missionSetCurrentUnpack = proc "mavlink_mission_set_current_unpack" $ \ msg buf -> body $ packGet packRep buf 0 msg

missionSetCurrentWrapper :: WrappedPackRep (Struct "mission_set_current_msg")
missionSetCurrentWrapper = wrapPackRep "mavlink_mission_set_current" $ packStruct
  [ packLabel mission_set_current_seq
  , packLabel target_system
  , packLabel target_component
  ]

instance Packable (Struct "mission_set_current_msg") where
  packRep = wrappedPackRep missionSetCurrentWrapper
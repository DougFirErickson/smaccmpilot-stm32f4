{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- Autogenerated Mavlink v1.0 implementation: see smavgen_ivory.py

module SMACCMPilot.Mavlink.Ivory.Messages.SetRollPitchYawSpeedThrust where

import Ivory.Language
import Ivory.Serialize
import SMACCMPilot.Mavlink.Ivory.Send
import SMACCMPilot.Mavlink.Ivory.Unpack

setRollPitchYawSpeedThrustMsgId :: Uint8
setRollPitchYawSpeedThrustMsgId = 57

setRollPitchYawSpeedThrustCrcExtra :: Uint8
setRollPitchYawSpeedThrustCrcExtra = 24

setRollPitchYawSpeedThrustModule :: Module
setRollPitchYawSpeedThrustModule = package "mavlink_set_roll_pitch_yaw_speed_thrust_msg" $ do
  depend serializeModule
  depend mavlinkSendModule
  incl mkSetRollPitchYawSpeedThrustSender
  incl setRollPitchYawSpeedThrustUnpack
  defStruct (Proxy :: Proxy "set_roll_pitch_yaw_speed_thrust_msg")
  wrappedPackMod setRollPitchYawSpeedThrustWrapper

[ivory|
struct set_roll_pitch_yaw_speed_thrust_msg
  { roll_speed :: Stored IFloat
  ; pitch_speed :: Stored IFloat
  ; yaw_speed :: Stored IFloat
  ; thrust :: Stored IFloat
  ; target_system :: Stored Uint8
  ; target_component :: Stored Uint8
  }
|]

mkSetRollPitchYawSpeedThrustSender ::
  Def ('[ ConstRef s0 (Struct "set_roll_pitch_yaw_speed_thrust_msg")
        , Ref s1 (Stored Uint8) -- seqNum
        , Ref s1 (Struct "mavlinkPacket") -- tx buffer/length
        ] :-> ())
mkSetRollPitchYawSpeedThrustSender = makeMavlinkSender "set_roll_pitch_yaw_speed_thrust_msg" setRollPitchYawSpeedThrustMsgId setRollPitchYawSpeedThrustCrcExtra

instance MavlinkUnpackableMsg "set_roll_pitch_yaw_speed_thrust_msg" where
    unpackMsg = ( setRollPitchYawSpeedThrustUnpack , setRollPitchYawSpeedThrustMsgId )

setRollPitchYawSpeedThrustUnpack :: Def ('[ Ref s1 (Struct "set_roll_pitch_yaw_speed_thrust_msg")
                             , ConstRef s2 (CArray (Stored Uint8))
                             ] :-> () )
setRollPitchYawSpeedThrustUnpack = proc "mavlink_set_roll_pitch_yaw_speed_thrust_unpack" $ \ msg buf -> body $ packGet packRep buf 0 msg

setRollPitchYawSpeedThrustWrapper :: WrappedPackRep (Struct "set_roll_pitch_yaw_speed_thrust_msg")
setRollPitchYawSpeedThrustWrapper = wrapPackRep "mavlink_set_roll_pitch_yaw_speed_thrust" $ packStruct
  [ packLabel roll_speed
  , packLabel pitch_speed
  , packLabel yaw_speed
  , packLabel thrust
  , packLabel target_system
  , packLabel target_component
  ]

instance Packable (Struct "set_roll_pitch_yaw_speed_thrust_msg") where
  packRep = wrappedPackRep setRollPitchYawSpeedThrustWrapper
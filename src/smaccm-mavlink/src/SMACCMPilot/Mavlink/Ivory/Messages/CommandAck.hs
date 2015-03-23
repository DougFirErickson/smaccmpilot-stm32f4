{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- Autogenerated Mavlink v1.0 implementation: see smavgen_ivory.py

module SMACCMPilot.Mavlink.Ivory.Messages.CommandAck where

import Ivory.Language
import Ivory.Serialize
import SMACCMPilot.Mavlink.Ivory.Send
import SMACCMPilot.Mavlink.Ivory.Unpack

commandAckMsgId :: Uint8
commandAckMsgId = 77

commandAckCrcExtra :: Uint8
commandAckCrcExtra = 143

commandAckModule :: Module
commandAckModule = package "mavlink_command_ack_msg" $ do
  depend serializeModule
  depend mavlinkSendModule
  incl mkCommandAckSender
  incl commandAckUnpack
  defStruct (Proxy :: Proxy "command_ack_msg")
  wrappedPackMod commandAckWrapper

[ivory|
struct command_ack_msg
  { command :: Stored Uint16
  ; result :: Stored Uint8
  }
|]

mkCommandAckSender ::
  Def ('[ ConstRef s0 (Struct "command_ack_msg")
        , Ref s1 (Stored Uint8) -- seqNum
        , Ref s1 (Struct "mavlinkPacket") -- tx buffer/length
        ] :-> ())
mkCommandAckSender = makeMavlinkSender "command_ack_msg" commandAckMsgId commandAckCrcExtra

instance MavlinkUnpackableMsg "command_ack_msg" where
    unpackMsg = ( commandAckUnpack , commandAckMsgId )

commandAckUnpack :: Def ('[ Ref s1 (Struct "command_ack_msg")
                             , ConstRef s2 (CArray (Stored Uint8))
                             ] :-> () )
commandAckUnpack = proc "mavlink_command_ack_unpack" $ \ msg buf -> body $ packGet packRep buf 0 msg

commandAckWrapper :: WrappedPackRep (Struct "command_ack_msg")
commandAckWrapper = wrapPackRep "mavlink_command_ack" $ packStruct
  [ packLabel command
  , packLabel result
  ]

instance Packable (Struct "command_ack_msg") where
  packRep = wrappedPackRep commandAckWrapper
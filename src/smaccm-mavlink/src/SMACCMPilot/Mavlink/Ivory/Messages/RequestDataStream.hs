{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- Autogenerated Mavlink v1.0 implementation: see smavgen_ivory.py

module SMACCMPilot.Mavlink.Ivory.Messages.RequestDataStream where

import Ivory.Language
import Ivory.Serialize
import SMACCMPilot.Mavlink.Ivory.Send
import SMACCMPilot.Mavlink.Ivory.Unpack

requestDataStreamMsgId :: Uint8
requestDataStreamMsgId = 66

requestDataStreamCrcExtra :: Uint8
requestDataStreamCrcExtra = 148

requestDataStreamModule :: Module
requestDataStreamModule = package "mavlink_request_data_stream_msg" $ do
  depend serializeModule
  depend mavlinkSendModule
  incl mkRequestDataStreamSender
  incl requestDataStreamUnpack
  defStruct (Proxy :: Proxy "request_data_stream_msg")
  wrappedPackMod requestDataStreamWrapper

[ivory|
struct request_data_stream_msg
  { req_message_rate :: Stored Uint16
  ; target_system :: Stored Uint8
  ; target_component :: Stored Uint8
  ; req_stream_id :: Stored Uint8
  ; start_stop :: Stored Uint8
  }
|]

mkRequestDataStreamSender ::
  Def ('[ ConstRef s0 (Struct "request_data_stream_msg")
        , Ref s1 (Stored Uint8) -- seqNum
        , Ref s1 (Struct "mavlinkPacket") -- tx buffer/length
        ] :-> ())
mkRequestDataStreamSender = makeMavlinkSender "request_data_stream_msg" requestDataStreamMsgId requestDataStreamCrcExtra

instance MavlinkUnpackableMsg "request_data_stream_msg" where
    unpackMsg = ( requestDataStreamUnpack , requestDataStreamMsgId )

requestDataStreamUnpack :: Def ('[ Ref s1 (Struct "request_data_stream_msg")
                             , ConstRef s2 (CArray (Stored Uint8))
                             ] :-> () )
requestDataStreamUnpack = proc "mavlink_request_data_stream_unpack" $ \ msg buf -> body $ packGet packRep buf 0 msg

requestDataStreamWrapper :: WrappedPackRep (Struct "request_data_stream_msg")
requestDataStreamWrapper = wrapPackRep "mavlink_request_data_stream" $ packStruct
  [ packLabel req_message_rate
  , packLabel target_system
  , packLabel target_component
  , packLabel req_stream_id
  , packLabel start_stop
  ]

instance Packable (Struct "request_data_stream_msg") where
  packRep = wrappedPackRep requestDataStreamWrapper
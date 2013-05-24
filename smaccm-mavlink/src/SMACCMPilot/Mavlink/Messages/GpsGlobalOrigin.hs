{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- Autogenerated Mavlink v1.0 implementation: see smavlink_ivory.py

module SMACCMPilot.Mavlink.Messages.GpsGlobalOrigin where

import SMACCMPilot.Mavlink.Pack
import SMACCMPilot.Mavlink.Unpack
import SMACCMPilot.Mavlink.Send

import Ivory.Language

gpsGlobalOriginMsgId :: Uint8
gpsGlobalOriginMsgId = 49

gpsGlobalOriginCrcExtra :: Uint8
gpsGlobalOriginCrcExtra = 39

gpsGlobalOriginModule :: Module
gpsGlobalOriginModule = package "mavlink_gps_global_origin_msg" $ do
  depend packModule
  incl gpsGlobalOriginUnpack
  defStruct (Proxy :: Proxy "gps_global_origin_msg")

[ivory|
struct gps_global_origin_msg
  { latitude :: Stored Sint32
  ; longitude :: Stored Sint32
  ; altitude :: Stored Sint32
  }
|]

mkGpsGlobalOriginSender :: SizedMavlinkSender 12
                       -> Def ('[ ConstRef s (Struct "gps_global_origin_msg") ] :-> ())
mkGpsGlobalOriginSender sender =
  proc ("mavlink_gps_global_origin_msg_send" ++ (senderName sender)) $ \msg -> body $ do
    gpsGlobalOriginPack (senderMacro sender) msg

instance MavlinkSendable "gps_global_origin_msg" 12 where
  mkSender = mkGpsGlobalOriginSender

gpsGlobalOriginPack :: (eff `AllocsIn` s, eff `Returns` ())
                  => SenderMacro eff s 12
                  -> ConstRef s1 (Struct "gps_global_origin_msg")
                  -> Ivory eff ()
gpsGlobalOriginPack sender msg = do
  arr <- local (iarray [] :: Init (Array 12 (Stored Uint8)))
  let buf = toCArray arr
  call_ pack buf 0 =<< deref (msg ~> latitude)
  call_ pack buf 4 =<< deref (msg ~> longitude)
  call_ pack buf 8 =<< deref (msg ~> altitude)
  sender gpsGlobalOriginMsgId (constRef arr) gpsGlobalOriginCrcExtra
  retVoid

instance MavlinkUnpackableMsg "gps_global_origin_msg" where
    unpackMsg = ( gpsGlobalOriginUnpack , gpsGlobalOriginMsgId )

gpsGlobalOriginUnpack :: Def ('[ Ref s1 (Struct "gps_global_origin_msg")
                             , ConstRef s2 (CArray (Stored Uint8))
                             ] :-> () )
gpsGlobalOriginUnpack = proc "mavlink_gps_global_origin_unpack" $ \ msg buf -> body $ do
  store (msg ~> latitude) =<< call unpack buf 0
  store (msg ~> longitude) =<< call unpack buf 4
  store (msg ~> altitude) =<< call unpack buf 8

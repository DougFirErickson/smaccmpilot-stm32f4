{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE MultiParamTypeClasses #-}

-- Autogenerated Mavlink v1.0 implementation: see smavlink_ivory.py

module SMACCMPilot.Mavlink.Messages.Statustext where

import SMACCMPilot.Mavlink.Pack
import SMACCMPilot.Mavlink.Unpack
import SMACCMPilot.Mavlink.Send

import Ivory.Language

statustextMsgId :: Uint8
statustextMsgId = 253

statustextCrcExtra :: Uint8
statustextCrcExtra = 83

statustextModule :: Module
statustextModule = package "mavlink_statustext_msg" $ do
  depend packModule
  incl statustextUnpack
  defStruct (Proxy :: Proxy "statustext_msg")

[ivory|
struct statustext_msg
  { severity :: Stored Uint8
  ; text :: Array 50 (Stored Uint8)
  }
|]

mkStatustextSender :: SizedMavlinkSender 51
                       -> Def ('[ ConstRef s (Struct "statustext_msg") ] :-> ())
mkStatustextSender sender =
  proc ("mavlink_statustext_msg_send" ++ (senderName sender)) $ \msg -> body $ do
    statustextPack (senderMacro sender) msg

instance MavlinkSendable "statustext_msg" 51 where
  mkSender = mkStatustextSender

statustextPack :: (eff `AllocsIn` s, eff `Returns` ())
                  => SenderMacro eff s 51
                  -> ConstRef s1 (Struct "statustext_msg")
                  -> Ivory eff ()
statustextPack sender msg = do
  arr <- local (iarray [] :: Init (Array 51 (Stored Uint8)))
  let buf = toCArray arr
  call_ pack buf 0 =<< deref (msg ~> severity)
  arrayPack buf 1 (msg ~> text)
  sender statustextMsgId (constRef arr) statustextCrcExtra
  retVoid

instance MavlinkUnpackableMsg "statustext_msg" where
    unpackMsg = ( statustextUnpack , statustextMsgId )

statustextUnpack :: Def ('[ Ref s1 (Struct "statustext_msg")
                             , ConstRef s2 (CArray (Stored Uint8))
                             ] :-> () )
statustextUnpack = proc "mavlink_statustext_unpack" $ \ msg buf -> body $ do
  store (msg ~> severity) =<< call unpack buf 0
  arrayUnpack buf 1 (msg ~> text)

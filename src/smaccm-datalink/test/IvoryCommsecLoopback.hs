{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE TypeFamilies #-}

module Main where

import Ivory.Language
import Ivory.Stdlib

import Ivory.Tower
import Ivory.Tower.Config
import Ivory.Tower.Compile
import Ivory.OS.FreeRTOS.Tower.STM32

import Ivory.BSP.STM32.Driver.UART
import Ivory.BSP.STM32.Driver.RingBuffer

import qualified Ivory.BSP.STM32F405.Interrupt as F405
import qualified BSP.Tests.Platforms as BSP

import SMACCMPilot.Commsec.Config
import SMACCMPilot.Commsec.Sizes
import SMACCMPilot.Commsec.Tower
import SMACCMPilot.Datalink.HXStream.Tower
import SMACCMPilot.Datalink.HXStream.Ivory (hxstreamModule)

main :: IO ()
main = towerCompile p (app id)
  where
  p topts = do
    cfg <- getConfig topts BSP.testPlatformParser
    return $ stm32FreeRTOS BSP.testplatform_stm32 cfg

app :: (e -> BSP.TestPlatform F405.Interrupt)
    -> Tower e ()
app totp = do
  tp <- fmap totp getEnv
  (o,i) <- uartTower tocc (console tp) 115200 (Proxy :: Proxy 256)
  frame_loopback i o
  where
  tocc = BSP.testplatform_clockconfig . totp
  console = BSP.testUART . BSP.testplatform_uart

frame_loopback :: ChanInput (Stored Uint8)
               -> ChanOutput (Stored Uint8)
               -> Tower p ()
frame_loopback o i = do
  ct_buf_in <- channel
  ct_buf_out <- channel
  hxstreamDecodeTower "test" i (fst ct_buf_in)
  pt_out <- commsecDecodeTower "test" trivial_key (snd ct_buf_out)
  ct_out <- commsecEncodeTower "test" trivial_key 1 pt_out
  hxstreamEncodeTower "test" ct_out o

  p <- period (Milliseconds 10)

  monitor "buffered_ctloopback" $ do
    (rb :: RingBuffer 4 CyphertextArray) <- monitorRingBuffer "loopback"
    handler (snd ct_buf_in) "ct_in" $ do
      callback $ \v -> do
        _ <- ringbuffer_push rb v
        return ()
    handler p "periodic_pop" $ do
      e <- emitter (fst ct_buf_out) 1
      callback $ \_ -> do
        v <- local (iarray [])
        got <- ringbuffer_pop rb v
        when got $ do
          emit e (constRef v)

  towerModule $ hxstreamModule
  commsecTowerDeps

  where
  trivial_key = KeySalt { ks_key = take 16 [1..], ks_salt = 0xdeadbeef }
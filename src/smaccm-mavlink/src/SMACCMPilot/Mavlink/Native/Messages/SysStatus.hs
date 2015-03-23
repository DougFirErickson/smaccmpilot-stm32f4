{-# LANGUAGE DataKinds #-}
{-# LANGUAGE RecordWildCards #-}
{-# OPTIONS_GHC -fno-warn-unused-imports #-}

-- Autogenerated Mavlink v1.0 implementation: see smavgen_haskell.py

module SMACCMPilot.Mavlink.Native.Messages.SysStatus where

import Data.Word
import Data.Int
import Data.Sized.Matrix (Vector)
import Data.Serialize
import SMACCMPilot.Mavlink.Native.Serialize

sysStatusMsgId :: Word8
sysStatusMsgId = 1

sysStatusCrcExtra :: Word8
sysStatusCrcExtra = 124

data SysStatusMsg =
  SysStatusMsg
    { onboard_control_sensors_present :: Word32
    , onboard_control_sensors_enabled :: Word32
    , onboard_control_sensors_health :: Word32
    , load :: Word16
    , voltage_battery :: Word16
    , current_battery :: Int16
    , drop_rate_comm :: Word16
    , errors_comm :: Word16
    , errors_count1 :: Word16
    , errors_count2 :: Word16
    , errors_count3 :: Word16
    , errors_count4 :: Word16
    , battery_remaining :: Int8
    }

getSysStatusMsg :: Get SysStatusMsg
getSysStatusMsg = do
  onboard_control_sensors_present <- get
  onboard_control_sensors_enabled <- get
  onboard_control_sensors_health <- get
  load <- get
  voltage_battery <- get
  current_battery <- get
  drop_rate_comm <- get
  errors_comm <- get
  errors_count1 <- get
  errors_count2 <- get
  errors_count3 <- get
  errors_count4 <- get
  battery_remaining <- get
  return SysStatusMsg{..}

putSysStatusMsg :: SysStatusMsg -> Put
putSysStatusMsg SysStatusMsg{..} = do
  put onboard_control_sensors_present
  put onboard_control_sensors_enabled
  put onboard_control_sensors_health
  put load
  put voltage_battery
  put current_battery
  put drop_rate_comm
  put errors_comm
  put errors_count1
  put errors_count2
  put errors_count3
  put errors_count4
  put battery_remaining

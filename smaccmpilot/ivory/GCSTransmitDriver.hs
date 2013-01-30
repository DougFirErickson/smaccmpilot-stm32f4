{-# LANGUAGE NoMonomorphismRestriction #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE QuasiQuotes #-}

module GCSTransmitDriver where

import Ivory.Language

import IvoryHelpers

import qualified PositionType as P
import qualified ServoType as Serv
import qualified SensorsType as Sens
import qualified MotorsOutputType as M
import qualified UserInputType as U
import qualified UserInputDecode as U

import Smaccm.Mavlink.Send (useSendModule)

import qualified Smaccm.Mavlink.Messages.Heartbeat as HB
import qualified Smaccm.Mavlink.Messages.Attitude as ATT
import qualified Smaccm.Mavlink.Messages.VfrHud as HUD
import qualified Smaccm.Mavlink.Messages.ServoOutputRaw as SVO
import qualified Smaccm.Mavlink.Messages.GpsRawInt as GPS

--------------------------------------------------------------------
-- Module def

gcsTransmitDriverModule :: Module
gcsTransmitDriverModule = package "gcs_transmit_driver" $ do
  -- send module has only abstract defs so we depend on it in a weird way
  useSendModule
  -- dependencies for all the smaccmpilot types
  depend P.positionModule
  depend Serv.servoModule
  depend Sens.sensorsTypeModule
  depend M.motorsOutputModule
  depend U.userInputModule
  -- dependencies for all the smavlink types and senders
  depend HB.heartbeatModule
  depend ATT.attitudeModule
  depend HUD.vfrHudModule
  depend SVO.servoOutputRawModule
  depend GPS.gpsRawIntModule
  -- module has the following methods
  incl sendHeartbeat
  incl sendAttitude
  incl sendVfrHud
  incl sendServoOutputRaw
  incl sendGps

sendHeartbeat :: Def ('[ (Ref (Struct "motorsoutput_result"))
                       , (Ref (Struct "userinput_result"))
                       , (Ref (Struct "smavlink_out_channel"))
                       , (Ref (Struct "smavlink_system"))
                       ] :-> ())
sendHeartbeat = proc "gcs_transmit_send_heartbeat" $ \mot user ch sys -> do
  hb <- local
  armed <- (mot ~>* M.armed)
  mode  <- (user ~>* U.mode)
  store (hb ~> HB.custom_mode) (mode_to_ac2mode mode)
  store (hb ~> HB.mavtype)      mavtype_quadrotor
  -- masquerade as an APM so we can use their custom modes, for now
  store (hb ~> HB.autopilot)    autopilot_ardupilotmega
  ifte armed
    (store (hb ~> HB.base_mode) (mavl_armed + mavl_custom_mode))
    (store (hb ~> HB.base_mode) (mavl_custom_mode))
  -- system status stays 0
  store (hb ~> HB.mavlink_version) 3 -- magic number

  call_ HB.heartbeatSend hb ch sys
  retVoid 
  where
  _autopilot_generic      = 0 -- MAV_AUTOPILOT_GENERIC
  autopilot_ardupilotmega = 3 -- MAV_AUTOPILOT_ARDUPILOTMEGA
  mavtype_quadrotor       = 2 -- MAV_TYPE_QUADROTOR

  mavl_armed        = 128  
  mavl_custom_mode  = 1
  ac2mode_stabilize = 0
  ac2mode_alt_hold  = 2
  ac2mode_loiter    = 5
  mode_to_ac2mode :: Uint8 -> Uint32
  mode_to_ac2mode um = foldr translate ac2mode_stabilize t
    where
    translate (umode, ac2mode) c = (um ==? umode) ? (ac2mode, c)
    t = [(U.mode_STABILIZE, ac2mode_stabilize)
        ,(U.mode_ALT_HOLD,  ac2mode_alt_hold)
        ,(U.mode_LOITER,    ac2mode_loiter)
        ]


sendAttitude :: Def ('[ (Ref (Struct "sensors_result"))
                      , (Ref (Struct "smavlink_out_channel"))
                      , (Ref (Struct "smavlink_system"))
                      ] :-> ())
sendAttitude = proc "gcs_transmit_send_attitude" $ \sensors ch sys -> do
  att <- local
  (sensors ~> Sens.time)    `into` (att ~> ATT.time_boot_ms)
  (sensors ~> Sens.roll)    `into` (att ~> ATT.roll)
  (sensors ~> Sens.pitch)   `into` (att ~> ATT.pitch)
  (sensors ~> Sens.yaw)     `into` (att ~> ATT.yaw)
  (sensors ~> Sens.omega_x) `into` (att ~> ATT.rollspeed)
  (sensors ~> Sens.omega_y) `into` (att ~> ATT.rollspeed)
  (sensors ~> Sens.omega_z) `into` (att ~> ATT.rollspeed)
  call_ ATT.attitudeSend att ch sys
  retVoid 

sendVfrHud :: Def ('[ (Ref (Struct "position_result"))
                    , (Ref (Struct "motorsoutput_result"))
                    , (Ref (Struct "sensors_result"))
                    , (Ref (Struct "smavlink_out_channel"))
                    , (Ref (Struct "smavlink_system"))
                    ] :-> ())
sendVfrHud = proc "gcs_transmit_send_vfrhud" $ \pos mot sens ch sys -> do
  hud <- local
  -- Calculating speed from vx/vy/vz int16s in m/s*100, into float in m/s
  (calcSpeed pos) `resultInto` (hud ~> HUD.groundspeed)
  (calcSpeed pos) `resultInto` (hud ~> HUD.airspeed)
  -- Calculating alt from int32 in milimeters, into float in meters
  (calcAltitude pos) `resultInto` (hud ~> HUD.alt)
  -- Vertical zpeed from vz
  (calcVertSpeed pos) `resultInto` (hud ~> HUD.climb)
  -- Heading from sensors
  (calcHeading sens) `resultInto` (hud ~> HUD.heading)
  -- Throttle from motor output
  (calcThrottle mot) `resultInto` (hud ~> HUD.throttle)
  call_ HUD.vfrHudSend hud ch sys
  retVoid 
  where
  calcSpeed :: (Ref (Struct "position_result")) -> Ivory () IFloat
  calcSpeed pos = do
    vx <- (pos ~>* P.vx)
    vy <- (pos ~>* P.vy)
    vz <- (pos ~>* P.vz)
    sumsquares <- assign (safeCast (vx * vx + vy * vy + vz * vz) :: IFloat)
    return $ sqrt sumsquares

  calcAltitude :: (Ref (Struct "position_result")) -> Ivory () IFloat
  calcAltitude pos = do
    milimeters <- (pos ~>* P.gps_alt)
    mm_float <- assign $ toFloat milimeters
    return (mm_float / 1000)

  calcVertSpeed :: (Ref (Struct "position_result")) -> Ivory () IFloat
  calcVertSpeed pos = do
    meterspersec <- (pos ~>* P.vz)
    return $ (safeCast meterspersec :: IFloat)

  calcHeading :: (Ref (Struct "sensors_result")) -> Ivory () Sint16
  calcHeading sens = do
    radians <- (sens ~>* Sens.yaw)
    degrees <- assign $ 180 / pi * radians
    deg_int <- assign $ fromFloat 0 degrees
    return  deg_int

  calcThrottle :: (Ref (Struct "motorsoutput_result")) -> Ivory () Uint16
  calcThrottle motors = do
    thrFloat <- (motors ~>* M.throttle)
    return $ fromFloat 0 (thrFloat * 100)


sendServoOutputRaw :: Def ('[ (Ref (Struct "servo_result"))
                            , (Ref (Struct "smavlink_out_channel"))
                            , (Ref (Struct "smavlink_system"))
                            ] :-> ())
sendServoOutputRaw = proc "gcs_transmit_send_servo_output" $ \state ch sys -> do
  msg <- local
  (state ~> Serv.time)   `into` (msg ~> SVO.time_usec)
  (state ~> Serv.servo1) `into` (msg ~> SVO.servo1_raw)
  (state ~> Serv.servo2) `into` (msg ~> SVO.servo2_raw)
  (state ~> Serv.servo3) `into` (msg ~> SVO.servo3_raw)
  (state ~> Serv.servo4) `into` (msg ~> SVO.servo4_raw)
  call_ SVO.servoOutputRawSend msg ch sys


sendGps :: Def ('[ (Ref (Struct "position_result"))
                 , (Ref (Struct "smavlink_out_channel"))
                 , (Ref (Struct "smavlink_system"))
                 ] :-> ())
sendGps = proc "gcs_transmit_send_gps" $ \pos ch sys -> do
  msg <- local
  (pos ~> P.lat)     `into` (msg ~> GPS.lat)
  (pos ~> P.lon)     `into` (msg ~> GPS.lon)
  (pos ~> P.gps_alt) `into` (msg ~> GPS.alt)
  store (msg ~> GPS.eph) 10
  store (msg ~> GPS.epv) 10
  store (msg ~> GPS.vel) 1 -- XXX can calculate this
  store (msg ~> GPS.cog) 359 -- XXX can calulate this
  store (msg ~> GPS.fix_type) 3 -- 3d fix
  store (msg ~> GPS.satellites_visible) 8
  call_ GPS.gpsRawIntSend msg ch sys
  retVoid 


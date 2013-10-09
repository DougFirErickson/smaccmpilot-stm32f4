{-# LANGUAGE DataKinds #-}
{-# LANGUAGE ScopedTypeVariables #-}

module SMACCMPilot.Flight.GCS.HIL where

import Ivory.Language
import Ivory.Tower
import Ivory.Stdlib.Trig (iAtan2)

import qualified SMACCMPilot.Mavlink.Messages.HilState as H
import qualified SMACCMPilot.Flight.Types.Sensors  as S
import qualified SMACCMPilot.Hardware.GPS.Types as P

hilTranslator :: (SingI n, SingI m)
              => ChannelSink   n (Struct "hil_state_msg")
              -> ChannelSource m (Struct "sensors_result")
              -> DataSource      (Struct "position")
              -> Task p ()
hilTranslator hil sens pos = do
  hilevt       <- withChannelEvent   hil  "hil"
  sens_emitter <- withChannelEmitter sens "sens"
  pos_writer   <- withDataWriter     pos  "pos"
  m            <- withGetTimeMillis
  onEvent hilevt $ \h -> do
    time    <- getTimeMillis m
    roll    <- deref (h ~> H.roll)
    pitch   <- deref (h ~> H.pitch)
    yaw     <- deref (h ~> H.yaw)
    omega_x <- deref (h ~> H.rollspeed)
    omega_y <- deref (h ~> H.pitchspeed)
    omega_z <- deref (h ~> H.yawspeed)
    alt_mm  <- deref (h ~> H.alt)
    xacc    <- deref (h ~> H.xacc)
    yacc    <- deref (h ~> H.yacc)
    zacc    <- deref (h ~> H.zacc)
    s <- local $ istruct
      [ S.roll     .= ival roll
      , S.pitch    .= ival pitch
      , S.yaw      .= ival yaw
      , S.omega_x  .= ival omega_x
      , S.omega_y  .= ival omega_y
      , S.omega_z  .= ival omega_z
      , S.baro_alt .= ival ((safeCast alt_mm) / 1000.0)
      , S.xacc     .= ival (safeCast xacc)
      , S.yacc     .= ival (safeCast yacc)
      , S.zacc     .= ival (safeCast zacc)
      , S.time     .= ival time
      ]
    emit_ sens_emitter (constRef s)
    lat <- deref (h ~> H.lat)
    lon <- deref (h ~> H.lon)
    vx  <- deref (h ~> H.vx)
    vy  <- deref (h ~> H.vy)
    vz  <- deref (h ~> H.vz)
    (vxf :: IFloat) <- assign $ safeCast vx
    (vyf :: IFloat) <- assign $ safeCast vy
    vground <- assign $ sqrt ((vxf * vxf) + (vyf * vyf))
    heading <- assign $ (iAtan2 (safeCast vx) (safeCast vy))*(180.0/pi)
    p <- local $ istruct
      [ P.fix     .= ival P.fix_3d
      , P.num_sv  .= ival 7
      , P.dop     .= ival 3.14159

      , P.lat     .= ival lat
      , P.lon     .= ival lon
      , P.alt     .= ival alt_mm

      , P.vnorth  .= ival (safeCast vx)
      , P.veast   .= ival (safeCast vy)
      , P.vdown   .= ival (safeCast vz)
      , P.vground .= ival (castWith 0 vground)
      , P.heading .= ival heading
      ]
    writeData pos_writer (constRef p)


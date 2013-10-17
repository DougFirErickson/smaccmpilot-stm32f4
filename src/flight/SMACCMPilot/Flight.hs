{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE DeriveFoldable #-}
{-# LANGUAGE DeriveTraversable #-}

module SMACCMPilot.Flight
  ( flight
  , hil
  ) where

import Control.Applicative ((<$>))
import Data.Foldable (Foldable)
import Data.Traversable (Traversable(..))

import Ivory.Language
import Ivory.Tower

import Ivory.Stdlib.String (stdlibStringModule)

import qualified SMACCMPilot.Flight.Types.Armed as A
import SMACCMPilot.Flight.Types (typeModules)
import SMACCMPilot.Flight.Control (controlModules)
import SMACCMPilot.Flight.Commsec.Commsec (commsecModule)

import SMACCMPilot.Flight.Control.Task
import SMACCMPilot.Flight.Motors.Task
import SMACCMPilot.Flight.Motors.Platforms
import SMACCMPilot.Flight.Sensors.Task
import SMACCMPilot.Flight.Sensors.Platforms
import SMACCMPilot.Flight.UserInput.Tower
import SMACCMPilot.Flight.BlinkTask
import SMACCMPilot.Flight.GCS.Tower
import SMACCMPilot.Flight.GCS.Transmit.MessageDriver (senderModules)
import SMACCMPilot.Flight.GPS
import SMACCMPilot.Flight.Param

import SMACCMPilot.Console (consoleModule)
import SMACCMPilot.Param

import SMACCMPilot.Mavlink.Messages (mavlinkMessageModules)
import SMACCMPilot.Mavlink.Send (mavlinkSendModule)
import SMACCMPilot.Mavlink.Receive (mavlinkReceiveStateModule)
import SMACCMPilot.Mavlink.CRC (mavlinkCRCModule)
import SMACCMPilot.Mavlink.Pack (packModule)

import SMACCMPilot.Hardware.GPS.Types (gpsTypesModule)

import qualified Commsec.CommsecOpts as O
import Ivory.HXStream

import qualified Ivory.BSP.HWF4.EEPROM as HWF4
import qualified Ivory.BSP.HWF4.I2C as HWF4

import qualified Ivory.BSP.STM32F4.GPIO as GPIO
import qualified Ivory.BSP.STM32F4.UART as UART
import           Ivory.BSP.STM32F4.RCC (BoardHSE(..))

-- | All parameters in the system.
data SysParams f = SysParams
  { sysFlightParams :: FlightParams f
  } deriving (Functor, Foldable, Traversable)

-- | Initialize the system parameter groups.
sysParams :: Monad m => ParamT f m (SysParams f)
sysParams =
  SysParams <$> group "" flightParams

hil :: (BoardHSE p, MotorOutput p, SensorOrientation p)
    => O.Options
    -> Tower p ()
hil opts = do
  -- Communication primitives:
  sensors       <- channel
  flightmode    <- dataport
  -- Arming input from GCS.  Goes to MAVLink mux.
  armed_mav     <- channel
  -- Result of the MAVLink/PPM mux.  Goes to control & GCS TX.
  armed_res     <- dataport

  -- RC override channel
  (rcOvrTx, rcOvrRx) <- channel

  -- Parameters:
  (params, paramList) <- initTowerParams sysParams
  let snk_params       = portPairSink <$> params

  -- Instantiate core:
  let flightparams = sysFlightParams snk_params
  (control, motors) <- core (snk sensors)
                            (snk flightmode)
                            armed_res
                            (snk armed_mav)
                            flightparams
                            rcOvrRx
  motors_state      <- stateProxy motors
  control_state     <- stateProxy control

  -- HIL-enabled GCS on uart1:
  (istream, ostream) <- uart UART.uart1

  gcsTowerHil "uart1" opts istream ostream flightmode
    (snk armed_res) (src armed_mav) control_state motors_state
    sensors rcOvrTx paramList

  addModule (commsecModule opts)
  -- Missing module that comes in via gpsTower:
  addModule  gpsTypesModule
  addDepends gpsTypesModule

flight :: (BoardHSE p, MotorOutput p, SensorOrientation p)
       => O.Options
       -> Tower p ()
flight opts = do
  -- Communication primitives:
  sensors       <- channel
  sensor_state  <- stateProxy (snk sensors)
  flightmode    <- dataport
  -- Arming input from GCS.  Goes to MAVLink mux.
  armed_mav     <- channel
  -- Result of the MAVLink/PPM mux.  Goes to control & GCS TX.
  armed_res     <- dataport

  -- RC override channel:
  (rcOvrTx, rcOvrRx) <- channel

  -- Parameters:
  (params, paramList) <- initTowerParams sysParams
  let snk_params       = portPairSink <$> params

  -- Instantiate core:
  let flightparams = sysFlightParams snk_params
  (control, motors) <- core (snk sensors)
                            (snk flightmode)
                            armed_res
                            (snk armed_mav)
                            flightparams
                            rcOvrRx
  motors_state      <- stateProxy motors
  control_state     <- stateProxy control

  -- GPS Input on uart6 (valid for all px4fmu platforms)
  gps_position <- gpsTower UART.uart6
  position_state <- stateProxy gps_position
  -- Sensors managed by AP_HAL
  sensorsTower gps_position (src sensors)
  -- Motor output dependent on platform
  motorOutput motors

  let gcsTower' uartNm uartiStrm uartoStrm =
        gcsTower uartNm opts uartiStrm uartoStrm flightmode
          (snk armed_res) (src armed_mav) sensor_state position_state
          control_state motors_state rcOvrTx paramList

  -- GCS on UART1:
  (uart1istream, uart1ostream) <- uart UART.uart1
  gcsTower' "uart1" uart1istream uart1ostream

  -- GCS on UART5:
  (uart5istream, uart5ostream) <- uart UART.uart5
  gcsTower' "uart5" uart5istream uart5ostream

  addModule (commsecModule opts)

core :: (SingI n0, SingI n1, SingI n2)
       => ChannelSink n0 (Struct "sensors_result")
       -> DataSink (Struct "flightmode")
       -> ( DataSource (Stored A.ArmedMode)
          , DataSink   (Stored A.ArmedMode))
       -> ChannelSink n1 (Stored A.ArmedMode)
       -> FlightParams ParamSink
       -> ChannelSink n2 (Struct "rc_channels_override_msg")
       -> Tower p ( ChannelSink 16 (Struct "controloutput")
                  , ChannelSink 16 (Struct "motors"))
core sensors flightmode armed_res armed_mav_snk
     flightparams snk_rc_override_msg
  = do
  motors  <- channel
  control <- channel

  userinput        <-
    userInputTower armed_res armed_mav_snk snk_rc_override_msg
  task "blink"      $ blinkTask lights (snk armed_res) flightmode
  task "control"    $ controlTask (snk armed_res) flightmode userinput sensors
                       (src control) flightparams
  task "motmix"     $ motorMixerTask (snk control) (snk armed_res)
                        flightmode (src motors)

  mapM_ addDepends typeModules
  mapM_ addModule otherms

  return (snk control, snk motors)
  where
  lights = [relaypin, redledpin]
  relaypin = GPIO.pinB13
  redledpin = GPIO.pinB14

otherms :: [Module]
otherms = concat
  -- flight types
  [ typeModules
  -- control subsystem
  , controlModules
  -- mavlink system
  , mavlinkMessageModules
  ] ++
  [ packModule
  , mavlinkCRCModule
  , consoleModule
  -- hwf4 bsp is used for I2C, EEPROM
  , HWF4.eepromModule
  , HWF4.i2cModule
  -- the rest:
  , stdlibStringModule
  -- hxstream
  , hxstreamModule

  , senderModules
  , mavlinkSendModule
  , mavlinkReceiveStateModule
  ]

-- Helper: a uartTower with 1k buffers and 57600 kbaud
uart :: (BoardHSE p)
     => UART.UART
     -> Tower p ( ChannelSink   1024 (Stored Uint8)
                , ChannelSource 1024 (Stored Uint8))
uart u = UART.uartTower u 57600

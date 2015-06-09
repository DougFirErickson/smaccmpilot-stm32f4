{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TypeFamilies #-}

module SMACCMPilot.INS.Bias.Magnetometer.Test
  ( app
  ) where

import Data.List (intercalate)
import Control.Monad (forM_)
import System.FilePath

import Ivory.Language
import Ivory.Artifact
import qualified Ivory.Compile.C.CmdlineFrontend as C (compile)

import SMACCMPilot.INS.Bias.Magnetometer
import SMACCMPilot.INS.Bias.Magnetometer.Types

app :: IO ()
app = C.compile modules artifacts
  where

  modules = [mag_bias_test_pkg, magnetometerBiasTypesModule]
  artifacts = [makefile]

  objects = [ moduleName m <.> "o" | m <- modules ]

  exename = moduleName $ head modules

  makefile = Root $ artifactString "Makefile" $ unlines
    [ "CC = gcc"
    , "CFLAGS = -Wall -g -Os -std=c99 -D_BSD_SOURCE -Wno-unused-variable -I."
    , "LDLIBS = -lm"
    , "OBJS = " ++ intercalate " " objects
    , exename ++ ": $(OBJS)"
    , "clean:"
    , "\t-rm -f $(OBJS) " ++ exename
    , ".PHONY: clean"
    ]



mag_bias_test_pkg :: Module
mag_bias_test_pkg = package "mag_bias_test" $ do
  mbe_moddef
  incl main_proc
  incl printf_float
  incl printf_uint32
  incl puts
  where
  (mbe, mbe_moddef) = ivoryMagBiasEstimator "mbe"

  put_float :: IFloat -> Ivory eff ()
  put_float = call_ printf_float "%f\t"

  put_uint32 :: Uint32 -> Ivory eff ()
  put_uint32 = call_ printf_uint32 "%d\t"

  put_array :: (ANat n) => Ref s (Array n (Stored IFloat)) -> Ivory eff ()
  put_array a = arrayMap $ \ix -> deref (a ! ix) >>= put_float

  mk_sample :: (GetAlloc eff ~ Scope s)
            => IFloat -> IFloat -> IFloat -> Ivory eff (Ref (Stack s) (Array 3 (Stored IFloat)))
  mk_sample x y z = local (iarray [ival x, ival y, ival z])


  endl = call_ puts ""


  main_proc :: Def('[]:->Sint32)
  main_proc = proc "main" $ body $ do
    call_ puts "magx magy magz biasx biasy biasz biasmag n"
    mbe_init mbe
    forM_ test_vector $ \(x, y, z) -> do
      s <- mk_sample x y z
      put_array s
      mbe_sample mbe (constRef s)
      o <- local izero
      n <- mbe_output mbe o
      put_array o
      put_uint32 n
      endl



    ret 0

  -- from http://www.freescale.com/files/sensors/doc/app_note/AN4246.pdf
  -- expected output: 155.7 -239.1 45.8 47.0
  -- our output is a little bit off from these - possibly because of single
  -- precision floating point error?
  test_vector = [ (167.4, -242.4, 91.7)
                , (140.3, -221.9, 86.8)
                , (152.4, -230.4, -0.6)
                , (180.3, -270.6, 71.0)
                , (190.9, -212.4, 62.7)
                , (192.9, -242.4, 17.1)
                ]

printf_float :: Def('[IString, IFloat] :-> ())
printf_float = importProc "printf" "stdio.h"

printf_uint32 :: Def('[IString, Uint32] :-> ())
printf_uint32  = importProc "printf" "stdio.h"

puts :: Def('[IString] :-> ())
puts = importProc "puts" "stdio.h"


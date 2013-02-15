{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE Rank2Types #-}
{-# LANGUAGE EmptyDataDecls #-}
{-# LANGUAGE TypeFamilies #-}
--
-- Param.hs --- MAVLink parameter support.
--
-- Copyright (C) 2013, Galois, Inc.
-- All Rights Reserved.
--

module SMACCMPilot.Param where

import Data.String
import GHC.TypeLits
import Ivory.Language
import Prelude hiding (seq)

import IvoryHelpers
import IvoryCString
import Smaccm.Mavlink.Pack

import SMACCMPilot.Console
import SMACCMPilot.Storage.Partition
import SMACCMPilot.SafePack

--
-- Design notes:
--
-- * Parameters are built around Ivory references.  Each module
--   registers its parameters by calling "param_init" with the
--   parameter name and a reference to its value.
--
-- * The run time table contains the name, type code, and reference to
--   the parameter's value.  This is used to save/load parameters from
--   storage and get/set them over MAVLink.
--

----------------------------------------------------------------------
-- Run-Time Parameter Info

-- | Type codes for parameter values.
paramTypeU8, paramTypeU16, paramTypeU32, paramTypeFloat :: Uint8
paramTypeU8    = 0
paramTypeU16   = 1
paramTypeU32   = 2
paramTypeFloat = 3

-- FIXME: I'm not sure about the "IvoryStore Global a" constraint
-- here.  Shouldn't we able to store a "ParamType a" in any reference
-- since it's a value?
class (Num a, IvoryType a, IvoryStore Global a, MavlinkPackable a)
    => ParamType a where
  paramToFloat   :: a -> IFloat
  paramFromFloat :: a -> IFloat -> a

instance ParamType Uint8 where
  paramToFloat   = toFloat
  paramFromFloat = fromFloat

instance ParamType Uint16 where
  paramToFloat   = toFloat
  paramFromFloat = fromFloat

instance ParamType Uint32 where
  paramToFloat   = toFloat
  paramFromFloat = fromFloat

instance ParamType IFloat where
  paramToFloat     = id
  paramFromFloat _ = id

-- | Run-time information about a parameter.
[ivory|
 struct param_info
 { param_type      :: Stored Uint8
 ; param_name      :: Array 17 (Stored IChar)
 ; param_index     :: Stored (Ix 512) -- argh
 ; param_ptr_u8    :: Stored (Ptr Global (Stored Uint8))
 ; param_ptr_u16   :: Stored (Ptr Global (Stored Uint16))
 ; param_ptr_u32   :: Stored (Ptr Global (Stored Uint32))
 ; param_ptr_float :: Stored (Ptr Global (Stored IFloat))
 ; param_requested :: Stored Uint8
 }
|]

-- | Global array of "param_info" structures containing all known
-- parameters.  This is filled in by calling "param_init".
param_info :: MemArea (Array 512 (Struct "param_info"))
param_info = area "g_param_info" Nothing

-- | Global containing the number of entries in "param_info".
param_count :: MemArea (Stored (Ix 512))
param_count = area "g_param_count" Nothing

-- FIXME: This should be defined in "ivory-language" somewhere.
instance (SingI len) => IvoryStore s (Ix len)
instance (SingI len) => IvoryInit (Ix len)

-- | Increment "param_count" and return an entry to be filled in when
-- a new parameter is added.
param_new :: Def ('[] :-> Ref Global (Struct "param_info"))
param_new = proc "param_new" $ body $ do
  count_ref <- addrOf param_count
  count     <- deref count_ref
  store count_ref (count + 1)

  info  <- addrOf param_info
  entry <- assign (info ! count)
  store (entry ~> param_index) count
  store (entry ~> param_requested) 0
  ret entry

-- | Initialize a parameter of type "Uint8".
param_init_u8 :: Def ('[ IString                    -- name
                       , Ref Global (Stored Uint8)] -- ref
                      :-> ())
param_init_u8 = proc "param_init_u8" $ \name ref -> body $ do
  entry <- call param_new
  strcpy (entry ~> param_name)   name
  store  (entry ~> param_type)   paramTypeU8
  store  (entry ~> param_ptr_u8) (refToPtr ref)

-- | Initialize a parameter of type "Uint16".
param_init_u16 :: Def ('[ IString                     -- name
                        , Ref Global (Stored Uint16)] -- ref
                       :-> ())
param_init_u16 = proc "param_init_u16" $ \name ref -> body $ do
  entry <- call param_new
  strcpy (entry ~> param_name)    name
  store  (entry ~> param_type)    paramTypeU16
  store  (entry ~> param_ptr_u16) (refToPtr ref)

-- | Initialize a parameter of type "Uint32".
param_init_u32 :: Def ('[ IString                     -- name
                        , Ref Global (Stored Uint32)] -- ref
                       :-> ())
param_init_u32 = proc "param_init_u32" $ \name ref -> body $ do
  entry <- call param_new
  strcpy (entry ~> param_name)    name
  store  (entry ~> param_type)    paramTypeU32
  store  (entry ~> param_ptr_u32) (refToPtr ref)

-- | Initialize a parameter of type "IFloat".
param_init_float :: Def ('[ IString                     -- name
                          , Ref Global (Stored IFloat)] -- ref
                         :-> ())
param_init_float = proc "param_init_float" $ \name ref -> body $ do
  entry <- call param_new
  strcpy (entry ~> param_name)      name
  store  (entry ~> param_type)      paramTypeFloat
  store  (entry ~> param_ptr_float) (refToPtr ref)

-- | Return the number of defined parameters.
param_get_count :: Ivory s r (Ix 512)
param_get_count = deref =<< addrOf param_count

-- | Look up a parameter by name and retrieve its "param_info" entry
-- if it exists.  Returns "nullPtr" if no parameter with that name is
-- found.
param_get_by_name :: Def ('[ConstRef s (CArray (Stored IChar))]
                          :-> Ptr Global (Struct "param_info"))
param_get_by_name = proc "param_get_by_name" $ \name -> body $ do
  count <- param_get_count
  info  <- addrOf param_info

  for count $ \ix -> do
    entry <- assign (info ! ix)
    name' <- assign (constRef (toCArray (entry ~> param_name)))
    len   <- assign (arrayLen (entry ~> param_name))
    r     <- call strncmp name name' len

    ift (r ==? 0)
      (ret (refToPtr entry))

  ret nullPtr

-- | Look up a parameter by index and retrieve its "param_info" entry
-- if it exists.  Returns "nullPtr" if no parameter with that index is
-- defined.
param_get_by_index :: Def ('[Ix 512] :-> Ptr Global (Struct "param_info"))
param_get_by_index = proc "param_get_by_index" $ \ix -> body $ do
  count <- param_get_count
  ift (ix >=? count)
    (ret nullPtr)

  info <- addrOf param_info
  ret (refToPtr (info ! ix))

-- | Return the first requested parameter, or NULL if no parameters
-- are marked for transmission.
param_get_requested :: Def ('[] :-> Ptr Global (Struct "param_info"))
param_get_requested = proc "param_get_requested" $ body $ do
  count <- param_get_count
  info  <- addrOf param_info

  for count $ \ix -> do
    entry <- assign (info ! ix)
    flag  <- deref (entry ~> param_requested)

    ift (flag /=? 0)
      (ret (refToPtr entry))

  ret nullPtr

-- | Extract the value of a parameter, casted to an IFloat.
param_get_float_value :: Def ('[Ref s (Struct "param_info")] :-> IFloat)
param_get_float_value = proc "param_get_float_value" $ \info -> body $ do
  withParamRef info $ \ref -> do
    val <- deref ref
    ret $ paramToFloat val

  ret 0.0

-- | Set the value of a parameter, from an IFloat.
param_set_float_value :: Def ('[ Ref s (Struct "param_info"), IFloat] :-> ())
param_set_float_value = proc "param_set_float_value" $ \info val -> body $ do
  withParamRef info $ \ref -> do
    store ref (paramFromFloat 0 val)

----------------------------------------------------------------------
-- Parameter Initialization

-- | Type class used to select the appropriate "param_init_XXX"
-- function based on the type of the value reference.
--
-- Modules can define instances of "param_init" to work on structures
-- and initialize multiple fields at once by appending suffixes to the
-- strings.
class ParamInit a where
  param_init :: String -> Ref Global a -> Ivory s r ()

instance ParamInit (Stored Uint8) where
  param_init name ref = call_ param_init_u8 (fromString name) ref

instance ParamInit (Stored Uint16) where
  param_init name ref = call_ param_init_u16 (fromString name) ref

instance ParamInit (Stored Uint32) where
  param_init name ref = call_ param_init_u32 (fromString name) ref

instance ParamInit (Stored IFloat) where
  param_init name ref = call_ param_init_float (fromString name) ref

-- | Initialize a parameter with value stored in a "MemArea".
param_init_area :: (ParamInit a, IvoryType a) =>
                   String -> MemArea a -> Ivory s r ()
param_init_area name a = param_init name =<< addrOf a

----------------------------------------------------------------------
-- Parameter Storage

--
-- Parameters are stored in two EEPROM partitions.
--
-- - Each parameter partition has a header with a signature and
--   sequence number.
--
-- - When parameters are saved, we alternate between partitions so
--   that the last settings are available if the data becomes
--   corrupted during the save (for example, if we lose power).  The
--   sequence number is incremented on each save (wrapping from 254 to
--   1).  The values 0 and 255 are invalid sequence numbers.
--
-- - When parameters are loaded, the partition with the highest valid
--   sequence number (accounting for the 254 -> 1 wraparound) is used.
--
-- The format of each partition is:
--
-- name         type           description
-- -------------------------------------------------------------------
-- signature    uint32         must be 0xAD3E031A
-- seq #        uint8          1 .. 254
-- length       uint32         length of payload, not incl. header+CRC
-- payload      uint8[length]  format described below
-- crc          uint16         CRC-16-CCITT of header and payload
--
-- The "payload" field contains an array of parameters:
--
-- name         type           description
-- -------------------------------------------------------------------
-- type         uint8          parameter type code
-- name         char[17]       name (null padded and terminated)
-- value        uint8[8]       packed value, up to 64 bits
--
-- Notes:
--
-- - Parameters with names that are unknown or type codes that do not
--   match will be discarded and not saved.
--

-- | Signature at the start of a parameter partition.
paramSig :: Uint32
paramSig = 0xad3e031a

-- | Header fields of a SMACCMPilot parameter partition.
[ivory|
 struct param_header
 { ph_signature   :: (Stored Uint32)
 ; ph_seq         :: (Stored Uint8)
 ; ph_length      :: (Stored Uint32)
 }
|]

-- | Make this structure writable to the console.  It would be cool if
-- we could auto-generate writers like this from the structure
-- definition.
instance Writable (ConstRef s (Struct "param_header")) where
  write x = do
    writes "{ "
    writes "ph_signature="
    write $ x ~> ph_signature
    writes " "
    writes "ph_seq="
    write $ x ~> ph_seq
    writes " "
    writes "ph_length="
    write $ x ~> ph_length
    writes " }"

instance Writable (Ref s (Struct "param_header")) where
  write x = write $ constRef x

-- Array lengths that we don't want to hardcode at each use.  These
-- could be type synonyms, but that doesn't work because of a GHC bug,
-- so we use a type family and tag types instead.
--
-- NOTE: These lengths are not necessarily a "struct" length.  They
-- are the packed length which may be different due to structure
-- padding.
--
-- In an ideal world, we'd derive these lengths from a packer/unpacker
-- definition.  Maybe we could do it with Template Haskell?
type family Len a :: Nat

-- XXX size assumption
data ParamHeader
type instance Len ParamHeader = 9

data ParamDef
type instance Len ParamDef = 26

-- | Shorthand to convert a type level natural to a numeric type.
fromNat :: forall len a. (SingI (len :: Nat), Num a) => Proxy len -> a
fromNat _ = fromInteger (fromSing (sing :: Sing len))

-- | Shorthand for creating a byte array of "len" elements.
localBuf :: (SingI len)
         => Proxy len
         -> Ivory (Top s) r (Ref (Stack s) (Array len (Stored Uint8)))
localBuf _ = local (iarray [])

-- | Partition ID that parameters are written to on the next save.
param_next_pid :: MemArea (Stored PartitionID)
param_next_pid = area "g_param_next_pid" (Just (ival partitionParamA))

-- | Sequence number to write on the next save.
param_next_seq :: MemArea (Stored Uint8)
param_next_seq = area "g_param_next_seq" (Just (ival 1))

-- | Read a param header from a partition.
param_read_header :: Def ('[ PartitionID
                           , Ref s (Struct "param_header")] :-> IBool)
param_read_header = proc "param_read_header" $ \pid header -> body $ do
  buf     <- localBuf (Proxy :: Proxy (Len ParamHeader))
  read_ok <- call partition_read pid 0 (toCArray buf) (arrayLen buf)
  ift (iNot read_ok)
    (ret false)

  unpackFrom_ (constRef buf) 0 $ do
    munpack $ header ~> ph_signature
    munpack $ header ~> ph_seq
    munpack $ header ~> ph_length

  ret true

-- | Write a param header to a partition.
param_write_header :: Def ('[ PartitionID
                            , ConstRef s (Struct "param_header")] :-> IBool)
param_write_header = proc "param_write_header" $ \pid header -> body $ do
  -- writes "param: writing header: "
  -- write  header
  -- writes "\r\n"

  buf <- localBuf (Proxy :: Proxy (Len ParamHeader))
  packInto_ buf 0 $ do
    mpack $ header ~> ph_signature
    mpack $ header ~> ph_seq
    mpack $ header ~> ph_length

  ret =<< call partition_write pid 0 (constRef (toCArray buf)) (arrayLen buf)

-- | Return true if a param header has a valid signature.
param_is_valid_header :: Def ('[ConstRef s (Struct "param_header")] :-> IBool)
param_is_valid_header = proc "param_is_valid_header" $ \header -> body $ do
  sig <- header ~>* ph_signature
  ret (sig ==? paramSig)

-- | Return true if "seq_n" is a valid sequence number.
param_is_valid_seq :: Def ('[Uint8] :-> IBool)
param_is_valid_seq = proc "param_is_valid_seq" $ \seq_n -> body $ do
  ret (seq_n /=? 0 .&& seq_n /=? 255)

-- | Return the sequence number following "seq_n".  The values '0' and
-- '255' are never valid sequence numbers.
param_get_next_seq :: Def ('[Uint8] :-> Uint8)
param_get_next_seq = proc "param_get_next_seq" $ \seq_n -> body $ do
  ifte (seq_n ==? 254)
    (ret 1)
    (ret $ seq_n + 1)

-- | Load parameters from EEPROM if valid data is available.
param_load :: Def ('[] :-> IBool)
param_load = proc "param_load" $ body $ do
  headerA <- local (istruct [])
  call_ param_read_header partitionParamA headerA
  headerA_ok <- call param_is_valid_header (constRef headerA)
  ift headerA_ok
    (do writes "param: headerA = "
        write headerA
        writes "\r\n")

  headerB <- local (istruct [])
  call_ param_read_header partitionParamB headerB
  headerB_ok <- call param_is_valid_header (constRef headerB)
  ift headerB_ok
    (do writes "param: headerB = "
        write headerB
        writes "\r\n")

  ret true

-- | Return the next partition to write to after "pid".
param_get_next_pid :: Def ('[PartitionID] :-> PartitionID)
param_get_next_pid = proc "param_get_next_pid" $ \pid -> body $ do
  ifte (pid ==? partitionParamA)
    (ret partitionParamB)
    (ret partitionParamA)

-- | Call the function "f" with a reference to the parameter's value,
-- which will be some type of class "ParamType".
--
-- XXX ref type should be polymorphic but "withRef" isn't.
withParamRef :: Ref s1 (Struct "param_info")
             -> (forall a. ParamType a =>
                 Ref Global (Stored a) -> Ivory (Block (Block s)) r ())
             -> Ivory s r ()
withParamRef param f = do
  type_code <- param ~>* param_type

  ift (type_code ==? paramTypeU8)
    (do ptr <- param ~>* param_ptr_u8
        withRef ptr f (return ()))

  ift (type_code ==? paramTypeU16)
    (do ptr <- param ~>* param_ptr_u16
        withRef ptr f (return ()))

  ift (type_code ==? paramTypeU32)
    (do ptr <- param ~>* param_ptr_u32
        withRef ptr f (return ()))

  ift (type_code ==? paramTypeFloat)
    (do ptr <- param ~>* param_ptr_float
        withRef ptr f (return ()))

-- | Save a single parameter to EEPROM at "offset" in "pid".
param_save_1 :: Def ('[ PartitionID
                      , Uint16
                      , Ref s (Struct "param_info")] :-> IBool)
param_save_1 = proc "param_save_1" $ \pid off param -> body $ do
  buf <- localBuf (Proxy :: Proxy (Len ParamDef))

  withParamRef param $ \ref -> do
    packInto_ buf 0 $ do
      mpack      $ constRef $ param ~> param_type
      marrayPack $ param ~> param_name
      mpack      $ constRef ref

  buf' <- assign $ constRef $ toCArray buf
  ok   <- call partition_write pid off buf' (arrayLen buf)
  ret ok

-- | Save parameters to EEPROM.
param_save :: Def ('[] :-> IBool)
param_save = proc "param_save" $ body $ do
  -- XXX size assumptions
  offset   <- local (ival (fromNat (Proxy :: Proxy (Len ParamHeader))))
  len      <- local (ival 0)
  count    <- param_get_count
  info     <- addrOf param_info
  next_seq <- addrOf param_next_seq
  next_pid <- addrOf param_next_pid
  pid      <- deref next_pid

  writes "param: writing to partition "
  write next_pid
  writes " seq "
  write next_seq
  writes "\r\n"

  -- Write the parameter values first, following where the header will
  -- be written.
  for count $ \ix -> do
    param <- assign (info ! ix)
    off   <- deref offset
    ok    <- call param_save_1 pid off param

    ift ok
      (do offset += fromNat (Proxy :: Proxy (Len ParamDef))
          len    += fromNat (Proxy :: Proxy (Len ParamDef)))

  -- Now that we know the payload length, write the header.
  header <- local (istruct [])
  store (header ~> ph_signature)  paramSig
  store (header ~> ph_seq)    =<< deref next_seq
  store (header ~> ph_length) =<< deref len
  ok <- call param_write_header pid (constRef header)
  ift (iNot ok)
    (ret false)

  -- TODO: Write CRC after the payload.

  -- Update the partition ID and sequence for the next save.
  store next_seq =<< call param_get_next_seq =<< deref next_seq
  store next_pid =<< call param_get_next_pid =<< deref next_pid

  ret true

----------------------------------------------------------------------
-- Ivory Module

paramModule :: Module
paramModule = package "param" $ do
  depend cstringModule
  depend consoleModule
  depend partitionModule
  depend packModule
  defStruct (Proxy :: Proxy "param_info")
  defStruct (Proxy :: Proxy "param_header")
  defMemArea param_info
  defMemArea param_count
  incl param_new
  incl param_init_u8
  incl param_init_u16
  incl param_init_u32
  incl param_init_float

  incl param_get_by_name
  incl param_get_by_index
  incl param_get_requested
  incl param_get_float_value
  incl param_set_float_value

  defMemArea param_next_pid
  defMemArea param_next_seq
  incl param_read_header
  incl param_write_header
  incl param_is_valid_header
  incl param_is_valid_seq
  incl param_get_next_seq
  incl param_get_next_pid
  incl param_load
  incl param_save_1
  incl param_save

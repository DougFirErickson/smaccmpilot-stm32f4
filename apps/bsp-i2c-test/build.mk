# -*- Mode: makefile-gmake; indent-tabs-mode: t; tab-width: 2 -*-
#
# build.mk
#
# Copyright (C) 2012, Galois, Inc.
# All Rights Reserved.
#
# This software is released under the "BSD3" license.  Read the file
# "LICENSE" for more information.
#

$(eval $(call tower_pkg,IVORY_PKG_I2C_TEST,bsp-i2c-test-gen))

BSP_I2C_TEST_IMG          := bsp-i2c-test

BSP_I2C_TEST_REAL_OBJECTS += $(IVORY_PKG_I2C_TEST_OBJECTS)

BSP_I2C_TEST_INCLUDES     += $(IVORY_PKG_I2C_TEST_CFLAGS)

BSP_I2C_TEST_CFLAGS       += $(BSP_I2C_TEST_INCLUDES)

BSP_I2C_TEST_DISABLE_GLOBAL_STARTUP_OBJECTS := 1


$(eval $(call cbmc_pkg,BSP_I2C_TEST,IVORY_PKG_I2C_TEST))

$(eval $(call when_os,freertos grtos,image,BSP_I2C_TEST))

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

IVORY_PKG_BSP_LED_TEST_GEN_SYMS    := true

BSP_LED_TOWER_TEST        := bsp-led-test-gen

$(eval $(call tower_pkg,IVORY_PKG_BSP_LED_TEST,$(BSP_LED_TOWER_TEST)))

BSP_LED_TEST_IMG          := bsp-led-test

BSP_LED_TEST_LIBRARIES    += libFreeRTOS.a
BSP_LED_TEST_INCLUDES     += $(FREERTOS_CFLAGS)

BSP_LED_TEST_REAL_OBJECTS += $(IVORY_PKG_BSP_LED_TEST_OBJECTS)

BSP_LED_TEST_INCLUDES     += $(IVORY_PKG_BSP_LED_TEST_CFLAGS)
BSP_LED_TEST_CFLAGS       += $(BSP_LED_TEST_INCLUDES)

BSP_LED_TEST_DISABLE_GLOBAL_STARTUP_OBJECTS := 1

$(eval $(call cbmc_pkg,BSP_LED_TEST,IVORY_PKG_BSP_LED_TEST))
$(eval $(call when_os,freertos,image,BSP_LED_TEST))
# $(eval $(call frama_c_pkg,BSP_LED_TEST,$(BSP_LED_TOWER_TEST)))


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
# Written by Pat Hickey <pat@galois.com>, January 08, 2013
#

$(eval $(call tower_pkg,IVORY_PKG_TOWER_EXAMPLE_STM32F4SIGNALS,tower-example-stm32f4signals))

APP_TOWER_EXAMPLE_STM32F4SIGNALS_IMG          := tower-example-stm32f4signals

APP_TOWER_EXAMPLE_STM32F4SIGNALS_OBJECTS      := main.o
APP_TOWER_EXAMPLE_STM32F4SIGNALS_REAL_OBJECTS += $(IVORY_PKG_TOWER_EXAMPLE_STM32F4SIGNALS_OBJECTS)

APP_TOWER_EXAMPLE_STM32F4SIGNALS_CFLAGS        = $(APP_TOWER_EXAMPLE_STM32F4SIGNALS_INCLUDES)
APP_TOWER_EXAMPLE_STM32F4SIGNALS_CFLAGS       += $(IVORY_PKG_TOWER_EXAMPLE_STM32F4SIGNALS_CFLAGS)
APP_TOWER_EXAMPLE_STM32F4SIGNALS_CXXFLAGS      = $(APP_TOWER_EXAMPLE_STM32F4SIGNALS_INCLUDES)
APP_TOWER_EXAMPLE_STM32F4SIGNALS_CXXFLAGS     += $(IVORY_PKG_TOWER_EXAMPLE_STM32F4SIGNALS_CFLAGS)

APP_TOWER_EXAMPLE_STM32F4SIGNALS_LIBS         += -lm

$(eval $(call when_os,freertos grtos,image,APP_TOWER_EXAMPLE_STM32F4SIGNALS))

# vim: set ft=make noet ts=2:

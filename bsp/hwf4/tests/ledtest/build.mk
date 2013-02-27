# -*- Mode: makefile-gmake; indent-tabs-mode: t; tab-width: 2 -*-
#
# build.mk --- Build an STM32F4 test program.
#
# Copyright (C) 2012, Galois, Inc.
# All Rights Reserved.
#
# This software is released under the "BSD3" license.  Read the file
# "LICENSE" for more information.
#
# Written by James Bielman <jamesjb@galois.com>, December 07, 2012
#

LEDTEST_IMG       := ledtest
LEDTEST_OBJECTS   := main.o

LEDTEST_CFLAGS    += $(FREERTOS_CFLAGS)
LEDTEST_CFLAGS    += -I$(TOP)/bsp/include
LEDTEST_CFLAGS    += -I$(TOP)/bsp/hwf4/include
LEDTEST_LIBRARIES := libhwf4.a libstm32_usb.a libFreeRTOS.a

$(eval $(call image,LEDTEST))

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

$(eval $(call tower_pkg,IVORY_PKG_TOWER_EXAMPLE_SIMPLESIGNAL,tower-example-simplesignal))

APP_TOWER_EXAMPLE_SIMPLESIGNAL_IMG          := tower-example-simplesignal

APP_TOWER_EXAMPLE_SIMPLESIGNAL_OBJECTS      := main.o
APP_TOWER_EXAMPLE_SIMPLESIGNAL_REAL_OBJECTS += $(IVORY_PKG_TOWER_EXAMPLE_SIMPLESIGNAL_OBJECTS)

APP_TOWER_EXAMPLE_SIMPLESIGNAL_CFLAGS        = $(APP_TOWER_EXAMPLE_SIMPLESIGNAL_INCLUDES)
APP_TOWER_EXAMPLE_SIMPLESIGNAL_CFLAGS       += $(IVORY_PKG_TOWER_EXAMPLE_SIMPLESIGNAL_CFLAGS)
APP_TOWER_EXAMPLE_SIMPLESIGNAL_CXXFLAGS      = $(APP_TOWER_EXAMPLE_SIMPLESIGNAL_INCLUDES)
APP_TOWER_EXAMPLE_SIMPLESIGNAL_CXXFLAGS     += $(IVORY_PKG_TOWER_EXAMPLE_SIMPLESIGNAL_CFLAGS)

APP_TOWER_EXAMPLE_SIMPLESIGNAL_LIBS         += -lm

$(eval $(call when_os,freertos grtos,image,APP_TOWER_EXAMPLE_SIMPLESIGNAL))

# vim: set ft=make noet ts=2:

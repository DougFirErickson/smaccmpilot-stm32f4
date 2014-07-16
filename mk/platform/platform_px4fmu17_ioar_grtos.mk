# -*- Mode: makefile-gmake; indent-tabs-mode: t; tab-width: 2 -*-
#
# platform/platform_px4fmu17_grtos.mk
# PX4FMU 1.7 (STM32F4 Cortex-M4) toolchain and board support package
# configuration.
#
# Copyright (C) 2012, Galois, Inc.
# All Rights Reserved.
#
# This software is released under the "BSD3" license.  Read the file
# "LICENSE" for more information.
#
# Written by James Bielman <jamesjb@galois.com>, December 07, 2012
#            Pat Hickey    <pat@galois.com>,     August 06, 2013
#

include mk/platform/toolchain_stm32f4.mk
include mk/platform/board_px4fmu17.mk

# support building PX4 images for this platform
px4fmu17_ioar_grtos_SUPPORT_PX4IMG := 1

# platform argument for tower builds
px4fmu17_ioar_grtos_TOWER_PLATFORM := px4fmu17_ioar

# operating system argument for tower builds
px4fmu17_ioar_grtos_TOWER_OS := grtos

# px4 image prototype
px4fmu17_ioar_grtos_PX4_IMG_PROTO := px4fmu17

# vim: set ft=make noet ts=2:

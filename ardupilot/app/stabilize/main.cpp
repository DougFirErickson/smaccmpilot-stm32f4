/*
 * main.cpp --- AP_HAL based helicopter stabilizer
 *
 * Copyright (C) 2012, Galois, Inc.
 * All Rights Reserved.
 *
 * This software is released under the "BSD3" license.  Read the file
 * "LICENSE" for more information.
 */

#include <stdint.h>

#include <FreeRTOS.h>
#include <task.h>

#include <hwf4/led.h>
#include <hwf4/gpio.h>
#include <hwf4/timer.h>

#if CONFIG_HAL_BOARD == HAL_BOARD_SMACCM
# include <AP_HAL_SMACCM.h>
#else
# error "Unsupported CONFIG_HAL_BOARD type."
#endif

#include "sensors.h"
#include "userinput.h"

const AP_HAL::HAL& hal = AP_HAL_BOARD_DRIVER;

static xTaskHandle h_main_task;

void main_task(void *args)
{
  vTaskSetApplicationTaskTag(xTaskGetIdleTaskHandle(), (pdTASK_HOOK_CODE)1);
  vTaskSetApplicationTaskTag(NULL, (pdTASK_HOOK_CODE)2);

  led_init();

  hal.init(0, NULL);

  sensors_init();
  userinput_init();

  for(;;);
}

extern "C" int main(void)
{
  xTaskCreate(main_task, (signed char *)"main", 1024, NULL, 0, &h_main_task);
  vTaskStartScheduler();
  for (;;)
    ;
  return 0;
}
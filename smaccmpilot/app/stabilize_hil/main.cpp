// -*- Mode: C++; indent-tabs-mode: nil; c-basic-offset: 4 -*-
/*
 * main.cpp --- AP_HAL HIL based helicopter stabilizer
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

#include <AP_HAL_SMACCM.h>
#include <AP_Math.h>

#include <smaccmpilot/userinput.h>
#include <smaccmpilot/motorsoutput.h>
#include <smaccmpilot/sensors.h>
#include <smaccmpilot/gps.h>
#include <smaccmpilot/stabilize.h>
#include "gcs.h"

const AP_HAL::HAL& hal = AP_HAL_BOARD_DRIVER;

// Handle to the main thread.
static xTaskHandle g_main_task;

extern "C" float throttle_to_climb_rate(float throttle);

extern float g_throttle_cruise;

// Main thread.  Starts up the GCS thread to communicate with the
// host, then processes incoming sensor data and writes servo output
// back to MAVLink.
void main_task(void *arg)
{
    struct userinput_result input;
    struct sensors_result sensors;
    struct motorsoutput_result motors;
    struct servo_result servos;
    portTickType last_wake;

    hal.init(0, NULL);
    userinput_init();
    motorsoutput_init();
    gcs_init();

    memset(&sensors, 0, sizeof(sensors));
    last_wake = xTaskGetTickCount();

    for (;;) {
        userinput_get(&input);
        gcs_sensors_get(&sensors);
        stabilize_motors(&input, &sensors, &motors);
        motorsoutput_set(&motors);
        motorsoutput_getservo(&servos);
        gcs_servos_set(&servos);

        vTaskDelayUntil(&last_wake, 10);
    }
}

extern "C"
int main()
{
    xTaskCreate(main_task, (signed char *)"main", 1024, NULL, 0, &g_main_task);
    vTaskStartScheduler();

    for (;;)
        ;

    return 0;
}

#! /bin/bash

set -e
set -o nounset
set -o pipefail

FW_TARGETDIR=$(pwd)/firmware
PREFIX=$(ros2 pkg prefix micro_ros_setup)

# Parse cli arguments
UROS_VERBOSE_FLASH=off
UROS_EXTRA_FLASH_ARGS=""

function usage {
    echo "Usage: ros2 run micro_ros_setup flash_firmware.sh [options] -- [flash_args]"
    echo "Options:"
    echo "  -h   Display help and exit."
    echo "  -v   Print verbose flash output."
    echo "Flash args: These options will get directly forwarded to the flash program (currently only supported for zephyr)."
}

while getopts "vh" o
do
    case "$o" in
        v)
            UROS_VERBOSE_FLASH=on
            ;;
        h)
            usage
            exit 0
            ;;
        [?])
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -n "$@" ]]; then
    UROS_EXTRA_FLASH_ARGS=("$@")
fi

export UROS_VERBOSE_FLASH
export UROS_EXTRA_FLASH_ARGS

# Checking if firmware exists
if [ -d $FW_TARGETDIR ]; then
    RTOS=$(head -n1 $FW_TARGETDIR/PLATFORM)
    PLATFORM=$(head -n2 firmware/PLATFORM | tail -n1)
else
    echo "Firmware folder not found. Please use ros2 run micro_ros_setup create_firmware_ws.sh to create a new project."
    exit 1
fi

# Flash specific firmware folder if needed
if [ $PLATFORM != "generic" ] && [ -d "$PREFIX/config/$RTOS/generic" ]; then
    if [ -f $PREFIX/config/$RTOS/generic/flash.sh ]; then
      echo "Flashing firmware for $RTOS platform $PLATFORM"
      . $PREFIX/config/$RTOS/generic/flash.sh
    else
      echo "No flash step found for $RTOS platform $PLATFORM"
    fi
else
    if [ -f $PREFIX/config/$RTOS/$PLATFORM/flash.sh ]; then
      echo "Flashing firmware for $RTOS platform $PLATFORM"
      . $PREFIX/config/$RTOS/$PLATFORM/flash.sh
    else
      echo "No flash step found for $RTOS platform $PLATFORM"
    fi
fi

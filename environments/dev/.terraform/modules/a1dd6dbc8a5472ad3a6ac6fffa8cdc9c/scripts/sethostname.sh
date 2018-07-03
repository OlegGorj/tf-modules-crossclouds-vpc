#!/bin/bash -e

if [ "$1" != "" ]; then
    echo "INFO: Changing hostname to $1 "
    sudo hostname $1
else
  echo "INFO: Hostname for this instance remains the same ($HOSTNAME)"
fi

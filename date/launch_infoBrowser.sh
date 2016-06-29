#!/bin/bash

export DATE_SITE=/dateSite

. /date/setup.sh

. /date/infoLogger/infoLoggerConfig.sh

/date/infoLogger/infoBrowser.tcl -l any

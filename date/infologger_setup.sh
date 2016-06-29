#!/bin/sh

# infoLoggerServer 

export DATE_SITE=/dateSite
. /date/infoLogger/infoLoggerConfig.sh

${DATE_INFOLOGGER_BIN}/infoLoggerServer -o

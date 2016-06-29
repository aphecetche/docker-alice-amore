#!/bin/bash

export DATE_SITE=${DATE_SITE:=/dateSite}

. /date/setup.sh

exec "$@"


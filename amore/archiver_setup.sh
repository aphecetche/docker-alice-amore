#!/bin/sh

. /amore_env.sh

printenv

amoreArchiver -g db:amoreArchiverConfig.txt

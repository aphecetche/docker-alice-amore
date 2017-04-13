#!/bin/sh

. /amore_env.sh

printenv

/usr/sbin/sshd -D

#!/bin/sh
#
# strawman way to get the sshd setup going...
#
service sshd start
service sshd stop

/usr/sbin/sshd -D



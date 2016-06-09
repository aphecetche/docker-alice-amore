#!/bin/sh

# dim 

# # first check that the correct link to the database have been made
#
# if [ -z ${MYSQL_PORT+x} ]
# then
#     echo "Link alias 'mysql' was not set!"
#     printenv
#     exit
# fi
#
export DATE_SITE=/dateSite
. /date/setup.sh

$DIMBIN/dns</dev/null >& /tmp/dns.log


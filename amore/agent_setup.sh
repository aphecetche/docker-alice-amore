#!/bin/sh

. /amore_env.sh

printenv

# # create a FIFO to read some data from 
# mkfifo /tmp/derootin
#
# # feed the pipe using tcp
# socat PIPE:/tmp/derootin TCP:$DEROOT_HOST:$DEROOT_PORT &

if [ -z ${DEROOT_INPUT+x} ]; then

# use file as data source

amoreAgent "$@" -s $DATA_SOURCE

else

    # using deroot pipe as data source
deroot $DEROOT_INPUT /tmp/derootin > /dev/null &

amoreAgent "$@" -s /tmp/derootin

fi



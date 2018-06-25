#!/bin/sh

. /amore_env.sh

printenv

# create a FIFO to feed some root files into the thing
mkfifo /tmp/derootout

# "export" the pipe using tcp
socat TCP-LISTEN:$DEROOT_PORT,fork,reuseaddr,ignoreeof PIPE:/tmp/derootout &

echo "done"
echo "collection://$COLLECTION"

while true
do
deroot collection://$COLLECTION /tmp/derootout
sleep 10
done


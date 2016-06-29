#!/bin/sh

# amore setup within a container

export DATE_SITE=/dateSite
. /date/setup.sh

# AMORE and DIM
export AMORE=${AMORE:=/opt/amore}
export AMORE_SITE=${AMORE_SITE:=/amoreSite}
export LD_LIBRARY_PATH=${AMORE_SITE}/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=${AMORE}/lib:$LD_LIBRARY_PATH
export PATH=${AMORE}/bin:$PATH
export LD_LIBRARY_PATH=/opt/dim/linux:$LD_LIBRARY_PATH
# AMORE extras
export AMORE_CDB_URI=${AMORE_CDB_URI:=local:///local/cdb}
# ROOT
export ROOTSYS=${ROOTSYS:=/opt/root}
export PATH=$ROOTSYS/bin:$PATH
export LD_LIBRARY_PATH=$ROOTSYS/lib:$LD_LIBRARY_PATH

. amoreSetup $AMORE_SITE/AMORE.params

if [ -z ${ALICE_ROOT+x} ]; then
    if test -d /opt/aliroot; then
        export ALICE_ROOT=/opt/aliroot
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ALICE_ROOT/lib
    fi
else
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ALICE_ROOT/lib
fi

exec "$@"

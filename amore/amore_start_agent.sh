. ./amore_setup.sh

export ALICE_ROOT=/opt/aliroot

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ALICE_ROOT/lib

echo "$@"

#amoreAgent "$@"

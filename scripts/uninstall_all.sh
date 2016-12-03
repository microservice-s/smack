#! /bin/bash
# global uninstallation script

DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR"/utility.sh


setup_res

# reset each server
for i in {1..4}; do

  SERV=server-$i

  if [[ $(hostname) = "$SERV" ]]; then
    SELF=$SERV
  else
    echo "Resetting $SERV"
    remote_run $SERV "~/scripts/declare_hosts.sh undo"
  fi

done

echo "Resetting $SELF"
~/scripts/declare_hosts.sh undo


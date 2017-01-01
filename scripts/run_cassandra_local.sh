#!/usr/bin/env bash

DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR"/utility.sh


echo "Running Cassandra on $SELF"

DEAD=0

# TODO : il faudrait ne mettre DEAD à 1 que quand on remplace un noeud qui est down, mais comment le savoir ?
# En effet quand le noeud est down nodetool n'est plus actif donc il faudrait demander à des noeuds fonctionnels
# Pour le moment on va passer en mode remplacement uniquement si un argument est fourni.
# if [[ $# -eq 1 ]]; then
#   DEAD=1
# fi

# On regarde si un noeud cassandra nous connaît,
# si oui alors on doit remplacer le processus mort
# si non on doit démarrer normalement
for SERV in "${NODES[@]}"; do

    if remote_run_sync "~/scripts/cassandra_status.sh | grep $MY_IP"; then
      DEAD=1;
      break;
    fi

done

# if [[ $# -ge 2 ]]; then
#   if (( RANDOM % 2 )); then
#     DEAD=1;
#   fi
# fi


if [ $DEAD -eq 1 ]; then

  echo "Replacing dead node"

  CENV=$XNET/apache-cassandra-3.9/conf/cassandra-env.sh

  cp -f $CENV $CENV.old
  chmod $CENV 666
  echo 'JVM_OPTS="$JVM_OPTS -Dcassandra.replace_address='$MY_IP'"' >> $CENV
  chmod $CENV 644

else

  echo "Starting node"

fi



# Xss = java thread stack size
# Xms = initial Java heap size
# Xmx = maximum Java heap size

# export JVM_OPTS="$JVM_OPTS Xss256k -Xms64m -Xmx256m"
export JVM_OPTS="$JVM_OPTS -Xss1024k -Xms64m -Xmx512m"

sudo rm $XNET/cassandra.log
sudo $XNET/apache-cassandra-3.9/bin/cassandra -R -p ${PIDF_CASSANDRA} > $XNET/cassandra.log


# If Cassandra node currently down, finish repairing
if [ $DEAD -eq 1 ]; then

  $XNET/apache-cassandra-3.9/bin/nodetool repair
  mv -f $CENV.old $CENV

fi


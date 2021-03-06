# server installation script that installs everything for a single machine

DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR"/utility.sh


# Abort if already installed
check_installed


# configure hosts
~/scripts/declare_hosts.sh

# Install M/Monit
~/scripts/install_mmonit.sh


echo manual | sudo tee /etc/init/zookeeper.override > /dev/null


if [ $# -ge 1 ]; then
  echo 'Configuration du master mesos'

# Install Mesos, Spark, Kafka, Cassandra, ...
  ~/scripts/install_node_deps.sh im_a_master

  MY_ID="${SELF##*-}"
  echo manual | sudo tee /etc/init/mesos-slave.override > /dev/null
  echo $MY_ID | sudo tee /etc/zookeeper/conf/myid > /dev/null
  printf "\nmaxClientCnxns=50" | sudo tee --append /etc/zookeeper/conf/zoo.cfg > /dev/null
  printf "\ntickTime=2000" | sudo tee --append /etc/zookeeper/conf/zoo.cfg > /dev/null
  printf "\ninitLimit=10" | sudo tee --append /etc/zookeeper/conf/zoo.cfg > /dev/null
  printf "\nsyncLimit=5" | sudo tee --append /etc/zookeeper/conf/zoo.cfg > /dev/null
  printf "\ndataDir=/var/lib/zookeeper" | sudo tee --append /etc/zookeeper/conf/zoo.cfg > /dev/null
  printf "\nclientPort=2181" | sudo tee --append /etc/zookeeper/conf/zoo.cfg > /dev/null

    for MASTER in "${MASTERS[@]}"; do

      MASTER_ID="${MASTER##*-}"
      printf "\nserver.$MASTER_ID="${MASTER}":2888:3888" | sudo tee --append /etc/zookeeper/conf/zoo.cfg > /dev/null

    done

else

  echo "Configuration de l'esclave mesos "$SELF
  ~/scripts/install_node_deps.sh
  echo manual | sudo tee /etc/init/mesos-master.override > /dev/null

fi


# Configure M/Monit
~/scripts/config_mmonit.sh


finish_server_install

echo "Installation du serveur $SELF terminée"


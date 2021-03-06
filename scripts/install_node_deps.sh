#! /bin/bash

DIR=$(cd "$(dirname "$0")" && pwd)
. "$DIR"/utility.sh

# Ajout des repos nécessaires
DISTRO=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -cs)

SPARK_LINK='http://d3kbcqa49mib13.cloudfront.net/spark-2.0.2-bin-hadoop2.7.tgz'
SPARK_TAR="${SPARK_LINK##*/}"
SPARK_DIRECTORY_NAME=${SPARK_TAR%\.tgz*}

KAFKA_LINK='http://apache.crihan.fr/dist/kafka/0.10.1.0/kafka_2.11-0.10.1.0.tgz'


echo "Installation clé E56151BF sur $SELF"
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF
echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" | sudo tee /etc/apt/sources.list.d/mesosphere.list


echo "Mise à jour du cache sur $SELF"

# Mise à jour du cache pour avoir accès aux nouveaux composants
sudo apt-get -y update


echo "Installation de mesos sur $SELF"
sudo apt-get -y install mesos
# Installe aussi zookeeper


echo "Installation de spark sur $SELF"
wget -P ~ ${SPARK_LINK} 2>/dev/null
tar -xzf ~/${SPARK_TAR}

# Not useful anymore, clean it
rm -f ~/${SPARK_TAR}


~/scripts/install_cassandra.sh


echo "Installation de Scala sur $SELF"
sudo apt-get -y install scala

# echo "Installation de Marathon"
# sudo apt-get -y install marathon

# echo "Configuration de Marathon"
# sudo mkdir -p /etc/marathon/conf/

# sudo bash -c "echo zk://${MASTER}:2181/mesos > /etc/marathon/conf/master"
# sudo bash -c "echo zk://$(slaves_list):2181/marathon > /etc/marathon/conf/zk"
# sudo bash -c "echo ${SELF} > /etc/marathon/conf/hostname"

# sudo systemctl restart marathon


# Mesos Master

if [ $# -ge 1 ]; then
#TODO: possible useless install steps for masters
  echo "Serveur maître/manager détecté"
  SPARK_MASTER_DECL="spark.master mesos://zk://"${JOINED_MASTERS_WITH_ZK_PORT}"/mesos"
  echo ${SPARK_MASTER_DECL} | sudo tee ~/${SPARK_DIRECTORY_NAME}/conf/spark-defaults.conf
  printf '\nspark.executor.memory 1024m'| sudo tee --append ~/${SPARK_DIRECTORY_NAME}/conf/spark-defaults.conf
  echo 'export MESOS_NATIVE_JAVA_LIBRARY=/usr/lib/libmesos.so'| sudo tee ~/${SPARK_DIRECTORY_NAME}/conf/spark-env.sh


  echo 'Installation de Kafka'

  #Installation de Kafka (seulement au niveau des masters)
  #sudo apt-get -y install openjdk-8-jdk
  git clone https://github.com/mesos/kafka
  cd kafka && ./gradlew jar
  wget -P ~/kafka ${KAFKA_LINK} 2>/dev/null

  export MESOS_NATIVE_JAVA_LIBRARY=/usr/local/lib/libmesos.so
  export LIBPROCESS_IP=$(cat /etc/my_ip)


  echo 'Configuration de Kafka'

  printf '\nuser=xnet'| sudo tee ~/kafka/kafka-mesos.properties
  printf "\nzk=$JOINED_MASTERS_WITH_ZK_PORT"| sudo tee --append ~/kafka/kafka-mesos.properties
  printf '\nstorage=zk:/mesos-kafka-scheduler'| sudo tee --append ~/kafka/kafka-mesos.properties
  printf "\nmaster=zk://$JOINED_MASTERS_WITH_ZK_PORT/mesos"| sudo tee --append ~/kafka/kafka-mesos.properties
  printf '\napi=http://'${SELF}':7000'| sudo tee --append ~/kafka/kafka-mesos.properties

  echo 'Fin du bloc maître'
else

  # Stop master service
  sudo systemctl stop mesos-master

fi


echo "Installation des dépendances terminée sur $SELF"




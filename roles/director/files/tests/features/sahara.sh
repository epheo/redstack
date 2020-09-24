#!/bin/bash
project='sahara'

cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
../new_identity.sh $project
source ~stack/rcfiles/$project'rc'

echo "TESTING DATA PROCESSING..."

echo "Creating images for DATA PROCESSING"

  mkdir -p /home/stack/user-images/sahara
  cp /home/stack/user-images/centos7.qcow2 /home/stack/user-images/sahara/sahara-hortonworks-2.5.qcow2
#  cp /usr/share/rhel-guest-image-7/rhel-guest-image-7.2-20160302.0.x86_64.qcow2 /home/stack/user-images/sahara/fedora-rawhide-sahara.qcow2

sudo yum install openstack-sahara-image-pack -y


cd /home/stack/user-images/sahara/
sahara-image-pack --image sahara-hortonworks-2.5.qcow2 ambari 2.5
cd /home/stack/


openstack image create sahara-hortonworks-2.5 --file /home/stack/user-images/sahara/sahara-hortonworks-2.5.qcow2 --disk-format qcow2 --container-format bare

sleep 60

# Register Image
echo "Registering Image"

openstack dataprocessing image register sahara-hortonworks-2.5 --username centos
openstack dataprocessing image tags add sahara-hortonworks-2.5 --tags ambari 2.5



echo "Configuring node group templates"

FLOATING_NET_ID=$(openstack network show floating -c id -f value)

openstack dataprocessing node group template create --autoconfig \
    --name hortonworks-nodegroup-master --plugin ambari  \
    --plugin-version 2.5 --processes  Ambari "MapReduce History Server" "Spark History Server" NameNode ResourceManager SecondaryNameNode "YARN Timeline Server" ZooKeeper "Kafka Broker" "Hive Metastore" HiveServer Oozie \
    --flavor m1.xlarge --auto-security-group --floating-ip-pool ${FLOATING_NET_ID}


openstack dataprocessing node group template create --autoconfig  \
    --name hortonworks-nodegroup-worker --plugin ambari \
    --plugin-version 2.5 --processes DataNode NodeManager \
    --flavor m1.medium --auto-security-group --floating-ip-pool ${FLOATING_NET_ID} \
    --volumes-per-node 2 --volumes-size 10




echo "Configuring cluster templates"

openstack dataprocessing cluster template create --autoconfig  \
    --name hortonworks-cluster-template \
    --node-groups hortonworks-nodegroup-master:1 hortonworks-nodegroup-worker:2

sleep 30

echo "Create cluster (NOTE: this step takes loooooooong........)"

openstack dataprocessing cluster create --wait --name test-cluster-1 \
    --cluster-template hortonworks-cluster-template --user-keypair undercloud-key \
    --neutron-network redhat-internal --image sahara-hortonworks-2.5


sleep 300







echo "Registering Data and run Jobs"

openstack container create test-sahara




# PIG

 curl -o /tmp/pig-input https://raw.githubusercontent.com/openstack/sahara-tests/master/sahara_tests/scenario/defaults/edp-examples/edp-pig/cleanup-string/data/input
 touch /tmp/pig-output

 openstack object create --name input-pig test-sahara /tmp/pig-input
 openstack object create --name output-pig test-sahara /tmp/pig-output


 openstack dataprocessing data source create --type swift --username redhat --password redhat \
  --url "swift://test-sahara/input-pig" input-pig

 openstack dataprocessing data source create --type swift --username redhat --password redhat \
  --url "swift://test-sahara/output-pig" output-pig


curl -o /tmp/example.pig https://raw.githubusercontent.com/openstack/sahara-tests/master/sahara_tests/scenario/defaults/edp-examples/edp-pig/cleanup-string/example.pig
curl -k -o /tmp/edp-pig-udf-stringcleaner.jar -H "Accept: application/zip"  https://raw.githubusercontent.com/openstack/sahara-tests/master/sahara_tests/scenario/defaults/edp-examples/edp-pig/cleanup-string/edp-pig-udf-stringcleaner.jar


openstack object create --name example.pig test-sahara /tmp/example.pig
openstack object create --name edp-pig-udf-stringcleaner.jar test-sahara /tmp/edp-pig-udf-stringcleaner.jar


openstack dataprocessing job binary create --url "swift://test-sahara/example.pig" \
  --username redhat --password redhat --description "example.pig binary example" --name example.pig

openstack dataprocessing job binary create --url "swift://test-sahara/edp-pig-udf-stringcleaner.jar" \
  --username redhat --password redhat --description "edp-pig-udf-stringcleaner.jar binary example" --name edp-pig-udf-stringcleaner.jar



openstack dataprocessing job template create --type Pig \
   --name pigsample --main example.pig --libs edp-pig-udf-stringcleaner.jar


openstack dataprocessing job execute --input input-pig --output output-pig \
  --job-template pigsample --cluster test-cluster-1





# Spark

cat > /tmp/input-spark << EOF
OpenStack is a free and open-source software platform for cloud computing, mostly deployed as infrastructure-as-a-service (IaaS), whereby virtual servers and other resources are made available to customers
EOF

touch /tmp/output-spark

openstack object create --name input-spark test-sahara /tmp/input-spark
openstack object create --name output-spark test-sahara /tmp/output-spark


 openstack dataprocessing data source create --type swift --username redhat --password redhat \
  --url "swift://test-sahara/input-spark" input-spark

 openstack dataprocessing data source create --type swift --username redhat --password redhat \
  --url "swift://test-sahara/output-spark" output-spark




curl -k -o /tmp/spark-wordcount.jar -H "Accept: application/zip"  https://raw.githubusercontent.com/openstack/sahara-tests/master/sahara_tests/scenario/defaults/edp-examples/edp-spark/spark-wordcount.jar

openstack object create --name spark-wordcount.jar test-sahara /tmp/spark-wordcount.jar

openstack dataprocessing job binary create --url "swift://test-sahara/spark-wordcount.jar" \
  --username redhat --password redhat --description "spark-wordcount.jar binary example" --name sparkexample.jar




openstack dataprocessing job template create --type Spark \
   --name sparkexamplejob --main sparkexample.jar

openstack dataprocessing job execute  \
   --job-template sparkexamplejob --cluster test-cluster-1 \
   --configs edp.java.main_class:sahara.edp.spark.SparkWordCount edp.spark.adapt_for_swift:true fs.swift.service.sahara.password:redhat fs.swift.service.sahara.username:redhat  --args  swift://test-sahara/input-spark swift://test-sahara/output-spark



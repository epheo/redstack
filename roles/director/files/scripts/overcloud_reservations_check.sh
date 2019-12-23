{% raw %}
#!/bin/bash

echo "HOST: $(hostname)"
echo "******************"
echo "*     CPUs       *"
echo "******************"
lscpu | grep -i -E  "^CPU\(s\):|core|socket"
echo ""
echo "Isolated CPUs: $(cat /etc/tuned/cpu-partitioning-variables.conf  | grep ^iso | awk -F \= '{print $2}')"
echo "Nova vcpu cores: $(cat /etc/nova/nova.conf | grep vcpu_pin_set | grep -v ^# | awk -F \= '{print $2}' )"

MASK=$( echo "obase=2; ibase=16; $(ovs-vsctl get Open_vSwitch . other_config | awk -F "\"" '{print toupper($14)}')" | bc )

CORES=''
len=${#MASK}
for ((i=0; i<${#MASK}; i++)); do MASK_array[$i]="${MASK:$i:1}" ; done
index=0
while [ $len -gt 0 ]
do
len=$[$len-1]
if [ ${MASK_array[$len]} == 1 ]; then CORES+=$index ; if [ $len != 0 ]; then CORES+=","; fi ;fi
index=$[$index+1]
done

echo "PDM cores: " $CORES

echo ""
echo "******************"
echo "*      Mem       *"
echo "******************"
free -h
cat /proc/meminfo | grep Huge
echo ""
echo "2MB Hugepages on NUMA0 -->  Reserved: $(cat /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages)  Free: $(cat /sys/devices/system/node/node0/hugepages/hugepages-2048kB/free_hugepages)"
echo "2MB Hugepages on NUMA1 -->  Reserved: $(cat /sys/devices/system/node/node1/hugepages/hugepages-2048kB/nr_hugepages)  Free: $(cat /sys/devices/system/node/node1/hugepages/hugepages-2048kB/free_hugepages)"
echo "1GB Hugepages on NUMA0 -->  Reserved: $(cat /sys/devices/system/node/node0/hugepages/hugepages-1048576kB/nr_hugepages)  Free: $(cat /sys/devices/system/node/node0/hugepages/hugepages-1048576kB/free_hugepages)"
echo "1GB Hugepages on NUMA1 -->  Reserved: $(cat /sys/devices/system/node/node1/hugepages/hugepages-1048576kB/nr_hugepages)  Free: $(cat /sys/devices/system/node/node1/hugepages/hugepages-1048576kB/free_hugepages)"
echo "Nova Reserved Memory: $(cat /etc/nova/nova.conf | grep reserved_host_memory_mb | grep -v ^# | awk -F \= '{print $2}' ) MB"

DPDK_mem=$(ovs-vsctl get Open_vSwitch . other_config | awk -F ", " '{print $5}' | awk -F \= '{print $2}')
echo "DPDK Reserved Memory:       NUMA0= $(echo $DPDK_mem | awk -F , '{print $1}' |  sed 's/\"//g') MB       NUMA1=$(echo $DPDK_mem | awk -F , '{print $2}' |  sed 's/\"//g') MB  "
echo ""
exit 0


## Send and run on computes
#ansible compute -b -m copy -a 'src=/home/stack/scripts/overcloud_reservations_check.sh dest=/usr/bin/reservations_check.sh mode=775'
#ansible compute -b -m shell -a 'reservations_check.sh'

{% endraw %}
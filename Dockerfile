FROM ubuntu:16.04
MAINTAINER ingee.kim@sk.com

LABEL RUN "sudo docker run --privileged -v /sys/bus/pci/drivers:/sys/bus/pci/drivers -v /sys/kernel/mm/hugepages:/sys/kernel/mm/hugepages -v /sys/devices/system/node:/sys/devices/system/node -v /dev:/dev ingee/dpdk-hello"
LABEL HOST "host should be DPDK enabled Ubuntu16.04"

# Install basic packages
WORKDIR /root
RUN apt-get update
RUN apt-get install -y module-init-tools pciutils python

# setup DPDK
COPY $PWD/x86_64-native-linuxapp-gcc/ /root/x86_64-native-linuxapp-gcc/
COPY $PWD/tools/ /root/tools/
COPY $PWD/example/ /root/example/
COPY $PWD/ingee-exec.sh /root/

# run DPDK-helloworld
CMD ["/root/ingee-exec.sh"]

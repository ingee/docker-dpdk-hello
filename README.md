# docker-dpdk-hello

- run DPDK-hello example in Docker container
- USAGE : 
  $ sudo docker run --privileged -v /sys/bus/pci/drivers:/sys/bus/pci/drivers -v /sys/kernel/mm/hugepages:/sys/kernel/mm/hugepages -v /sys/devices/system/node:/sys/devices/system/node -v /dev:/dev ingee/dpdk-hello
- tested on DPDK enabled Ubuntu 16.04 host

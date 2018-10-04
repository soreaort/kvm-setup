#!/bin/bash -x
if [ $(id -u) == 0 ]
then
   #Define variables
   IPADDRESS="192.168.100.250"
   GWADDRESS="192.168.100.1"
   NWMASK="255.255.255.0"
   SSHPORT="22"

   #Update packages
   yum update -y

   #Install some admin tools
   yum install -y vim git net-tools lsof nc firewalld rsync sysstat bind-utils

   #Install libvirt and qemu-kvm
   yum install -y qemu-kvm libvirt libvirt-python libguestfs-tools virt-install

   #Start and enable libvirtd
   systemctl enable libvirtd
   systemctl start libvirtd

   #Disable NetworkManager and start/configure networking
   systemctl stop NetworkManager
   systemctl disable NetworkManager
   systemctl enable network
 
   #Create ifcfg-enp2s0
   cat > /etc/sysconfig/network-scripts/ifcfg-enp2s0 <<EOF
DEVICE=enp2s0
ONBOOT=yes 
NM_CONTROLLED=no
BRIDGE=virbr0
BOOTPROTO=static
EOF
   
   #Create ifcfg-virbr0
   cat > /etc/sysconfig/network-scripts/ifcfg-virbr0 <<EOF
DEVICE=virbr0
ONBOOT=yes
TYPE=Bridge
BOOTPROTO=static
IPADDR=$IPADDRESS
GATEWAY=$GWADDRESS
NETMASK=$NWMASK
EOF

   #Configure namespaces
   cat > /etc/resolv.conf <<EOF
nameserver $GWADDRESS
nameserver 4.4.4.4
nameserver 8.8.8.8
EOF
   
   #Restart network to refresh configuration
   systemctl restart network

   if [ $(echo $SSHPORT) != 22 ]
   then
      #Change ssh port and enable it in selinux
      #Below package provides semanage
      yum install -y policycoreutils-python
      sed 's/#Port 22/Port '$SSHPORT'/' -i /etc/ssh/sshd_config
      #Disable remotely root login
      sed -E 's/#?PermitRootLogin yes/PermitRootLogin no/' -i /etc/ssh/sshd_config
      semanage port -a -t ssh_port_t -p tcp $SSHPORT
      systemctl restart sshd

      #Create rule for new ssh port
      firewall-cmd --add-interface=enp2s0 --permanent --zone=public
      firewall-cmd --add-port=$SSHPORT/tcp --permanent --zone=public
      firewall-cmd --reload
   fi

else
   echo "You must be root to execute it!!!"
   exit 1
fi

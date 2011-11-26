#!/bin/bash
# vbclonecfg.sh
#
# This script was made for use on a simi base install of CentOS 6 using 
# VirtualBox 4.1.4. I first create a basic install and get all of my configuration
# files (ex. ssh keys, .bashrc, repos, .vimrc etc...) in place. I then just clone
# my "basic" install for whatever I am building out. The script handles changing 
# the VM hardware addresses so you can bring up the new VM's interface as eth0.
# Clone_config.sh will also ask you for the new hostname.
#
# - kp

# Use a regual expression to match the meac addresses. First line is the old MAC 
# and the second line is out new MAC address.
hwaddr_old=$(grep -E -o '[[:xdigit:]]{2}(:[[:xdigit:]]{2}){5}' /etc/udev/rules.d/70-persistent-net.rules | awk 'NR==1')
hwaddr_new=$(grep -E -o '[[:xdigit:]]{2}(:[[:xdigit:]]{2}){5}' /etc/udev/rules.d/70-persistent-net.rules | awk 'NR==2')

echo -n "Clone's old MAC address: " 
echo $hwaddr_old

echo -n "Clone's new MAC address: " 
echo $hwaddr_new

# Grab the line numbers so we can comment/uncomment the lines.
line_one_num=$(grep -n "$hwaddr_old" /etc/udev/rules.d/70-persistent-net.rules | awk -F: '{print $1}')
line_two_num=$(grep -n "$hwaddr_new" /etc/udev/rules.d/70-persistent-net.rules | awk -F: '{print $1}')

# Use sed to create a temp 70-persistent-net.rules with the adjusted configuration.
# First we make the replace the old eth0 interface with the new eth1 entry.
# Next we comment out the old eth0 (comment = #) and uncomment the new eth0
# using the line numbers we grabed above.
cat /etc/udev/rules.d/70-persistent-net.rules | sed "s/eth1/eth0/" |
                                                sed "$line_one_num s/^/#/" |
                                                sed "$line_two_num s/#//" > tmp/70-persistent-net.rules

# The MAC address we are using for the new eth0 was stored using lower case which
# we will want to convert to upper case before we store it in our new ifcfg-eth0 
# config.
hwaddr_new=$line_two
hwaddr_new_upper=$(echo $hwaddr_new |tr '[:lower:]' '[:upper:]')

# Find the old MAC with a regular expression and replace it with our new upper case
# MAC address. I could just use the variable for the old hardware address $hwaddr_old 
# to search and replace but that wouldnt look as cool.
cat /etc/sysconfig/network-scripts/ifcfg-eth0 | sed -r "s/[[:xdigit:]]{2}(:[[:xdigit:]]{2}){5}/${hwaddr_new_upper}/" > tmp/ifcfg-eth0

# Replace the current hostname with one entered at run time.
echo -n "Enter a new hostname: "
read hostname
cat /etc/sysconfig/network | sed "s/basic/${hostname}/" > tmp/network


# Display the new configs located in the tmp directory.
echo -e "\n\nNew ifcfg-eth0 config: \n"
cat tmp/ifcfg-eth0

echo -e "\n\nNew network config: \n"
cat tmp/network

echo -e "\n\nNew 70-persistent-net.rules config: \n"
cat tmp/70-persistent-net.rules

# Copy the tmp configs to the real locations
deploy(){
cp tmp/ifcfg-eth0 /etc/sysconfig/network-scripts/ifcfg-eth0
cp tmp/70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules
cp tmp/network /etc/sysconfig/network
}

# Ask the user if the configs above look correct and if so procude to use the
# deploy function to put them in the correct locations. 
echo -e "\n\nDo you wish to use this configuration?\n"

select yn in "Yes" "No"; do
    case $yn in
        Yes ) deploy; break;;
        No ) exit;;
    esac
done


echo -e "\nReboot to enable the new changes."

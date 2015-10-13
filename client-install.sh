#!/bin/bash

###############################################################################
# Configure client to use local mirror and sync time using NTP
#
# Copyright Mike Wendt 2015
###############################################################################

###############################################################################
# Config
###############################################################################
SRC_RELEASE="trusty"		# Set to release to mirror 
MIRROR="mirror.example.com"	# Set to hostname or IP of local mirror

############################################################################### 
# Script                                                                        
###############################################################################
function logger() {
  echo "INFO : $@"
}

# Check config var set for hostname
if [ "$MIRROR" == "mirror.example.com" ] ; then
  echo "ERROR : Config var 'MIRROR' not set in script; set and re-run"
  exit
fi

# Check for sudo/root
if [ $UID -ne 0 ] ; then
  echo "Usage: sudo $0"
  exit
fi

# Configure apt-mirror
logger "Configuring apt for release/mirror provided..."
mv /etc/apt/sources.list /etc/apt/sources.list.bak
cat > /etc/apt/sources.list <<EOL
deb http://${MIRROR}/ubuntu ${SRC_RELEASE} main restricted universe multiverse
deb http://${MIRROR}/ubuntu ${SRC_RELEASE}-security main restricted universe multiverse
deb http://${MIRROR}/ubuntu ${SRC_RELEASE}-updates main restricted universe multiverse
#deb http://${MIRROR}/ubuntu ${SRC_RELEASE}-proposed main restricted universe multiverse
deb http://${MIRROR}/ubuntu ${SRC_RELEASE}-backports main restricted universe multiverse

deb-src http://${MIRROR}/ubuntu ${SRC_RELEASE} main restricted universe multiverse
deb-src http://${MIRROR}/ubuntu ${SRC_RELEASE}-security main restricted universe multiverse
deb-src http://${MIRROR}/ubuntu ${SRC_RELEASE}-updates main restricted universe multiverse
#deb-src http://${MIRROR}/ubuntu ${SRC_RELEASE}-proposed main restricted universe multiverse
deb-src http://${MIRROR}/ubuntu ${SRC_RELEASE}-backports main restricted universe multiverse
EOL

# Update apt repos
logger "Updating repos before install..."
apt-get update

# Install apt-mirror, apache, ntp
logger "Installting ntp..."
apt-get install ntp -y

# Configure NTP
logger "Configuring NTP..."
mv /etc/ntp.conf /etc/ntp.conf.bak
cat > /etc/ntp.conf <<EOL
# /etc/ntp.conf, configuration for ntpd; see ntp.conf(5) for help

driftfile /var/lib/ntp/ntp.drift

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery

# Permit all access over the loopback interface.  This could
# be tightened as well, but to do so would effect some of
# the administrative functions.
restrict 127.0.0.1
restrict -6 ::1

server ${MIRROR} iburst

# Add log file
logfile /var/log/ntpd.log
EOL

# Set time
logger "Restarting NTP and setting time..."
service ntp stop
ntpdate time.nist.gov
service ntp start

logger "Finished Installation..."

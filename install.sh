#!/bin/bash

###############################################################################
# Install and configure script for Ubuntu Mirror with NTP
#
# Copyright Mike Wendt 2015
###############################################################################

###############################################################################
# Config
###############################################################################
SRC_MIRROR="mirror.umd.edu"	# Set to source of packages; no uri only FQDN
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

# Update apt repos
logger "Updating repos before install..."
apt-get update

# Install apt-mirror, apache, ntp
logger "Installting apt-mirror, apache & ntp..."
apt-get install apt-mirror ntp ntpdate apache2 -y

# Configure NTP
logger "Configuring NTP..."
mv /etc/ntp.conf /etc/ntp.conf.bak
cat > /etc/ntp.conf <<EOL
# ntp.conf(5), ntp_acc(5), ntp_auth(5), ntp_clock(5), ntp_misc(5), ntp_mon(5).

driftfile /var/lib/ntp/drift

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery

# Permit all access over the loopback interface.  This could
# be tightened as well, but to do so would effect some of
# the administrative functions.
restrict 127.0.0.1
restrict -6 ::1

# Hosts on local network are less restricted.
restrict 10.5.0.0 mask 255.255.0.0 nomodify notrap

# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
server 98.175.203.200
server 216.229.0.179 iburst
server 64.113.32.5
server 24.56.178.140 iburst
server time.nist.gov iburst

# Undisciplined Local Clock. This is a fake driver intended for backup
# and when no outside source of synchronized time is available.
#server  127.127.1.0     # local clock
#fudge   127.127.1.0 stratum 10

# Enable public key cryptography.
#crypto

includefile /etc/ntp/crypto/pw

# Key file containing the keys and key identifiers used when operating
# with symmetric key cryptography.
keys /etc/ntp/keys

# Specify the key identifiers which are trusted.
#trustedkey 4 8 42

# Specify the key identifier to use with the ntpdc utility.
#requestkey 8

# Specify the key identifier to use with the ntpq utility.
#controlkey 8

# Enable writing of statistics records.
statistics clockstats cryptostats loopstats peerstats

# Add log file
logfile /var/log/ntpd.log
EOL

# Set time
logger "Restarting NTP and setting time..."
service ntp stop
ntpdate time.nist.gov
service ntp start

# Configure apt-mirror
logger "Configuring apt-mirror for release/mirror provided..."
cat > /etc/apt/mirror.list <<EOL
############# config ##################
#
# set base_path    /var/spool/apt-mirror
#
# set mirror_path  \$base_path/mirror
# set skel_path    \$base_path/skel
# set var_path     \$base_path/var
# set cleanscript \$var_path/clean.sh
# set defaultarch  <running host architecture>
# set postmirror_script \$var_path/postmirror.sh
# set run_postmirror 0
set nthreads     4
set _tilde 0
#
############# end config ##############

deb http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE} main restricted universe multiverse
deb http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-security main restricted universe multiverse
deb http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-updates main restricted universe multiverse
#deb http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-proposed main restricted universe multiverse
deb http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-backports main restricted universe multiverse

deb-i386 http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE} main restricted universe multiverse
deb-i386 http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-security main restricted universe multiverse
deb-i386 http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-updates main restricted universe multiverse
#deb-i386 http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-proposed main restricted universe multiverse
deb-i386 http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-backports main restricted universe multiverse

deb-src http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE} main restricted universe multiverse
deb-src http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-security main restricted universe multiverse
deb-src http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-updates main restricted universe multiverse
#deb-src http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-proposed main restricted universe multiverse
deb-src http://${SRC_MIRROR}/ubuntu ${SRC_RELEASE}-backports main restricted universe multiverse

clean http://${SRC_MIRROR}/ubuntu
EOL

# Setup symlinks for apt-mirror in apache
logger "Creating symlink for Apache to serve pacakges..."
ln -s /var/spool/apt-mirror/mirror/$SRC_MIRROR/ubuntu/ /var/www/html/ubuntu

# Setup cron job for apt-mirror
logger "Installing cron for apt-mirror..."
cat > /etc/cron.d/apt-mirror <<EOL
#
# Regular cron jobs for the apt-mirror package
#
MAILTO=""
0 */6 * * *     apt-mirror      /usr/bin/apt-mirror > /var/spool/apt-mirror/var/cron.log
EOL

logger "Finished Installation..."

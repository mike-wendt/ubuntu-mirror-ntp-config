# ubuntu-mirror-ntp-config

## Overview
Scripts to setup an Ubuntu mirror (can be changed to also serve as a Debian mirror) with NTP for a local data center. The benefits have been: fast distribution of packages (10G network connects woohoo!), limit external network traffic for package updates, time sync between nodes (great for big data apps) and super fast installs (the Ubuntu archives can be sluggish at times).

## Mirror
### Recommendations
For our deployment we use a VM, but this could be a smaller standalone machine as well:
* 2 cores recommend for multiple downloads
* 2 GB RAM - haven't seen a need for more
* ~250GB per release that you want to mirror - mirroring `trusty - main, updates, security, backports` is about ~180GB currently
* Ubuntu LTS 14.04 amd64 server install
* LVM on `/` or `/var` so the volume can be expanded if space runs out - `/var/spool/apt-mirror/` is the default storage directory
* 10G network (if available) to distribute packages as quickly as possible

### Installation
Before running change the config vars at the beginning of the script, then run `sudo install.sh` to install and setup initial configuration.

### Running Initial Mirror Pull
After installation the packages need to be synced from the mirror. You can run this command to start the sync: `sudo -u apt-mirror apt-mirror 2>&1 | tee /var/spool/apt-mirror/var/first-run.log` or wait for the cron job to run every 6 hrs to start the sync

### Accessing Packages
Packages will be available at <http://mirror.example.com/ubuntu>; check firewall settings if port 80 is not open

### Custom Configuration
After installation the following files are useful to know about if any changes need to be made.

#### NTP
`/etc/ntp.conf` - main file for NTP configuration; currently set to source from multiple machines listed on the NIST Time page: <http://tf.nist.gov/tf-cgi/servers.cgi> Edit this file if you need to change these servers so they are more local to you (as opposed to the mainly East Coast US ones in the setup now). **TIP:** Run `ntpq -p` after NTP has started and check that all servers show a delay less than 100. If not change the servers to something more local to get the delay under 100. Delays over 100 cause issues with keeping the clock in sync. **WARNING:** Do not try to use NTP to sync with Windows AD machines. Linux NTP will not trust them and will not keep the clocks in sync.

#### Mirroring
* `/etc/apt/mirror.list` sets up all the repositories to mirror locally as well as config settings for the program
* `/etc/cron.d/apt-mirror` - cron script to run updates every 6 hrs; edit this to limit updates to daily/nightly/weekly or whatever schedule you would like

## Clients
There is a `client-install.sh` to setup clients Ubuntu to use the new NTP server and mirror for packages. **Before running** change the config variables at the beginning of the script to set the IP/hostname of the mirror that you want to use otherwise the installation will not run. After running the script on each client the clients will have their time synced with the mirror and request packages from the mirror instead of the archives.

## License
MIT License for project in file `LICENSE`

## Fixes & Issues
Submit issues and pull requests as needed and I'll respond as soon as I can

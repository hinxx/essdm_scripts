essdm_scripts
======
ESS Physical Development Machine (DM) Setup Script

## Goal
* This script should be used for the ESS Physical DM setup for CentOS 7.1 1503.
* This script should provide an easy solution to setup the DM quickly
* This script should focus *ONLY* two options (EEE Local installation and CS-Studio installation) 
* This script should provide an additional installation of several packages


## CentOS 7.1 (1503)
Download the CentOS 7.1 (1503) as following links :

### UI in most case
* http://vault.centos.org/7.1.1503/isos/x86_64/CentOS-7-x86_64-DVD-1503-01.iso

### Non User Interface - console
* http://vault.centos.org/7.1.1503/isos/x86_64/CentOS-7-x86_64-Minimal-1503-01.iso

## Things one should do carefully
* Set Installation Source as **Local media** 
* Create iocuser and set the administrator permission
* **Do not "yum" before executing the dm_setup script**.  DM **should** use the ESS RPM repositories, not any other CentOS ones. The script will remove original CentOS repositories completely, and put the ESS customized repositories.  


## DM Setup

### Login the CentOS as iocuser

### Open an Terminal

### Download the script

* Short, but it has no meaning
```
$ curl -L https://git.io/vi8DA -o dm_setup.bash
```
* Long, but it is self-evidence
```
$ curl -L https://raw.githubusercontent.com/jeonghanlee/essdm_scripts/master/dm_setup.bash -o dm_setup.bash
```

### Execute the script
* In case, no user interface (no X windows)
```
$ bash dm_setup.bash 
```

* In case, an user interface (yes X windows, Gnome, etc)
```
$ bash dm_setup.bash gui
```

## Reference 
https://ess-ics.atlassian.net/wiki/display/DE/ESS+physical+DM+setup

## Installation Example
Please see the [README.md in DMonVM](./DMonVM/README.md).

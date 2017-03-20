essdm_scripts
======
ESS Physical Development Machine (DM) Setup Script, which is a *wrapper script* to reduce a human interaction while configuration of the ESS DM in order to minimize any potential failure senario. It follows the exact same procedure, which the Reference [1] suggests and it contains some possible improvement for the ansible configuration also. The possible improvement, once we verify as valuable, should be merged into the main ansible deployment stream. 

It is designed for the quick deployment of any type of ESS Physical DM. However, it also work well with any virtual machine (VM) environment with cumbersome VM configuration. 

## Goal
* This script should be used for the ESS Physical DM setup for CentOS 7.1 1503.
* This script should provide an easy solution to setup the DM quickly
* This script should focus *ONLY* one option (EEE installation)
* This script should provide an additional installation of several packages


## CentOS 7.1 (1503)
Download the CentOS 7.1 (1503) as following links :

### User Interface in most case
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

### Download and Execute the script as follows:

* Setup the EEE 1.8.2 
```
$ curl -L https://git.io/vi8DA -o dm_setup.bash
$ bash dm_setup.bash loc
```

* Setup CSS 4.4.1.2
```
$ curl -L https://git.io/vMyeU -o css_setup.bash
$ bash css_setup.bash
```

## Reference 
[1] https://ess-ics.atlassian.net/wiki/display/DE/ESS+physical+DM+setup

## Installation Example
Please see the [README.md in DMonVM](./DMonVM/README.md).
* Note that this example is always out-of-date and only is valid for a reference example. 

## Issues
* Mate-Desktop has the dependency issue
* CSS will be installed via css_setup.bash indepentently. 

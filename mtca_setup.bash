#!/bin/bash
#
#  Copyright (c) 2016 Jeong Han Lee
#
#  The script is free software: you can redistribute
#  it and/or modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation, either version 2 of the
#  License, or any newer version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License along with
#  this program. If not, see https://www.gnu.org/licenses/gpl-2.0.txt
#
# Author : Jeong Han Lee
# email  : jeonghan.lee@gmail.com
# Date   : 
# version : 0.0.3
#
# 
#
declare -gr SC_SCRIPT="$(realpath "$0")"
declare -gr SC_SCRIPTNAME="$(basename "$SC_SCRIPT")"
declare -gr SC_TOP="$(dirname "$SC_SCRIPT")"


set -a
. ${SC_TOP}/env.conf
set +a

. ${SC_TOP}/functions

# https://the.earth.li/~sgtatham/putty/latest/putty-0.67.tar.gz
# CentOS 7.1 1503
# Required packages 
# yum install cpan gtk2-devel 


function packages_install() {
    local func_name=${FUNCNAME[*]}; __ini_func ${func_name};
    local package_list=();

    package_list+="emacs tree screen telnet nano";
    package_list+=" ";
    package_list+="xterm xorg-x11-fonts-misc";
    package_list+=" ";
    package_list+="net-snmp net-snmp-utils"
    package_list+=" ";
    ## putty 
    package_list+="cpan gtk2-devel";
    package_list+=" ";
    ## ipmi
    package_list+="ipmitool OpenIPMI";
    package_list+=" ";
    
    ${SUDO_CMD} yum -y install ${package_list}; 

    __end_func ${func_name};
}

function putty_setup_build () {

    local func_name=${FUNCNAME[*]}; __ini_func ${func_name};
    local git_src_url=${PUTTY_GIT_URL};
    local git_src_name=${PUTTY_GIT_NAME};
    local git_src_dir=${SC_TOP}/${git_src_name};
    local git_src_tag=${PUTTY_GIT_TAG};
    
    printf "\n>>>"
    printf "\n>>> Now, we are going to clone and build the putty\n"
    git_clone  "${git_src_dir}" "${git_src_url}" "${git_src_name}" "${git_src_tag}";
    
    pushd ${git_src_dir};
    perl mkfiles.pl
    sh mkauto.sh
    # ./configure & make doesn't work, because of the following message:
    # *** No rule to make target 'doc/plink.1', needed by 'all-am'.  Stop.
    # So disable configure, and go unix directory directly
    # ./configure
    popd

    pushd ${git_src_dir}/unix;
    make -f Makefile.gtk
    #
    # mv only putty binary to /usr/local/bin directory manually.
    # and overwrite an existing file

    printf "\n>>>"
    printf "\n>>> Now, we are moving the putty to /usr/local/bin manually\n"
    ${SUDO_CMD} mv --force putty /usr/local/bin/ 
    popd

    __end_func ${func_name};
}


function MCH_management_network_setup() {

    local func_name=${FUNCNAME[*]}; __ini_func ${func_name};


    # This method is not permant, rebooting changes, so
    # should check the setup via nmcli with the real MTCA HW
    #
    ${SUDO_CMD} ifconfig ${MTCA_NET_DEV} ${MTCA_MANAGE_IP} netmask ${MTCA_MANAGE_NM} 
    ${SUDO_CMD} route add default gw ${MTCA_MANAGE_GW}
    ${SUDO_CMD} ifconfig ${MTCA_NET_DEV} up;

    __end_func ${func_name};
}

#MCH_management_network_setup


DO="$1"


case "$DO" in     

    pac) 
	${SUDO_CMD} -v;
	packages_install;
	;;
    putty)
	${SUDO_CMD} -v;
	packages_install;
	putty_setup_build;
	;;
    *) 	
	echo "">&2         
	echo "usage: $0 <arg>">&2 
	echo ""
        echo "          <arg> : info">&2 
	echo ""
	echo "          pac   : Linux packages for MTCA systems">&2
	echo "                  for putty, ipmi, and so on.... ">&2
        echo "" 
	echo "          putty : compile putty from git repository ">&2
	echo "                  ${PUTTY_GIT_URL}/${PUTTY_GIT_NAME}">&2
	echo "                  tag name : ${PUTTY_GIT_TAG}">&2
	echo "" 
    	echo "">&2 	
	exit 0         
	;; 
esac


exit

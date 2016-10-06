#!/bin/bash
#
#  Copyright (c) 2016 Jeong Han Lee
#  Copyright (c) 2016 European Spallation Source ERIC
#
#  The dm_setup.bash is free software: you can redistribute
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
# Shell  : dm_setup.bash
# Author : Jeong Han Lee
# email  : han.lee@esss.se
# Date   : 
# version : 0.9.5
#
# http://www.gnu.org/software/bash/manual/bashref.html#Bash-Builtins


# 
# PREFIX : SC_, so declare -p can show them in a place
# 
# Generic : Global vaiables - readonly
#
declare -gr SC_SCRIPT="$(realpath "$0")"
declare -gr SC_SCRIPTNAME="$(basename "$SC_SCRIPT")"
declare -gr SC_TOP="$(dirname "$SC_SCRIPT")"
declare -gr SC_LOGDATE="$(date +%Y%b%d-%H%M-%S%Z)"
declare -gr SC_IOCUSER="$(whoami)"

# Generic : Redefine pushd and popd to reduce their output messages
# 
function pushd() { builtin pushd "$@" > /dev/null; }
function popd()  { builtin popd  "$@" > /dev/null; }


function ini_func() { sleep 1; printf "\n>>>> You are entering in : %s\n" "${1}"; }
function end_func() { sleep 1; printf "\n<<<< You are leaving from %s\n" "${1}"; }

function checkstr() {
    if [ -z "$1" ]; then
	printf "%s : input variable is not defined \n" "${FUNCNAME[*]}"
	exit 1;
    fi
}


function printf_tee() {

    local input=${1};
    local target=${2};
    local command="";
    # If target exists, it will be overwritten.
    ${SUDO_CMD} printf "%s" "${input}" | ${SUDO_CMD} tee "${target}";
};



# Generic : Global variables for git_clone, git_selection, and others
# 
declare -g SC_SELECTED_GIT_SRC=""
declare -g SC_GIT_SRC_DIR=""
declare -g SC_GIT_SRC_NAME=""
declare -g SC_GIT_SRC_URL=""


# Generic : git_clone
#
# Required Global Variable
# - SC_GIT_SRC_DIR  : Input
# - SC_LOGDATE      : Input
# - SC_GIT_SRC_URL  : Input
# - SC_GIT_SRC_NAME : Input
# 
function git_clone() {

    local func_name=${FUNCNAME[*]}; ini_func ${func_name}

    checkstr ${SC_LOGDATE}
    checkstr ${SC_GIT_SRC_URL}
    checkstr ${SC_GIT_SRC_NAME}
    
    if [[ ! -d ${SC_GIT_SRC_DIR} ]]; then
	echo "No git source repository in the expected location ${SC_GIT_SRC_DIR}"
    else
	echo "Old git source repository in the expected location ${SC_GIT_SRC_DIR}"
	echo "The old one is renamed to ${SC_GIT_SRC_DIR}_${SC_LOGDATE}"
	mv  ${SC_GIT_SRC_DIR} ${SC_GIT_SRC_DIR}_${SC_LOGDATE}
    fi
    
    # Alwasy fresh cloning ..... in order to workaround any local 
    # modification in the repository, which was cloned before. 
    #
    git clone ${SC_GIT_SRC_URL}/${SC_GIT_SRC_NAME}

    end_func ${func_name}
}


# Generic : git_selection
#
# 1.0.3 : Thursday, October  6 15:34:12 CEST 2016
#
# Require Global vairable
# - SC_SELECTED_GIT_SRC  : Output
#
function git_selection() {

    local func_name=${FUNCNAME[*]}; ini_func ${func_name}

    local git_ckoutcmd=""
    local checked_git_src=""

    
    declare -i index=0
    declare -i master_index=0
    declare -i list_size=0
    declare -i selected_one=0
    declare -a git_src_list=()

    
    local n_tags=${1};

    # no set n_tags, set default 10
    
    if [[ ${n_tags} -eq 0 ]]; then
	n_tags=10;
    fi

    git_src_list+=("master")

    # git_tags=$(git describe --tags `git rev-list --tags --max-count=${n_tags}`);
    # git_exitstatus=$?
    # if [ $git_exitstatus = 0 ]; then
    # 	#
    # 	# (${}) and ($(command))  are important to separate output as an indiviaul arrar
    # 	#
    # 	git_src_list+=(${git_tags});
    # else
    # 	# In case, No tags can describe, use git tag instead of git describe
    # 	#
    # 	# fatal: No tags can describe '7fce903a82d47dec92012664648cacebdacd88e1'.
    # 	# Try --always, or create some tags.
    # doesn't work for CentOS7
    #    git_src_list+=($(git tag -l --sort=-refname  | head -n${n_tags}))
    # fi

    git_src_list+=($(git tag -l | sort -r | head -n${n_tags}))
    
    for tag in "${git_src_list[@]}"
    do
	printf "%2s: git src %34s\n" "$index" "$tag"
	let "index = $index + 1"
    done
    
    echo -n "Select master or one of tags which can be built, followed by [ENTER]:"

    # don't wait for 3 characters 
    # read -e -n 2 line
    read -e line
   
    # convert a string to an integer?
    # do I need this? 
    # selected_one=${line/.*}

    # Without selection number, type [ENTER], 0 is selected as default.
    #
    selected_one=${line}
    
    let "list_size = ${#git_src_list[@]} - 1"
    
    if [[ "$selected_one" -gt "$list_size" ]]; then
	printf "\n>>> Please select one number smaller than %s\n" "${list_size}"
	exit 1;
    fi
    if [[ "$selected_one" -lt 0 ]]; then
	printf "\n>>> Please select one number larger than 0\n" 
	exit 1;
    fi

    SC_SELECTED_GIT_SRC="$(tr -d ' ' <<< ${git_src_list[line]})"
    
    printf "\n>>> Selected %34s --- \n" "${SC_SELECTED_GIT_SRC}"
 
    echo ""
    if [ "$selected_one" -ne "$master_index" ]; then
	git_ckoutcmd="git checkout tags/${SC_SELECTED_GIT_SRC}"
	$git_ckoutcmd
	checked_git_src="$(git describe --exact-match --tags)"
	checked_git_src="$(tr -d ' ' <<< ${checked_git_src})"
	
	printf "\n>>> Selected : %s --- \n>>> Checkout : %s --- \n" "${SC_SELECTED_GIT_SRC}" "${checked_git_src}"
	
	if [ "${SC_SELECTED_GIT_SRC}" != "${checked_git_src}" ]; then
	    echo "Something is not right, please check your git reposiotry"
	    exit 1
	fi
    else
	git_ckoutcmd="git checkout ${SC_SELECTED_GIT_SRC}"
	$git_ckoutcmd
    fi
    end_func ${func_name}
 
}


#
# Specific only for this script : Global vairables - readonly
#
declare -gr SUDO_CMD="sudo"
declare -gr ANSIBLE_VARS="DEVENV_SSSD=false DEVENV_EEE=local DEVENV_CSS=true DEVENV_OPENXAL=false DEVENV_IPYTHON=false"
declare -gr RSYNC_EPICS_LOG="/tmp/rsync-epics.log"
declare -gr RSYNC_STARTUP_LOG="/tmp/rsync-startup.log"
declare -gr ANSIBLE_LOG="/var/log/ansible.log"
declare -g  GUI_STATUS=""


function print_logrotate_rule() {

    local logfile=${1};
    local user=${2};
    printf "%s {\nmissingok\nnotifempty\nsize 100k\nyearly\ncreate 0666 %s %s\n}" "${logfile}" "${user}" "${user}";
    
}

 

# Specific : preparation
#
# Require Global vairable
# - SUDO_CMD :  input
# - 

function preparation() {
    
    local func_name=${FUNCNAME[*]}; ini_func ${func_name};
    checkstr ${SUDO_CMD};

    # yum, repository
    declare -r yum_pid="/var/run/yum.pid"
    declare -r yum_repo_dir="/etc/yum.repos.d"
    declare -r rpmgpgkey_dir="/etc/pki/rpm-gpg/"
    declare -r repo_centos="CentOS-Base.repo"
    declare -r repo_epel="epel-19012016.repo"
    declare -r rpmgpgkey_epel="RPM-GPG-KEY-EPEL-7"
    declare -r ess_repo_url="https://artifactory01.esss.lu.se/artifactory/list/devenv/repositories/repofiles"

    # ansible 
    local ansible_cfg="/etc/ansible/ansible.cfg";
    local ansible_logrotate="/etc/logrotate.d/ansible";
    local ansible_logrotate_rule=$(print_logrotate_rule "${ANSIBLE_LOG}" "${SC_IOCUSER}");
    local ansilbe_log_init=$(printf "Note that ansible is not running currently,\nPlease wait for it, it will show up here soon....\nThis screen is updated every 2 seconds, to check the ansible log file in %s\n" "${ANSIBLE_LOG}");
    
    # Somehow, yum is running due to PackageKit, so if so, kill it
    #
    if [[ -e ${yum_pid} ]]; then
	${SUDO_CMD} kill -9 $(cat ${yum_pid})
    fi	
    
    # Remove PackageKit
    #
    ${SUDO_CMD} yum -y remove PackageKit 

    # Necessary to clean up the existent CentOS repositories
    # 
    ${SUDO_CMD} rm -rf ${yum_repo_dir}/*  
    ${SUDO_CMD} rm -rf ${rpmgpgkey_dir}/${rpmgpgkey_epel}
    
    # Download the ESS customized repository files and its RPM GPG KEY file
    #
    ${SUDO_CMD} curl -o ${yum_repo_dir}/${repo_centos}     ${ess_repo_url}/CentOS-Vault-7.1.1503.repo \
		     -o ${yum_repo_dir}/${repo_epel}       ${ess_repo_url}/${repo_epel} \
		     -o ${rpmgpgkey_dir}/${rpmgpgkey_epel} ${ess_repo_url}/${rpmgpgkey_epel}
        
    # Install "git and ansible" and logrotate for real works
    # 
    ${SUDO_CMD} yum -y install git ansible logrotate;

    # Enable the ansible log its path is /var/log/ansible.log
    ${SUDO_CMD} sed -i~ "s/#log_path =/log_path =/g" "${ansible_cfg}";

    # the initial log message
    printf_tee "${ansilbe_log_init}" "${ANSIBLE_LOG}";

    # change the permission 
    ${SUDO_CMD} chmod 666 ${ANSIBLE_LOG};
    
    # Enable the logrotate for ansible log
    
    printf_tee "${ansible_logrotate_rule}" "${ansible_logrotate}";

    end_func ${func_name};
}


function is-active-ui() {

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};
    
    GUI_STATUS="$(systemctl is-active graphical.target)";

    if [[ ${GUI_STATUS} = "active" ]]; then
	# If a system has the GUI, it returns "active"
	printf "\n User Interface was detected, \nexecute the monitoring terminal for the EEE Rsync status and install the required packages for them.\n\n";
	
	${SUDO_CMD} yum -y install xterm xorg-x11-fonts-misc
	nice xterm -title "EEE rsync status" -geometry 140x15+0+0   -e "nice watch -n 2 tail -n 10 ${RSYNC_EPICS_LOG}"&
	nice xterm -title "ANSIBLE   status" -geometry 140x15+0+190 -e "nice watch -n 2 tail -n 10 ${ANSIBLE_LOG}"&
    else
	# If a system has the NO GUI, it returns "inactive"
	printf "\n NO User Interface was detected, install the required packages to work around ansible errors\n\n";
	# In minimal image, minimal selection case : 
	# unzip doesn't be ready to use, force to install it
	#
	# Package "redhat-menus" creates the /etc/xdg/menus directory,
	# so ansible can copy their menu/* files into
	# /etc/xdg/menus/applications-merged
	#
	# Fortunately, these packages has no other heavy dependency on
	# other packages.
	# 
	${SUDO_CMD} yum -y install unzip redhat-menus xdg-utils
    fi

    end_func ${func_name};
}

function yum_gui(){

    local func_name=${FUNCNAME[*]}

    ini_func ${func_name}
	
    checkstr ${SUDO_CMD}


    ${SUDO_CMD} yum -y groupinstall "Gnome Desktop"
    ${SUDO_CMD} yum -y install lightdm
    #systemctl set-default graphical.target

    ${SUDO_CMD} systemctl disable gdm.service
    ${SUDO_CMD} systemctl enable lightdm.service
 
    end_func ${func_name}  
}



function yum_extra(){
    
    local func_name=${FUNCNAME[*]}

    ini_func ${func_name}
	
    checkstr ${SUDO_CMD}

    ${SUDO_CMD} yum -y install emacs screen

    # Now it is safe to run update by an user, let them do this job.
    
    ${SUDO_CMD} yum -y update
 
    end_func ${func_name}
}

 
function update_eeelocal_parameters() {

    local func_name=${FUNCNAME[*]}; ini_func ${func_name};
    checkstr ${SC_GIT_SRC_DIR}; checkstr ${SC_IOCUSER};

    local target_dir=${SC_GIT_SRC_DIR}/roles/EEElocal

    # Replace the default user (ess) with the user who executes this script (whoami)
    printf "... Replace the default user (ess) with \"%s\" in %s\n\n" "${SC_IOCUSER}" "${target_dir}/tasks/main.yml";

    # It is the bad idea to have the same "ess" in everywhere

    # is needed to transfer bash variable into sed
    sed -i~ "s/name=ess/name=${SC_IOCUSER}/g"   "${target_dir}/tasks/main.yml"
    sed -i  "s/a user ess/a user ${SC_IOCUSER}/g" "${target_dir}/tasks/main.yml"
    sed -i  "s/owner=ess/owner=${SC_IOCUSER}/g"   "${target_dir}/tasks/main.yml"
    
    # Replace the default user, and add log files for rsync-epics.service and rsync-startup.service
    printf "... Replace the default user (ess) with \"%s\" in %s \n\n... Add logfiles in %s\n" \
	   "${SC_IOCUSER}" "${target_dir}/files/rsync-{epics,startup}.service" \
	   "/tmp/rsync-{epics,startup}.log";

    
   
    local rsync_server="rsync://owncloud01.esss.lu.se:80";

    # Does CentOS EEE need ELDK EEE stuffs?
    #
    local rsync_general_option="--recursive --links --perms --times --timeout 120 --exclude='.git/' --exclude='SL6-x86_64/' --exclude='*eldk*/' ";

    local rsync_epics_option="${rsync_general_option} --log-file=${RSYNC_EPICS_LOG} ";
    local rsync_startup_option="${rsync_general_option} --log-file=${RSYNC_STARTUP_LOG} ";

    #
    # Rsync appends its log the existent log file, so I copy them in different time
    # Do we need to track down?

    # cp ${RSYNC_EPICS_LOG} ${RSYNC_EPICS_LOG}_${SC_LOGDATE}
    # cp ${RSYNC_STARTUP_LOG} ${RSYNC_STARTUP_LOG}_${SC_LOGDATE}

    # # Nullify them 
    # # 
    #cat /dev/null > ${RSYNC_EPICS_LOG};
    #cat /dev/null > ${RSYNC_STARTUP_LOG};

   # Enable the logrotate for ansible log

    declare -r rsync_epics_logrotate="/etc/logrotate.d/rsync_epics";
    declare -r rsync_startup_logrotate="/etc/logrotate.d/rsync_startup";

    declare rsync_epics_logrotate_rule=$(print_logrotate_rule "${RSYNC_EPICS_LOG}" "${SC_IOCUSER}");
    declare rsync_startup_logrotate_rule=$(print_logrotate_rule "${RSYNC_STARTUP_LOG}" "${SC_IOCUSER}");
        
    printf_tee "${rsync_epics_logrotate_rule}"   "${rsync_epics_logrotate}";
    printf_tee "${rsync_startup_logrotate_rule}" "${rsync_startup_logrotate}";
    
    
    # Add some information before showing actual log information of RSYNC
    # Only valid at the first instalation
    #
    cat > ${RSYNC_EPICS_LOG} <<EOF

Note that rsync-epics.servive is not running currently,
Please wait for it, it will show up here soooon......
This screen is updated every 2 seconds, to check the rsync log file
in ${RSYNC_EPICS_LOG}. 

EOF
    cat > ${RSYNC_STARTUP_LOG} <<EOF

Note that rsync-startup.servive is not running currently,
Please wait for it, it will show up here soooon......
This screen is updated every 2 seconds, to check the rsync log file
in ${RSYNC_EPICS_LOG}. 

EOF
    cat > ${target_dir}/files/rsync-epics.service <<EOF
[Unit]
Description=Script that syncs epics folder from the EEE server, hacked by dm_setup.bash

[Service]
ExecStart=/usr/bin/bash -c "rsync ${rsync_epics_option} ${rsync_server}/epics /opt/epics --chmod=Dugo=rwx,Fuog=rwx"
User=${SC_IOCUSER}

[Install]
WantedBy=multi-user.target

EOF
    
    cat > ${target_dir}/files/rsync-startup.service <<EOF
[Unit]
Description=Script that syncs startup folder from the EEE server

[Service]
ExecStart=/usr/bin/bash -c "rsync ${rsync_startup_option} ${rsync_server}/startup /opt/startup --chmod=Dugo=rwx,Fuog=rwx"
User=${SC_IOCUSER}

[Install]
WantedBy=multi-user.target
EOF

    end_func ${func_name};  
    
}



${SUDO_CMD} -v

#
# This "keep sudo" functionality
# doesn't work in the no-gui environment (minimal iso and minimal selection)
# One needs to type ones password twice during the entire setup procedure
#

while [ true ];
do
    ${SUDO_CMD} -n /bin/true;
    sleep 60;
    kill -0 "$$" || exit;
done 2>/dev/null &

declare -i tag_cnt=$1;


preparation

#
#
SC_GIT_SRC_NAME="ics-ans-devenv"
SC_GIT_SRC_URL="https://bitbucket.org/europeanspallationsource"
SC_GIT_SRC_DIR=${SC_TOP}/${SC_GIT_SRC_NAME}

#
#
git_clone
#
#
pushd ${SC_GIT_SRC_DIR}
#
#
git_selection  ${tag_cnt};

update_eeelocal_parameters
is-active-ui

ini_func "Ansible Playbook"
${SUDO_CMD} ansible-playbook -i "localhost," -c local devenv.yml --extra-vars="${ANSIBLE_VARS}"
end_func "Ansible Playbook"
#

popd


# #
# #
# #yum_gui
yum_extra
#

if [[ ${GUI_STATUS} = "inactive" ]]; then
    printf "\n>>>>>>>> NO USER INTERFACE  <<<<<<<< \n* One should wait for rsync EPICS processe \n  in order to check the ESS EPICS Environment.\n  tail -n 10 -f ${RSYNC_EPICS_LOG}\n\n";
     printf "* One can check the ansible log ${ANSIBLE_LOG}\n  whether the ansible returns OK or not. \n  tail -f ${ANSIBLE_LOG}\n\n";
fi

     
exit


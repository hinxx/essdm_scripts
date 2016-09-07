#!/bin/bash
# 
# Shell  : dm_setup.bash
# Author : Jeong Han Lee
# email  : han.lee@esss.se
# Date   : 
# version : 0.1.0 
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


# Generic : Redefine pushd and popd to reduce their output messages
# 
function pushd() { builtin pushd "$@" > /dev/null; }
function popd()  { builtin popd  "$@" > /dev/null; }


# Generic : Global variables for git_clone, git_selection, and others
# 
declare -g SC_SELECTED_GIT_SRC=""
declare -g SC_GIT_SRC_DIR=""
declare -g SC_GIT_SRC_NAME=""
declare -g SC_GIT_SRC_URL=""


# Generic : git_clone
#
#
function git_clone() {

    SC_GIT_SRC_DIR=${SC_TOP}/${SC_GIT_SRC_NAME}
    
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

}

# Generic : git_selection
# - requirement : Global vairable : SC_SELECTED_GIT_SRC 
#
function git_selection() {

    local git_ckoutcmd=""
    local checked_git_src=""
    declare -i index=0
    declare -i master_index=0
    declare -i list_size=0
    declare -i selected_one=0
    declare -a git_src_list=()


    git_src_list+=("master")
    git_src_list+=($(git tag -l | sort -n))
    
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

}


#
# Specific only for this script : Global vairables - readonly
#
declare -gr SUDO_CMD="sudo"
declare -gr YUM_REPO_DIR="/etc/yum.repos.d"
declare -gr RPMGPGKEY_DIR="/etc/pki/rpm-gpg/"
declare -gr REPO_CENTOS="CentOS-Base.repo"
declare -gr REPO_EPEL="epel-19012016.repo"
declare -gr RPMGPGKEY_EPEL="RPM-GPG-KEY-EPEL-7"
declare -gr ESS_REPO_URL="https://artifactory01.esss.lu.se/artifactory/list/devenv/repositories/repofiles"
declare -gr ANSIBLE_VARS="DEVENV_SSSD=false DEVENV_EEE=local DEVENV_CSS=true DEVENV_OPENXAL=false DEVENV_IPYTHON=false"


function yum_extra(){

    declare extra_package_list="emacs tree screen"

    ${SUDO_CMD} yum update
    ${SUDO_CMD} yum -y install lightdm
    ${SUDO_CMD} systemctl disable gdm.service
    ${SUDO_CMD} systemctl enable lightdm.service
    ${SUDO_CMD} yum -y install ${extra_package_list}


}


# Necessary to clean up the existent CentOS repositories
# 
${SUDO_CMD} rm -rf ${YUM_REPO_DIR}/*

# Download the ESS customized repository files and its RPM GPG KEY file
#
${SUDO_CMD} curl -o ${YUM_REPO_DIR}/${REPO_CENTOS}     ${ESS_REPO_URL}/CentOS-Vault-7.1.1503.repo
${SUDO_CMD} curl -o ${YUM_REPO_DIR}/${REPO_EPEL}       ${ESS_REPO_URL}/${REPO_EPEL}
${SUDO_CMD} curl -o ${RPMGPGKEY_DIR}/${RPMGPGKEY_EPEL} ${ESS_REPO_URL}/${RPMGPGKEY_EPEL}


# Install git and ansible for further steps
#
# -y Assume yes, doesn't work :)
# 
${SUDO_CMD} yum -y install git ansible


#
#
SC_GIT_SRC_NAME="ics-ans-devenv"
SC_GIT_SRC_URL="https://bitbucket.org/europeanspallationsource"

#
#
git_clone

#
#
pushd ${SC_GIT_SRC_DIR}

#
#
git_selection

${SUDO_CMD} ansible-playbook -i "localhost," -c local devenv.yml --extra-vars="${ANSIBLE_VARS}"

popd

yum_extra

exit


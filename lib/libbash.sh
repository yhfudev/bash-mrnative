#!/bin/bash
# -*- tab-width: 4; encoding: utf-8 -*-
#
#####################################################################
## @file
## @brief bash library
##   some useful bash script functions:
##     ssh
##     IPv4 address handle
##     install functions for RedHat/CentOS/Ubuntu/Arch
## @author Yunhui Fu <yhfudev@gmail.com>
## @copyright GPL v3.0 or later
## @version 1
##
#####################################################################
# detect if the ~/bin is included in environment variable $PATH
#echo $PATH | grep "~/bin"
#if [ ! "$?" = "0" ]; then
    #echo 'PATH=~/bin/:$PATH' >> ~/.bashrc
    #export PATH=~/bin:$PATH
#fi

#####################################################################
# the format of the segment file name, it seems 19 is the max value for gawk.
PRIuSZ="%019d"

#####################################################################
# becareful the danger execution, such as rm -rf ...
# use DANGER_EXEC=echo to skip all of such executions.
DANGER_EXEC=echo

if [ "${FN_LOG}" = "" ]; then
    FN_LOG=mrtrace.log
    #FN_LOG="/dev/stderr"
fi

## @fn mr_trace()
## @brief print a trace message
## @param msg the message
##
## pass a message to log file, and also to stdout
mr_trace() {
    echo "$(date +"%Y-%m-%d %H:%M:%S.%N" | cut -c1-23) [self=${BASHPID},$(basename $0)] $@" | tee -a ${FN_LOG} 1>&2
}

## @fn mr_exec_do()
## @brief execute a command line
## @param cmd the command line
##
## execute a command line, and also log the line
mr_exec_do() {
    mr_trace "$@"
    eval "$@"
}

## @fn mr_exec_skip()
## @brief skip a command line
## @param cmd the command line
##
## skip a command line, and also log the line
mr_exec_skip() {
    mr_trace "DEBUG (skip) $@"
}

MYEXEC=mr_exec_do
#MYEXEC=
if [ "$FLG_SIMULATE" = "1" ]; then
    MYEXEC=mr_exec_skip
fi

## @fn fatal_error()
## @brief log a fatal error
## @param msg the message
##
fatal_error() {
  PARAM_MSG="$1"
  mr_trace "Fatal error: ${PARAM_MSG}" 1>&2
  #exit 1
}

#####################################################################
EXEC_SSH="$(which ssh) -oBatchMode=yes -CX"
EXEC_SCP="$(which scp)"
EXEC_AWK="$(which awk)"
EXEC_SED="$(which sed)"

EXEC_SUDO=sudo
if [ "`whoami`" = "root" ]; then
    EXEC_SUDO=
fi

#####################################################################
# System distribution detection
EXEC_APTGET="${EXEC_SUDO} $(which apt-get)"

OSTYPE=unknown
OSDIST=unknown
OSVERSION=unknown
OSNAME=unknown

#####################################################################
## @fn detect_os_type()
## @brief detect the OS type
##
## detect the OS type, such as RedHat, Debian, Ubuntu, Arch, OpenWrt etc.
detect_os_type() {
    test -e /etc/debian_version && OSDIST="Debian" && OSTYPE="Debian"
    grep Ubuntu /etc/lsb-release &> /dev/null && OSDIST="Ubuntu" && OSTYPE="Debian"
    test -e /etc/redhat-release && OSTYPE="RedHat"
    test -e /etc/fedora-release && OSTYPE="RedHat"
    which pacman &> /dev/null && OSTYPE="Arch"
    which opkg &> /dev/null && OSTYPE="OpenWrt"
    which emerge &> /dev/null && OSTYPE="Gentoo"
    which zypper &> /dev/null && OSTYPE="SUSE"
    which rug &> /dev/null && OSTYPE="Novell"
    #which smart && OSTYPE="Smart" # http://labix.org/smart

    OSDIST=
    OSVERSION=
    OSNAME=

    case "$OSTYPE" in
    Debian)
        if ! which lsb_release &> /dev/null; then
            $EXEC_APTGET install -y lsb-release
        fi
        ;;

    RedHat)
        EXEC_APTGET="${EXEC_SUDO} `which yum`"
        #yum whatprovides */lsb_release
        if ! which lsb_release &> /dev/null; then
            $EXEC_APTGET --skip-broken install -y redhat-lsb-core
        fi
        ;;

    Arch)
        if [ -f "/etc/os-release" ]; then
            OSDIST=$(cat /etc/os-release | grep ^ID= | awk -F= '{print $2}')
            OSVERSION=1
            OSNAME=arch
        fi
        ;;

    OpenWrt)
        if [ -f "/etc/os-release" ]; then
            OSDIST=$(cat /etc/os-release | grep ^ID= | awk -F= '{print $2}')
            OSVERSION=1
            OSNAME=openwrt
        fi
        ;;
    *)
        mr_trace "Error: Not supported OS: $OSTYPE"
        exit 0
        ;;
    esac

    if which lsb_release &> /dev/null; then
        OSDIST=$(lsb_release -is)
        OSVERSION=$(lsb_release -rs)
        OSNAME=$(lsb_release -cs)
    fi
    if [ "${OSDIST}" = "" ]; then
        mr_trace "Error: Not found lsb_release."
    fi
    mr_trace "Detected $OSTYPE system: $OSDIST $OSVERSION $OSNAME"
    export OSTYPE
    export OSDIST
    export OSVERSION
    export OSNAME
}


#####################################################################
## @fn hput()
## @brief put a value to hash table
## @param key the key
## @param value the value
##
## put a value to hash table
hput() {
  local KEY=`echo "$1" | tr '[:punct:][:blank:]' '_'`
  eval export hash"$KEY"='$2'
}

## @fn hget()
## @brief get a value from hash table
## @param key the key
##
## get a value from hash table
hget() {
  local KEY=`echo "$1" | tr '[:punct:][:blank:]' '_'`
  eval echo '${hash'"$KEY"'#hash}'
}

## @fn hiter()
## @brief list all of values in the hash table
##
hiter() {
    for h in $(eval echo '${!'$1'*}') ; do
        local key=${h#$1*}
        echo "$key=`hget $key`"
    done
}

## @fn ospkgset()
## @brief set package name mapping
## @param key the key package name (Debian)
## @param vredhat the map package name for RedHat
## @param varch the map package name for Arch
##
## set package name mapping for debian,redhat,arch
ospkgset() {
    local PARAM_KEY=$1
    shift
    local PARAM_REDHAT=$1
    shift
    local PARAM_ARCH=$1
    shift
    hput "pkg_RedHat_$PARAM_KEY" "$PARAM_REDHAT"
    hput "pkg_Arch_$PARAM_KEY" "$PARAM_ARCH"
}

## @fn ospkgget()
## @brief get package name mapping
## @param os the OS name. RedHat or Arch
## @param key the key package name (Debian)
##
## get package name mapping for debian,redhat,arch
ospkgget() {
    local PARAM_OS=$1
    shift
    local PARAM_KEY=$1
    shift
    if [ "$PARAM_OS" = "Debian" ]; then
        echo "${PARAM_KEY}"
        return
    fi
    hget "pkg_${PARAM_OS}_${PARAM_KEY}"
}

# Debian/Ubuntu, RedHat/Fedora/CentOS, Arch, OpenWrt
ospkgset apt-get            yum                 pacman              opkg
ospkgset apt-file           yum                 pkgfile
ospkgset u-boot-tools       uboot-tools         uboot-tools
ospkgset mtd-utils          mtd-utils           mtd-utils
ospkgset initramfs-tools    initramfs-tools     mkinitcpio
ospkgset build-essential    'Development Tools' base-devel
ospkgset devscripts         rpmdevtools         abs
ospkgset lsb-release        redhat-lsb-core     redhat-lsb-core
ospkgset openssh-client     openssh-clients     openssh-clients
ospkgset parted             parted              parted
ospkgset subversion         svn                 subversion
ospkgset git-all            git                 git
ospkgset dhcp3-server       dhcp                dhcp
ospkgset dhcp3-client       dhcp                dhcpcd
ospkgset tftpd-hpa          tftp-server         tftp-hpa
ospkgset syslinux           syslinux            syslinux
ospkgset nfs-kernel-server  nfs-utils           nfs-utils
ospkgset nfs-common         nfs-utils           nfs-utils
ospkgset bind9              bind                bind
ospkgset portmap            portmap             ""
ospkgset libncurses-dev     ncurses-devel       ncurses
ospkgset kpartx             kpartx              multipath-tools
ospkgset lib32stdc++6       libstdc++.i686      lib32-libstdc++5
#                           libstdc++.so.6
ospkgset lib32z1            zlib.i686           lib32-zlib
ospkgset libjpeg62-turbo-dev libjpeg62-turbo    libjpeg-turbo

ospkgset u-boot-tools       uboot-tools         uboot-tools
ospkgset bsdtar             bsdtar              libarchive

ospkgset uuid-runtime       util-linux          util-linux

ospkgset wiringpi           wiringpi            wiringpi-git

# fixme: fedora: pixz?
ospkgset pixz               xz                  pixz

# fix me: fedora has no equilant to qemu-user-static!  qemu-arm-static
ospkgset qemu-user-static   qemu-user           qemu-user-static-exp
#ospkgset qemu qemu qemu # gentoo: app-emulation/qemu

# fedora, qemu provides qemu.binfmt, and the kernel already contains binfmt support
ospkgset binfmt-support     qemu                binfmt-support

ospkgset apache2            httpd               apache
#ospkgset apache2-mpm-prefork
#ospkgset apache2-utils
ospkgset libapache2-mod-php5 php-apache         php-apache
ospkgset php5-common        php                 php-apache
#ospkgset php5-cli           php
#ospkgset php5-mcrypt
#ospkgset php5-mysql         php-mysql
#ospkgset php5-pgsql
ospkgset php5-sqlite        php-sqlite          php-sqlite
#ospkgset php5-dev
#ospkgset php5-curl
#ospkgset php5-idn
ospkgset php5-imagick       php-imagick         php-imagick
#ospkgset php5-imap
#ospkgset php5-memcache
#ospkgset php5-ps
#ospkgset php5-pspell
#ospkgset php5-recode
#ospkgset php5-tidy
#ospkgset php5-xmlrpc
#ospkgset php5-xsl
#ospkgset php5-json
#ospkgset php5-gd            php-gd
#ospkgset php5-snmp          php-snmp
#ospkgset php-versioncontrol-svn
#ospkgset php-pear           php-pear
ospkgset snmp               net-snmp-utils      net-snmp
ospkgset graphviz           graphviz            graphviz
ospkgset php5-mcrypt        php-mcrypt          php-mcrypt
ospkgset subversion         subversion          subversion
ospkgset mysql-server       mysql-server        mariadb
ospkgset mysql-client       mysql               mariadb-clients
#ospkgset mysql-perl         ?                   perl-dbd-mysql
#ospkgset rrdtool            rrdtool
#ospkgset fping              fping
ospkgset imagemagick        ImageMagick         imagemagick
ospkgset whois              jwhois              whois
ospkgset mtr-tiny           mtr                 mtr
ospkgset nmap               nmap                nmap
ospkgset ipmitool           ipmitool            ipmitool
ospkgset python-mysqldb     MySQL-python        mysql-python

ospkgset gpsd               gpsd                gpsd
ospkgset gpsd-clients       gpsd-clients        gpsd

## @fn patch_centos_gawk()
## @brief compile gawk with switch support
## @param os the OS name. RedHat or Arch
## @param key the key package name (Debian)
##
## compile gawk with switch support and install it to system.
##   WARNING: the CentOS boot program depend the awk, and if the system upgrade the gawk again,
##   new installed gawk will not support
patch_centos_gawk() {
    yum -y install rpmdevtools readline-devel #libsigsegv-devel
    yum -y install gcc byacc
    rpmdev-setuptree

    #FILELIST="gawk.spec gawk-3.1.8.tar.bz2 gawk-3.1.8-double-free-wstptr.patch gawk-3.1.8-syntax.patch"
    #URL="http://archive.fedoraproject.org/pub/archive/fedora/linux/updates/14/SRPMS/gawk-3.1.8-3.fc14.src.rpm"
    FILELIST="gawk.spec gawk-4.0.1.tar.gz"
    URL="http://archive.fedoraproject.org/pub/archive/fedora/linux/updates/17/SRPMS/gawk-4.0.1-1.fc17.src.rpm"
    cd ~/rpmbuild/SOURCES/; rm -f ${FILELIST}; cd - > /dev/null; rm -f ${FILELIST}
    wget -c "${URL}" -O ~/rpmbuild/SRPMS/$(basename "${URL}")
    rpm2cpio ~/rpmbuild/SRPMS/$(basename "${URL}") | cpio -div
    mv ${FILELIST} ~/rpmbuild/SOURCES/
    sed -i 's@configure @configure --enable-switch --disable-libsigsegv @g' ~/rpmbuild/SOURCES/$(echo "${FILELIST}" | awk '{print $1}')
    sed -i 's@--with-libsigsegv-prefix=[^ ]*@@g' ~/rpmbuild/SOURCES/$(echo "${FILELIST}" | awk '{print $1}')
    sed -i 's@Conflicts: filesystem@#Conflicts: filesystem@g' ~/rpmbuild/SOURCES/$(echo "${FILELIST}" | awk '{print $1}')

    # we don't install gawk to system's directory
    # instead, we install the new gawk in ~/bin
    #rpmbuild -bb --clean ~/rpmbuild/SOURCES/$(echo "${FILELIST}" | awk '{print $1}')
    ##sudo rpm -U --force ~/rpmbuild/RPMS/$(uname -i)/gawk-4.0.1-1.el6.$(uname -i).rpm
    #sudo rpm -U --force ~/rpmbuild/RPMS/$(uname -p)/gawk-4.0.1-1.el6.$(uname -p).rpm
    #ln -s $(which gawk) /bin/gawk
    #ln -s $(which gawk) /bin/awk
    rpmbuild -bb ~/rpmbuild/SOURCES/$(echo "${FILELIST}" | awk '{print $1}')
    mkdir -p ~/bin/
    cp ~/rpmbuild/BUILD/gawk-4.0.1/gawk ~/bin/
    ln -s ~/bin/gawk ~/bin/awk
    rm -rf ~/rpmbuild/BUILD/gawk-4.0.1/
}

## @fn download_extract_2tmp_syslinux()
## @brief download syslinux files
##
## download the syslinux files for non-x86 platforms
download_extract_2tmp_syslinux() {
    PKG=""
    DN_ORIG12=$(pwd)
    cd /tmp
    DATE1=$(date +%Y-%m-%d)
    rm -f index.html*
    URL_ORIG="https://www.archlinux.org/packages/core/i686/syslinux/download/"
    URL_REAL=$(wget --no-check-certificate ${URL_ORIG} 2>&1 | grep pkg | grep $DATE1 | awk '{print $3}')
    FN_SYSLI=$(basename ${URL_REAL})
    if [ ! -f "${FN_SYSLI}" ]; then
        if [ ! -f index.html ]; then
            mr_trace "Error: not found downloaded file from ${URL_ORIG}(${URL_REAL})"
        else
            mr_trace "[DBG] rename index.html to ${FN_SYSLI}"
            mv index.html "${FN_SYSLI}"
        fi
    fi
    if [ ! -f "${FN_SYSLI}" ]; then
        mr_trace "Error: not found file ${FN_SYSLI}"
        exit 0
    fi
    tar -xf "${FN_SYSLI}"
    cd "${DN_ORIG12}"
}

## @fn yum_groupinfo()
## @brief a wrap for "yum groupinfo" to return correct value
## @param name the package names
yum_groupinfo() {
    PARAM_PKG=$1
    yum groupinfo "${PARAM_PKG}" 2>&1 | grep -i "Warning: " | grep -i "not exist." > /dev/null
    if [ "$?" = "0" ]; then
        #return 1
        mkdir /a/b/c/d/e/f/
    else
        #return 0
        mkdir -p /tmp
    fi
}

## @fn yum_groupcheck()
## @brief check if a group installed
## @param name the package names
yum_groupcheck() {
    PARAM_PKG=$1
    yum_groupinfo "${PARAM_PKG}"
    if [ ! "$?" = "0" ]; then
        mkdir /a/b/c/d/e/f/
    else
        yes no | yum groupupdate "${PARAM_PKG}" 2>&1 | grep -i "Dependent packages" > /dev/null
        if [ "$?" = "0" ]; then
            #return 1
            mkdir /a/b/c/d/e/f/
        else
            #return 0
            mkdir -p /tmp
        fi
    fi
}

## @fn check_available_package()
## @brief check if the packages exist
## @param name the package names
check_available_package() {
    PARAM_NAME=$*
    #INSTALLER=`ospkgget $OSTYPE apt-get`
    EXEC_CHKPKG="dpkg -s"
    EXEC_CHKGRP="dpkg -s"
    case "$OSTYPE" in
    RedHat)
        EXEC_CHKPKG="yum info"
        EXEC_CHKGRP="yum info"
        ;;

    Arch)
        EXEC_CHKPKG="pacman -Si"
        EXEC_CHKGRP="pacman -Sg"
        ;;
    Gentoo)
        EXEC_CHKPKG="emerge -S"
        EXEC_CHKGRP="emerge -S"
        ;;
    *)
        mr_trace "[ERR] Not supported OS: $OSTYPE"
        exit 0
        ;;
    esac
    #mr_trace "enter arch for pkgs: ${PARAM_NAME}"
    for i in $PARAM_NAME ; do
        #mr_trace "enter loop arch for pkg: ${i}"
        PKG=$(ospkgget $OSTYPE $i)
        if [ "${PKG}" = "" ]; then
            PKG="$i"
        fi
        mr_trace "check available pkg: ${PKG}"
        ${EXEC_CHKPKG} "${PKG}" > /dev/null
        if [ ! "$?" = "0" ]; then
            ${EXEC_CHKGRP} "${PKG}" > /dev/null
            if [ ! "$?" = "0" ]; then
                echo "fail"
                mr_trace "check available pkg: ${PKG} return fail!"
                return
            fi
        fi
    done
    mr_trace "check available pkg: ${PARAM_NAME} return ok!"
    echo "ok"
}

## @fn check_installed_package()
## @brief check if the packages installed
## @param name the package names
check_installed_package() {
    PARAM_NAME=$*
    #INSTALLER=`ospkgget $OSTYPE apt-get`
    EXEC_CHKPKG="dpkg -s"
    EXEC_CHKGRP="dpkg -s"
    case "$OSTYPE" in
    RedHat)
        EXEC_CHKPKG="rpm -qi"
        EXEC_CHKGRP="yum_groupcheck"
        ;;

    Arch)
        EXEC_CHKPKG="pacman -Qi"
        EXEC_CHKGRP="pacman -Qg"
        ;;
    Gentoo)
        EXEC_CHKPKG="emerge -pv" # and emerge -S
        EXEC_CHKGRP="emerge -pv" # and emerge -S
        ;;
    *)
        mr_trace "[ERR] Not supported OS: $OSTYPE"
        exit 0
        ;;
    esac
    #mr_trace "enter arch for pkgs: ${PARAM_NAME}"
    for i in $PARAM_NAME ; do
        #mr_trace "enter loop arch for pkg: ${i}"
        PKG0=$(echo "$i" | awk -F\> '{print $1}')
        PKG=$(ospkgget $OSTYPE $PKG0)
        if [ "${PKG}" = "" ]; then
            PKG="${PKG0}"
        fi
        mr_trace "check installed pkg: ${PKG}"
        ${EXEC_CHKPKG} "${PKG}" > /dev/null
        if [ ! "$?" = "0" ]; then
            ${EXEC_CHKGRP} "${PKG}" > /dev/null
            if [ ! "$?" = "0" ]; then
                echo "fail"
                mr_trace "check installed pkg: ${PKG} return fail!"
                return
            fi
        fi
    done
    mr_trace "check installed pkg: ${PARAM_NAME} return ok!"
    echo "ok"
#set +x
}

## @fn install_package()
## @brief install software packages
## @param name the package names
##
## using the package name of Debian, and convert to the name of the underlying distribution.
## the package gawk or syslinux will be handled in a different way
install_package() {
    local PARAM_NAME=$*
    local INSTALLER=`ospkgget $OSTYPE apt-get`
    local PKGLST=
    local FLG_GAWK_RH=0
    for i in $PARAM_NAME ; do
        PKG=$(ospkgget $OSTYPE $i)
        if [ "${PKG}" = "" ]; then
            PKG="$i"
        fi
        mr_trace "try to install package: $PKG($i)"
        if [ "$i" = "gawk" ]; then
            if [ "$OSTYPE" = "RedHat" ]; then
                mr_trace "[DBG] patch gawk to support 'switch'"
                echo | awk '{a = 1; switch(a) { case 0: break; } }'
                if [ $? = 1 ]; then
                    FLG_GAWK_RH=1
                    PKG="rpmdevtools libsigsegv-devel readline-devel"
                fi
            fi
        fi

        mr_trace "[DBG] OSTYPE = $OSTYPE"
        if [ "$OSTYPE" = "Arch" ]; then
            if [ "$i" = "portmap" ]; then
                mr_trace "[DBG] Ignore $i"
                PKG=""
            fi
            if [ "$i" = "syslinux" ]; then
                MACH=$(uname -m)
                case "$MACH" in
                x86_64|i386|i686)
                    mr_trace "[DBG] use standard method"
                    ;;

                *)
                    mr_trace "[DBG] Arch $MACH yet another installation of $i"
                    mr_trace "[DBG] Download package for $MACH"
                    download_extract_2tmp_syslinux
                    ;;
                esac
            fi
        fi
        PKGLST="${PKGLST} ${PKG}"
    done

    INST_OPTS=""
    case "$OSTYPE" in
    Debian)
        INST_OPTS="install -y --force-yes"
        ;;

    RedHat)
        INST_OPTS="install -y"
        ;;

    Arch)
        INST_OPTS="-S"
        # install loop module
        lsmod | grep loop > /dev/null
        if [ "$?" != "0" ]; then
            modprobe loop > /dev/null

            grep -Hrn loop /etc/modules-load.d/
            if [ "$?" != "0" ]; then
                echo "loop" > /etc/modules-load.d/tftpboot.conf
            fi
        fi
        ;;
    *)
        mr_trace "[ERR] Not supported OS: $OSTYPE"
        exit 0
        ;;
    esac

    mr_trace "try to install packages: ${PKGLST}"
    ${EXEC_SUDO} $INSTALLER ${INST_OPTS} ${PKGLST}
    if [ ! "$?" = "0" ]; then
        echo "fail"
    fi

    if [ "${FLG_GAWK_RH}" = "1" ]; then
        patch_centos_gawk
    fi
    echo "ok"
}

## @fn install_arch_yaourt()
## @brief install yaourt for Arch Linux
install_arch_yaourt() {
    wget https://aur.archlinux.org/packages/ya/yaourt/yaourt.tar.gz

    pacman -Qi package-query >> /dev/null
    if [ ! "$?" = "0" ]; then
        wget https://aur.archlinux.org/packages/pa/package-query/package-query.tar.gz
        tar -xf package-query.tar.gz \
            && cd package-query \
            && makepkg -Asf \
            && ${EXEC_SUDO} pacman -U ./package-query-*.xz \
            && cd ..
    fi

    tar -xf yaourt.tar.gz \
        && cd yaourt \
        && makepkg -Asf \
        && ${EXEC_SUDO} pacman -U ./yaourt-*.xz \
        && cd ..
}

## @fn install_package_alt()
## @brief install alternative packages
## @param name the package names
install_package_alt() {
    local PARAM_NAME=$*
    local INSTALLER=`ospkgget $OSTYPE apt-get`

    local INST_OPTS=""
    case "$OSTYPE" in
    Debian)
        INST_OPTS="install -y --force-yes"
        ;;

    RedHat)
        INST_OPTS="groupinstall -y"
        ;;

    Arch)
        if [ ! -x "$(which yaourt)" ]; then
            install_arch_yaourt >> "${FN_LOG}"
        fi
        if [ ! -x "$(which yaourt)" ]; then
            echo "Error in get yaourt!" >> "${FN_LOG}"
            exit 1
        fi
        INSTALLER="yaourt"
        INST_OPTS=""
        ;;
    *)
        echo "[ERR] Not supported OS: $OSTYPE" >> "${FN_LOG}"
        exit 0
        ;;
    esac
    for i in $PARAM_NAME ; do
        PKG=$(ospkgget $OSTYPE $i)
        if [ "${PKG}" = "" ]; then
            PKG="$i"
        fi
        echo "try to install 3rd packages: ${PKG}" >> "${FN_LOG}"
        ${EXEC_SUDO} $INSTALLER ${INST_OPTS} "${PKG}" >> "${FN_LOG}"
        if [ ! "$?" = "0" ]; then
            echo "fail"
            return
        fi
    done
    echo "ok"
}

## @fn check_install_package()
## @brief check if command is not exist, then install the package
## @param bin the binary name
## @param pkg the package name
check_install_package() {
    local PARAM_BIN=$1
    shift
    local PARAM_PKG=$1
    shift
    if [ ! -x "${PARAM_BIN}" ]; then
        install_package "${PARAM_PKG}"
    fi
}

detect_os_type 1>&2

#for h in ${!hash*}; do indirect=$hash$h; echo ${!indirect}; done
#hiter hash
#install_package apt-get subversion
#exit 0
######################################################################
EXEC_SSH="$(which ssh)"
if [ ! -x "${EXEC_SSH}" ]; then
  mr_trace "[DBG] Try to install ssh."
  install_package openssh-client
fi

EXEC_SSH="$(which ssh)"
if [ ! -x "${EXEC_SSH}" ]; then
  mr_trace "[ERR] Not exist ssh!"
  exit 1
fi
EXEC_SSH="$(which ssh) -oBatchMode=yes -CX"

EXEC_AWK="$(which gawk)"
if [ ! -x "${EXEC_AWK}" ]; then
  mr_trace "[DBG] Try to install gawk."
  install_package gawk
fi

EXEC_AWK="$(which gawk)"
if [ ! -x "${EXEC_AWK}" ]; then
  mr_trace "[ERR] Not exist awk!"
  exit 1
fi

######################################################################
# ssh

## @fn ssh_check_id_file()
## @brief generate the cert of localhost
ssh_check_id_file() {
    if [ ! -f ~/.ssh/id_rsa.pub ]; then
        mr_trace "generate id ..."
        mkdir -p ~/.ssh/
        ssh-keygen
    fi
}

## @fn ssh_ensure_connection()
## @brief ensure the local id_rsa.pub copied to remote host to setup the SSH connection without key
ssh_ensure_connection() {
    local PARAM_SSHURL="${1}"
    mr_trace "[DBG] test host: ${PARAM_SSHURL}"
    $EXEC_SSH "${PARAM_SSHURL}" "ls > /dev/null"
    if [ ! "$?" = "0" ]; then
        mr_trace "[DBG] copy id to ${PARAM_SSHURL} ..."
        ssh-copy-id -i ~/.ssh/id_rsa.pub "${PARAM_SSHURL}"
    else
        mr_trace "[DBG] pass id : ${PARAM_SSHURL}."
    fi
    if [ "$?" = "0" ]; then
        $EXEC_SSH "${PARAM_SSHURL}" "yum -y install xauth libcanberra-gtk2 dejavu-lgc-sans-fonts"
    fi
}

######################################################################
# Math Lib:

# 最小公倍数 (Least Common Multiple, LCM)

## @fn gcd()
## @brief Greatest Common Divisor, GCD
## @param num1 number 1
## @param num2 number 2
##
## example:
## gcd 6 15
## 30
gcd() {
    local PARAM_NUM1=$1
    shift
    local PARAM_NUM2=$1
    shift

    local NUM1=$PARAM_NUM1
    local NUM2=$PARAM_NUM2
    if [ $(echo | awk -v A=$NUM1 -v B=$NUM2 '{ if (A<B) {print 1;} else {print 0;} }') = 1 ]; then
        NUM1=$PARAM_NUM2
        NUM2=$PARAM_NUM1
    fi

    a=$NUM1
    b=$NUM2
    while (( $b != 0 ));do
        tmp=$(($a % $b))
        a=$b
        b=$tmp
    done
    #echo "GDC=$a"
    #echo "LCM=$(($NUM1 * $NUM2 / $a))"
    echo $(($NUM1 * $NUM2 / $a))
}

######################################################################
# IPv4 address Lib:
die() {
    mr_trace "Error: $@"
    exit 1
}

IPv4_check_ok() {
    local IFS=.
    set -- $1
    [ $# -eq 4 ] || return 2
    local var
    for var in $* ;do
        [ $var -lt 0 ] || [ $var -gt 255 ] && return 3
    done
    echo $(( ($1<<24) + ($2<<16) + ($3<<8) + $4))
}

IPv4_from_int() {
    echo $(($1>>24)).$(($1>>16&255)).$(($1>>8&255)).$(($1&255))
}

# convert the string to IPv4 configurations
# Example:
#   IPv4_convert "192.168.1.15/17"
#echo "netIP=$OUTPUT_IPV4_IP"
#echo "netMASK=$OUTPUT_IPV4_MASK"
#echo "netBCST=$OUTPUT_IPV4_BROADCAST"
#echo "network=$OUTPUT_IPV4_NETWORK"
#echo "first ip=${OUTPUT_IPV4_FIRSTIP}"
#echo "DHCP_UNKNOW=${OUTPUT_IPV4_DHCP_UNKNOW_RANGE}"
#echo "DHCP_KNOW=${OUTPUT_IPV4_DHCP_KNOW_RANGE}"
IPv4_convert() {
    local PARAM_IP="$1"
    shift

    netIP=$(echo $PARAM_IP | awk -F/ '{print $1}')
    intIP=$(IPv4_check_ok $netIP) || die "Submited IP: '$netIP' is not an IPv4 address."

    LEN=$(echo $PARAM_IP | awk -F/ '{print $2}')
    intMASK0=$((  ( (1<<$LEN) - 1 ) << ( 32 - $LEN )  ))
    #echo "intMASK0=$intMASK0"
    netMASK=$(  IPv4_from_int $intMASK0  )
    intMASK=$(IPv4_check_ok $netMASK) || die "Submited Mask: '$netMASK' not IPv4."
    if [ ! "$intMASK0" = "$intMASK" ]; then
        die "Mask convert error: 0-'$intMASK0'; 1-'$intMASK'"
    fi

    intBCST=$((  intIP | intMASK ^ ( (1<<32) - 1 )  ))
    intBASE=$((  intIP & intMASK  ))
    netBCST=$(  IPv4_from_int $((  intIP | intMASK ^ ( (1<<32) - 1 )  ))  )
    netBASE=$(  IPv4_from_int $((  intIP & intMASK  ))  )

    OUTPUT_IPV4_IP="$netIP"
    OUTPUT_IPV4_MASK="$netMASK"
    OUTPUT_IPV4_BROADCAST="$netBCST"
    OUTPUT_IPV4_NETWORK="$netBASE"
    OUTPUT_IPV4_FIRSTIP=$(  IPv4_from_int $((  intBASE + 1  ))  )

    RESERV_RATIO="4/5"
    #mr_trace "LEN = $LEN"
    #mr_trace "RESERV_RATIO = $RESERV_RATIO"
    SZ=$((  ( 1 << ( 32 - $LEN ) ) - 2  ))
    #mr_trace "SZ-0 = $SZ"
    SZ2=$((  ( $SZ - $SZ * $RESERV_RATIO ) * 3 / 4  ))
    #mr_trace "SZ2-0 = $SZ2"
    [ $SZ2 -lt 100 ] || SZ2=100
    #mr_trace "SZ2-1 = $SZ2"
    [ $SZ2 -gt 0 ] || SZ2=1
    #mr_trace "SZ2-2 = $SZ2"
    SZ1=$((  ( $SZ - $SZ * $RESERV_RATIO ) - $SZ2  ))
    #mr_trace "SZ1-0 = $SZ1"
    [ $SZ1 -lt 10 ] || SZ1=10
    #mr_trace "SZ1-1 = $SZ1"
    [ $SZ1 -gt 0 ] || SZ1=1
    #mr_trace "SZ1-2 = $SZ1"
    SZLEFT=$((  $SZ - $SZ1 - $SZ2  ))
    #mr_trace "SZLEFT-0 = $SZLEFT"
    [ $SZLEFT -gt 0 ] || SZLEFT=$((  ( $SZ / 3 + $SZ ) * $RESERV_RATIO  ))
    #mr_trace "SZLEFT-1 = $SZLEFT"
    [ $SZLEFT -gt 0 ] || SZLEFT=1
    #mr_trace "SZLEFT-2 = $SZLEFT"
    SZ1=$((  ( $SZ - $SZLEFT ) / 2  ))
    [ $SZ1 -lt 10 ] || SZ1=10
    [ $SZ1 -gt 0 ] || SZ1=0
    SZ2=$((  $SZ - $SZLEFT - $SZ1  ))
    [ $SZ2 -lt 100 ] || SZ2=100
    [ $SZ2 -gt 0 ] || SZ2=0
    SZLEFT=$((  $SZ - $SZ1 - $SZ2  ))
    #mr_trace SZ1=$SZ1
    #mr_trace SZ2=$SZ2
    #mr_trace SZLEFT=$SZLEFT

    MID=$((  $intBCST - $SZ2 - 1 ))
    [ $MID -lt $intBCST ] || MID=$((  $intBCST - 1  ))

    #OUTPUT_IPV4_DHCP_ROUTER=
    #  IP unknown range
    OUTPUT_IPV4_DHCP_UNKNOW_RANGE="$(  IPv4_from_int $(( $MID + 1 )) )    $(  IPv4_from_int $((  $intBCST - 1  ))  )"
    #  IP known range
    OUTPUT_IPV4_DHCP_KNOW_RANGE="$(  IPv4_from_int $((  $intBASE + 1 + $SZ1  ))  )    $(  IPv4_from_int $((  $MID  ))  )"
}

#####################################################################
# http://blog.n01se.net/blog-n01se-net-p-145.html
# redirect tty fds to /dev/null
redirect_std() {
    [[ -t 0 ]] && exec </dev/null
    [[ -t 1 ]] && exec >/dev/null
    [[ -t 2 ]] && exec 2>/dev/null
}

# close all non-std* fds
close_fds() {
    eval exec {3..255}\>\&-
}

# full daemonization of external command with setsid
daemonize() {
    (                   # 1. fork
        redirect-std    # 2.1. redirect stdin/stdout/stderr before setsid
        cd /            # 3. ensure cwd isn't a mounted fs
        # umask 0       # 4. umask (leave this to caller)
        close-fds       # 5. close unneeded fds
        exec setsid "$@"
    ) &
}

# daemonize without setsid, keeps the child in the jobs table
daemonize_job() {
    (                   # 1. fork
        redirect-std    # 2.2.1. redirect stdin/stdout/stderr
        trap '' 1 2     # 2.2.2. guard against HUP and INT (in child)
        cd /            # 3. ensure cwd isn't a mounted fs
        # umask 0       # 4. umask (leave this to caller)
        close-fds       # 5. close unneeded fds
        if [[ $(type -t "$1") != file ]]; then
            "$@"
        else
            exec "$@"
        fi
    ) &
    disown -h $!       # 2.2.3. guard against HUP (in parent)
}

#####################################################################
HDFF_EXCLUDE_4PREFIX="\.\,?\!\-_:;\]\[\#\|\$()\"%"

## @fn generate_prefix_from_filename()
## @brief generate a prefix string from a file name
## @param fn the file name
##
generate_prefix_from_filename() {
  local PARAM_FN="$1"
  shift

  echo "${PARAM_FN//[${HDFF_EXCLUDE_4PREFIX}]/}" | tr [:upper:] [:lower:]
}

HDFF_EXCLUDE_4FILENAME="\""

## @fn unquote_filename()
## @brief remove double quotes from string
## @param fn the file name
##
unquote_filename() {
  local PARAM_FN="$1"
  shift
  #mr_trace "PARAM_FN=${PARAM_FN}; dirname=$(dirname "${PARAM_FN}"); readlink2=$(readlink -f "$(dirname "${PARAM_FN}")" )"
  echo "${PARAM_FN//[${HDFF_EXCLUDE_4FILENAME}]/}" | sed 's/\t//g'
}

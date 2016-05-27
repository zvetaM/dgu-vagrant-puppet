#!/bin/bash

echo "data.gov.si install script, part 1 (version 27.5.2016-1)"

#show message on error exit
abort()
{
  echo "An error occurred. Exiting..." >&2
#sleep is necessary for tee to finish writing before console is shown, otherwise you do not get the prompt
  sleep 1
  exit 1;
}
trap 'abort' 0

#exit script on error
set -e
#log stdout and stderr to log as well as stdout
exec &> >(tee -a "log-1-conf-sys.txt")
#exec 1>log.txt 2>&1

#Run as root when installing on fresh machine
if [ "$EUID" -ne 0 ]
  then echo "Run script as 'root' user!"
  exit 1
fi

#Configure system, create users, set permissions
#-----------------------------------------------
echo "127.0.0.1    ckan" >> /etc/hosts || ( echo "******ERROR*******: 127.0.0.1 ckan not included in /etc/hosts" && false )
hostnamectl --static set-hostname ckan || ( echo "******ERROR*******: hostnamectl ckan failed" && false )
getent passwd co && echo "******WARNING****** not creating user co, already exists" || adduser -u 510 co -G wheel || ( echo "******ERROR*******: nisem mogel dodati uporabnika co (uid 510, dodatna skupina wheel)" && false )
chmod a+rx /home/co/ || ( echo "******ERROR*******: chmod of /home/co failed" && false )
echo "co ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ckan-co-user || ( echo "******ERROR*******: adding user 'co' to /etc/sudoers.d failed" && false )
sed -e '/Defaults[[:space:]]\+requiretty/ s/^#*/#/' -i /etc/sudoers || ( echo "******ERROR*******: commenting out Defaults requiretty failed" && false )
sed -i 's/enforcing/permissive/g' /etc/selinux/config /etc/selinux/config || ( echo "******ERROR*******: could not change SELinux mode from enforcing to permissive" && false )
setenforce 0 || ( echo "******ERROR*******: setenforce 0 failed" && false )
mkdir /vagrant || echo "******WARNING*******: mkdir /vagrant failed, probably already exists"
chown co /vagrant || ( echo "******ERROR*******: chown co /vagrant failed" && false )
chgrp co /vagrant || ( echo "******ERROR*******: chgrp co /vagrant failed" && false )
#-----------------------------------------------

#Install missing software
#------------------------
#add epel repositories
yum install epel-release -y || ( echo "******ERROR*******: epel-release install failed" && false )
yum update -y || ( echo "******ERROR*******: yum update failed" && false )
#CentOS no longer has mysql in its official repo
rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm || ( echo "******ERROR*******: mysql repo install failed" && false )
#postgis causes trouble with double declarations in puppet, preinstall helps fix this
rpm -Uvh http://yum.postgresql.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-6.noarch.rpm || ( echo "******ERROR*******: postgis repo install failed" && false )
yum update -y || ( echo "******ERROR*******: yum update failed" && false )
yum install git -y || ( echo "******ERROR*******: install git failed" && false )
yum install postgis2_92 -y || ( echo "******ERROR*******: install postgis failed" && false )
yum install php-mbstring -y || ( echo "******ERROR****** yum install php-mbstring failed" && false )
yum install firewalld -y || echo "******WARNING*******: firewalld install failed, possibly already installed?"
systemctl enable firewalld || ( echo "******ERROR*******: failure enabling firewalld" && false )
systemctl start firewalld || ( echo "******ERROR*******: firewalld could not start" && false )
#------------------------

trap : 0

echo >&2 '
*** FINISHED WITHOUT ERRORS *** 
'
#sleep is necessary for tee to finish writing before console is shown, otherwise you do not get the prompt
sleep 1
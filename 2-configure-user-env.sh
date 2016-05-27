#!/bin/bash

echo "data.gov.si install script, part 2 (version 27.5.2016-1)"

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
exec &> >(tee -a "log-2-conf-user.txt")
#exec 1>log.txt 2>&1

#Run as root when installing on fresh machine
if [ "$(whoami)" != "co" ]
  then echo "Run script as 'co' user, by calling sudo -u co bash 2-configure-user-env.sh"
  echo "If getting premission denied, you need to run it inside a directory where co has execute permissions."
  exit 1
fi

cd /home/co || ( echo "******ERROR*******: cd /home/co failed" && false )

gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 || ( echo "******ERROR*******: adding gpg2 failed" && false )
curl -sSL get.rvm.io | bash -s stable || ( echo "******ERROR*******: rvm install failed" && false )
echo "source /home/co/.profile" >> /home/co/.bash_profile || ( echo "******ERROR*******: modification of .bash_profile failed" && false )

source /home/co/.rvm/scripts/rvm || ( echo "******ERROR*******: source /home/co/.rvm/scripts/rvm failed" && false ) 
rvm requirements || ( echo "******ERROR*******: rvm requirements failed" && false )
rvm install 1.8.7 || ( echo "******ERROR*******: rvm install 1.8.7 failed" && false )
gem install puppet -v 2.7.19 || ( echo "******ERROR*******: gem install puppet failed" && false )
gem install highline -v 1.6.1 || ( echo "******ERROR*******: gem install highline failed" && false )
gem install librarian-puppet -v 1.0.3 || ( echo "******ERROR*******: gem install librarian-puppet failed" && false )

cd /vagrant || ( echo "******ERROR*******: cd /vagrant failed" && false )
git clone https://github.com/zvetaM/dgu-vagrant-puppet || ( echo "******ERROR*******: git clone zvetaM/dgu-vagrant-puppet failed" && false )
cd dgu-vagrant-puppet || ( echo "******ERROR******: cd dgu-vagrant-puppet failed" && false )
git pull || ( echo "******ERROR*******: git pull zvetaM/dgu-vagrant-puppet failed" && false )
cd /vagrant/dgu-vagrant-puppet || ( echo "******ERROR*******: cd /vagrant/dgu-vagrant-puppet failed" && false )

ln -s /vagrant/dgu-vagrant-puppet/src /vagrant/src || ( echo "******ERROR*******: ln /vagrant/src failed" && false )
ln -s /vagrant/dgu-vagrant-puppet/puppet/ /vagrant/puppet || ( echo "******ERROR*******: ln /vagrant/puppet failed" && false )
ln -s /vagrant/dgu-vagrant-puppet/pypi /vagrant/pypi || ( echo "******ERROR*******: ln /vagrant/pypi failed" && false )

sudo ln -s /vagrant/src /src || ( echo "******ERROR*******: ln /src failed" && false )
sudo chown co /src || ( echo "******ERROR*******: chown /src failed" && false )
sudo chgrp co /src || ( echo "******ERROR*******: chrgp /src failed" && false )
sudo chown co -h /src || ( echo "******ERROR*******: chown -h /src failed" && false )
sudo chgrp co -h /src || ( echo "******ERROR*******: chown -h /src failed" && false )
cd /src || ( echo "******ERROR*******: cd /src failed" && false )
./git_clone_all.sh || ( echo "******ERROR*******: ./git_clone_all.sh failed" && false )

trap : 0

echo >&2 '
*** FINISHED WITHOUT ERRORS *** 
'
#sleep is necessary for tee to finish writing before console is shown, otherwise you do not get the prompt
sleep 1
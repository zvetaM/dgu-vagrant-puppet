#!/bin/bash

echo "data.gov.si install script, part 3 (version 27.5.2016-1)"

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
exec &> >(tee -a "log-3-puppet.txt")
#exec 1>log.txt 2>&1

#Run as root when installing on fresh machine
if [ "$EUID" -ne 0 ]
  then echo "Run script as 'root' user!"
  exit 1
fi

cd /src || ( echo "******ERROR*******: cd /src failed" && false )
source /home/co/.rvm/scripts/rvm  || ( echo "******ERROR*******: source /home/co/.rvm/scripts/rvm failed" && false )
/vagrant/puppet/install_puppet_dependancies.sh || ( echo "******ERROR*******: install_puppet_dependencies.sh failed" && false )
source /home/co/.rvm/scripts/rvm ; puppet apply /vagrant/puppet/manifests/site.pp  || ( echo "******ERROR*******: puppet apply failed" && false )

trap : 0

echo >&2 '
*** FINISHED WITHOUT ERRORS ***
Please also check Puppet output for errors or warnings. If some
remote package did not install, try first to run the script again 
in case it was just due to a sparse connection error. 
'
#sleep is necessary for tee to finish writing before console is shown, otherwise you do not get the prompt
sleep 1
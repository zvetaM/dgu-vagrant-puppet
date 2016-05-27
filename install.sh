#!/bin/bash

echo "data.gov.si install script (version 27.5.2016-1)"

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
exec &> >(tee -a "log.txt")
#exec 1>log.txt 2>&1

#Run as root when installing on fresh machine
if [ "$EUID" -ne 0 ]
  then echo "Run script as 'root' user!"
  exit
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

cd /home/co || ( echo "******ERROR*******: cd v /home/co ni uspel" && false )

sudo -u co bash -c "gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3" || ( echo "******ERROR*******: dodajanje gpg2 ni uspelo" && false )
sudo -u co bash -c "curl -sSL get.rvm.io | bash -s stable" || ( echo "******ERROR*******: namestitev rvm ni uspela" && false )
sudo -u co bash -c "echo "source /home/co/.profile" >> /home/co/.bash_profile" || ( echo "******ERROR*******: spreminjanje .bash_profile ni uspelo" && false )

sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; rvm requirements" || ( echo "******ERROR*******: rvm requirements ni uspel" && false )
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; rvm install 1.8.7" || ( echo "******ERROR*******: rvm install 1.8.7 ni uspel" && false )
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; gem install puppet -v 2.7.19" || ( echo "******ERROR*******: gem install puppet ni uspel" && false )
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; gem install highline -v 1.6.1" || ( echo "******ERROR*******: gem install highline ni uspel" && false )
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; gem install librarian-puppet -v 1.0.3" || ( echo "******ERROR*******: gem install librarian-puppet ni uspel" && false )

cd /vagrant || ( echo "******ERROR*******: cd na /vagrant ni uspel" && false )
sudo -u co git clone https://github.com/zvetaM/dgu-vagrant-puppet || ( echo "******ERROR*******: git clone zvetaM/dgu-vagrant-puppet ni uspel" && false )
cd dgu-vagrant-puppet || ( echo "******ERROR******: cd v dgu-vagrant-puppet ni uspel" && false )
sudo -u co git pull || ( echo "******ERROR*******: git pull zvetaM/dgu-vagrant-puppet ni uspel" && false )
cd /vagrant/dgu-vagrant-puppet || ( echo "******ERROR*******: cd v /vagrant/dgu-vagrant-puppet ni uspel" && false )

sudo -u co bash -c "ln -s /vagrant/dgu-vagrant-puppet/src /vagrant/src" || ( echo "******ERROR*******: ln /vagrant/src ni uspel" && false )
sudo -u co bash -c "ln -s /vagrant/dgu-vagrant-puppet/puppet/ /vagrant/puppet" || ( echo "******ERROR*******: ln /vagrant/puppet ni uspel" && false )
sudo -u co bash -c "ln -s /vagrant/dgu-vagrant-puppet/pypi /vagrant/pypi" || ( echo "******ERROR*******: ln /vagrant/pypi ni uspel" && false )

ln -s /vagrant/src /src || ( echo "******ERROR*******: ln /src ni uspel" && false )
chown co /src || ( echo "******ERROR*******: chown /src ni uspel" && false )
chgrp co /src || ( echo "******ERROR*******: chrgp /src ni uspel" && false )
chown co -h /src || ( echo "******ERROR*******: chown -h /src ni uspel" && false )
chgrp co -h /src || ( echo "******ERROR*******: chown -h /src ni uspel" && false )
cd /src || ( echo "******ERROR*******: cd v /src ni uspel" && false )
sudo -u co ./git_clone_all.sh || ( echo "******ERROR*******: ./git_clone_all.sh ni uspel" && false )

source /home/co/.rvm/scripts/rvm  || ( echo "******ERROR*******: source /home/co/.rvm/scripts/rvm failed" && false )
/vagrant/puppet/install_puppet_dependancies.sh || ( echo "******ERROR*******: install_puppet_dependencies.sh failed" && false )
source /home/co/.rvm/scripts/rvm ; puppet apply /vagrant/puppet/manifests/site.pp  || ( echo "******ERROR*******: puppet apply failed" && false )

sudo -u co /home/co/ckan/bin/paster --plugin=ckanext-dgu create-test-data --config=/var/ckan/ckan.ini || ( echo "******ERROR****** paster ckan create-test-data ni uspel" && false )
sudo -u co /home/co/ckan/bin/paster --plugin=ckanext-dgu schema init --config=/var/ckan/ckan.ini || ( echo "******ERROR****** paster ckan schema init ni uspel" && false )
sudo -u co /home/co/ckan/bin/paster --plugin=ckanext-packagezip packagezip init --config=/var/ckan/ckan.ini || ( echo "******ERROR****** paster ckan packagezip init ni uspel" && false )
sudo -u co /home/co/ckan/bin/paster --plugin=ckan user add admin email=admin@ckan password=pass --config=/var/ckan/ckan.ini || ( echo "******ERROR****** paster ckan user ni uspel" && false )
sudo -u co /home/co/ckan/bin/paster --plugin=ckan sysadmin add admin --config=/var/ckan/ckan.ini || ( echo "******ERROR****** paster ckan sysadmin ni uspel" && false )

mkdir /var/www/drupal || echo "******WARNING****** mkdir /var/www/drupal failed, probably already exists"
chown co:apache /var/www/drupal || ( echo "******ERROR****** sudo chown co:apache /var/www/drupal ni uspel" && false )
echo 'export PATH="/usr/local/bin:$PATH"' >> /home/co/.bashrc || ( echo "******ERROR****** razsirjen PATHH z /usr/local/bin ni uspel" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src ; curl -sS https://getcomposer.org/installer | php" || ( echo "******ERROR****** get composer ni uspel" && false )
mv /vagrant/dgu-vagrant-puppet/src/composer.phar /usr/local/bin/composer || ( echo "******ERROR****** mv composer ni uspel" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src ; composer global require drush/drush" || ( echo "******ERROR****** composer global require ni uspel" && false )
echo 'export PATH="/home/co/.composer/vendor/bin:$PATH"' >> /home/co/.bashrc || ( echo "******ERROR****** razsirjen PATH z composer ni uspel" && false )

sudo -u co bash -c "source /home/co/.bash_profile ; cd /src ; drush make /src/dgu_d7/distro.make /var/www/drupal/dgu" || ( echo "******ERROR****** drush make distro.make ni uspel" && false )
#za uporabo postgresa za Drupal zamenjaj mysql klice z naslednjim (beware: might cause errors running site because of incomplete support):	
#sudo -u postgres psql -U postgres -c "CREATE DATABASE dgu;" || ( echo "******ERROR****** postgres CREATE DATABASE dgu; ni uspel"
mysql -u root --execute "CREATE DATABASE dgu;" || ( echo "******ERROR****** MySQL CREATE DATABASE dgu failed" && false )
mysql -u root --execute "CREATE USER 'co'@'localhost' IDENTIFIED BY 'pass';" || ( echo "******ERROR****** MySQL CREATE USER co failed" && false )
mysql -u root --execute "GRANT ALL PRIVILEGES ON *.* TO 'co'@'localhost';" || ( echo "******ERROR****** MySQL GRANT TO co failed" && false )
cd /var/www/drupal/dgu || ( echo "******ERROR****** cd /var/www/drupal/dgu ni uspel" && false )
#postgres Drupal:
#sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; source /home/co/.bashrc ; drush --yes --verbose site-install dgu --db-url=pgsql://co:pass@localhost/dgu --account-name=admin --account-pass=admin  --site-name='Portal odprtih podatkov Slovenije'" || ( echo "******ERROR****** drush site-install ni uspel"
#mysql Drupal:
#naslednji ukaz javi napako, zaenkrat jo ignoriramo:
#WD cron: PDOException: SQLSTATE[42S02]: Base table or view not found: 1146 Table 'dgu.ckan_dataset_history' doesn't exist: DELETE FROM                  [error]
#{ckan_dataset_history} 
#WHERE  (timestamp < :db_condition_placeholder_0) ; Array
#(
#    [:db_condition_placeholder_0] => 1460968899
#)
# in ckan_dataset_cron() (line 348 of /var/www/drupal/dgu/profiles/dgu/modules/contrib/ckan/ckan_dataset/ckan_dataset.module).
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush --yes --verbose site-install dgu --db-url=mysql://co:pass@localhost/dgu --account-name=admin --account-pass=admin  --site-name='Portal odprtih podatkov Slovenije'" || ( echo "******ERROR****** drush site-install ni uspel" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush --yes en dgu_app dgu_blog dgu_consultation dgu_data_set dgu_data_set_request dgu_footer dgu_forum dgu_glossary dgu_idea dgu_library dgu_linked_data dgu_location dgu_moderation dgu_notifications dgu_organogram dgu_print dgu_reply dgu_search dgu_services dgu_user ckan" || ( echo "******ERROR****** drush module install ni uspel" && false )

sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_url 'http://data.gov.si/api/'" || ( echo "******ERROR****** drush vset ckan_url ni uspel" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_apikey 'xxxxxxxxxxxxxxxxxxxxx'" || ( echo "******ERROR****** drush vset ckan_apikey ni uspel" && false )

sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush composer-rebuild" || ( echo "******ERROR****** drush composer-rebuild ni uspel" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu/sites/default/files/composer ; composer install" || ( echo "******ERROR****** composer install ni uspel" && false )

chown -R co:apache /var/www/drupal/dgu/sites/default/files || ( echo "******ERROR****** sudo chown drupal default files ni uspel" && false )

#odpre firewall za http(s) dostop
firewall-cmd --permanent --zone=public --add-service=http || ( echo "******ERROR****** firewall add http ni uspel" && false )
firewall-cmd --permanent --zone=public --add-service=https || ( echo "******ERROR****** firewall add https ni uspel" && false )
firewall-cmd --reload || ( echo "******ERROR****** firewall reload ni uspel" && false )
#brez naslednjih vrstic apache ne dekodira php-ja
echo "AddType application/x-httpd-php .php" > /etc/httpd/conf.d/php-enable.load || ( echo "******ERROR****** php enable ni uspel" && false )

sudo -u apache bash -c "source /home/co/.bash_profile; /home/co/ckan/bin/paster --plugin=ckan user add frontend email=a@b.com password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1` --config=/var/ckan/ckan.ini" &> /tmp/frontend_izhod.txt || ( echo "******ERROR****** ckan user add frontend ni uspel" && false )
APIKEY=$(cat /tmp/frontend_izhod.txt | grep apikey | awk '{print $2}' | sed -r 's/^.{2}//' | sed 's/.\{2\}$//')
[[ !  -z  $APIKEY  ]] && sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_apikey '$APIKEY'" || ( echo "******ERROR****** drush vset ckan_apikey ni uspel oziroma je kljuc ze nastavljen!" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset d3_library_source cdn" || ( echo "******ERROR****** drush vset d3_library_source ni uspel" && false )
sudo -u apache bash -c "source /home/co/.bash_profile; /home/co/ckan/bin/paster --plugin=ckan sysadmin add frontend --config=/var/ckan/ckan.ini" || ( echo "******ERROR****** ckan sysadmin add frontend ni uspel" && false )

service httpd restart || ( echo "******ERROR****** httpd restart ni uspel" && false )

trap : 0

echo >&2 '
*** FINISHED WITHOUT ERRORS *** 
'
#sleep is necessary for tee to finish writing before console is shown, otherwise you do not get the prompt
sleep 1
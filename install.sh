echo "Skripta za namestitev data.gov.si (različica 18.5.2016-3)"

#Kot uporabnik root, namestitev na novo virtualko
if [ "$EUID" -ne 0 ]
  then echo "Poženi me kot uporabnik 'root'!"
  exit
fi

yum install epel-release -y || echo "******NAPAKA*******: epel-release namestitev ni uspela"
yum update -y || echo "******NAPAKA*******: yum update ni uspel"
echo "127.0.0.1    ckan" >> /etc/hosts || echo "******NAPAKA*******: 127.0.0.1 ckan ni v /etc/hosts"
hostnamectl --static set-hostname ckan || echo "******NAPAKA*******: hostnamectl ckan ni uspel"
adduser -u 510 co -G wheel || echo "******NAPAKA*******: nisem mogel dodati uporabnika co (uid 510, dodatna skupina wheel)"
chmod a+rx /home/co/ || echo "******NAPAKA*******: sprememba pravic za branje /home/co ni uspela"
echo "co ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ckan-co-user || echo "******NAPAKA*******: pravilo za uporabnika co v /etc/sudoers.d ni uspešno dodano"
yum install git -y || echo "******NAPAKA*******: install git ni uspel"
sed -e '/Defaults[[:space:]]\+requiretty/ s/^#*/#/' -i /etc/sudoers || echo "******NAPAKA*******: komentiranje Defaults requiretty ni uspel"
sed -i 's/enforcing/permissive/g' /etc/selinux/config /etc/selinux/config || echo "******NAPAKA*******: SELinux nisem mogel spremeniti načina delovanja na permissive iz enforcing"
setenforce 0 || echo "******NAPAKA*******: setenforce 0 ne deluje"

yum install -y firewalld
systemctl enable firewalld
systemctl start firewalld

cd /home/co || echo "******NAPAKA*******: cd v /home/co ni uspel"

sudo -u co bash -c "gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3" || echo "******NAPAKA*******: dodajanje gpg2 ni uspelo"
sudo -u co bash -c "curl -sSL get.rvm.io | bash -s stable" || echo "******NAPAKA*******: namestitev rvm ni uspela"
sudo -u co bash -c "echo "source /home/co/.profile" >> /home/co/.bash_profile" || echo "******NAPAKA*******: spreminjanje .bash_profile ni uspelo"

sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; rvm requirements" || echo "******NAPAKA*******: rvm requirements ni uspel"
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; rvm install 1.8.7" || echo "******NAPAKA*******: rvm install 1.8.7 ni uspel"
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; gem install puppet -v 2.7.19" || echo "******NAPAKA*******: gem install puppet ni uspel"
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; gem install highline -v 1.6.1" || echo "******NAPAKA*******: gem install highline ni uspel"
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; gem install librarian-puppet -v 1.0.3" || echo "******NAPAKA*******: gem install librarian-puppet ni uspel"

#CentOS no longer has mysql in its official repo
rpm -Uvh http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm || echo "******NAPAKA*******: mysql repo install ni uspel"
#postgis causes trouble with double declarations in puppet, preinstall helps fix this
rpm -Uvh http://yum.postgresql.org/9.2/redhat/rhel-6-x86_64/pgdg-centos92-9.2-6.noarch.rpm || echo "******NAPAKA*******: postgis repo install ni uspel"
yum update -y || echo "******NAPAKA*******: yum update ni uspel"
yum install postgis2_92 -y || echo "******NAPAKA*******: install postgis ni uspel"

mkdir /vagrant || echo "******NAPAKA*******: mkdir /vagrant ni uspel"
chown co /vagrant || echo "******NAPAKA*******: chown na /vagrant ni uspel"
chgrp co /vagrant || echo "******NAPAKA*******: chgrp na /vagrant ni uspel"
cd /vagrant || echo "******NAPAKA*******: cd na /vagrant ni uspel"
sudo -u co git clone https://github.com/zvetaM/dgu-vagrant-puppet || echo "******NAPAKA*******: git clone zvetaM/dgu-vagrant-puppet ni uspel"
cd dgu-vagrant-puppet || echo "******NAPAKA******: cd v dgu-vagrant-puppet ni uspel"
sudo -u co git pull || echo "******NAPAKA*******: git pull zvetaM/dgu-vagrant-puppet ni uspel"
cd /vagrant/dgu-vagrant-puppet || echo "******NAPAKA*******: cd v /vagrant/dgu-vagrant-puppet ni uspel"

sudo -u co bash -c "ln -s /vagrant/dgu-vagrant-puppet/src /vagrant/src" || echo "******NAPAKA*******: ln /vagrant/src ni uspel"
sudo -u co bash -c "ln -s /vagrant/dgu-vagrant-puppet/puppet/ /vagrant/puppet" || echo "******NAPAKA*******: ln /vagrant/puppet ni uspel"
sudo -u co bash -c "ln -s /vagrant/dgu-vagrant-puppet/pypi /vagrant/pypi" || echo "******NAPAKA*******: ln /vagrant/pypi ni uspel"

ln -s /vagrant/src /src || echo "******NAPAKA*******: ln /src ni uspel"
chown co /src || echo "******NAPAKA*******: chown /src ni uspel"
chgrp co /src || echo "******NAPAKA*******: chrgp /src ni uspel"
chown co -h /src || echo "******NAPAKA*******: chown -h /src ni uspel"
chgrp co -h /src || echo "******NAPAKA*******: chown -h /src ni uspel"
cd /src || echo "******NAPAKA*******: cd v /src ni uspel"
sudo -u co ./git_clone_all.sh || echo "******NAPAKA*******: ./git_clone_all.sh ni uspel"

source /home/co/.rvm/scripts/rvm  || echo "******NAPAKA*******: source /home/co/.rvm/scripts/rvm ni uspel"
/vagrant/puppet/install_puppet_dependancies.sh || echo "******NAPAKA*******: namestitev install_puppet_dependencies.sh ni uspela"
source /home/co/.rvm/scripts/rvm ; puppet apply /vagrant/puppet/manifests/site.pp  || echo "******NAPAKA*******: puppet apply ni uspel"

sudo -u co /home/co/ckan/bin/paster --plugin=ckanext-dgu create-test-data --config=/var/ckan/ckan.ini || echo "******NAPAKA****** paster ckan create-test-data ni uspel"
sudo -u co /home/co/ckan/bin/paster --plugin=ckan user add admin email=admin@ckan password=pass --config=/var/ckan/ckan.ini || echo "******NAPAKA****** paster ckan user ni uspel"
sudo -u co /home/co/ckan/bin/paster --plugin=ckan sysadmin add admin --config=/var/ckan/ckan.ini || echo "******NAPAKA****** paster ckan sysadmin ni uspel"

sudo -u co /home/co/ckan/bin/pip install simplejson==3.2.0

echo 'export PATH="/usr/local/bin:$PATH"' >> /home/co/.bashrc || echo "******NAPAKA****** razsirjen PATHH z /usr/local/bin ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src ; curl -sS https://getcomposer.org/installer | php" || echo "******NAPAKA****** get composer ni uspel"
mv /vagrant/dgu-vagrant-puppet/src/composer.phar /usr/local/bin/composer || echo "******NAPAKA****** mv composer ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src ; composer global require drush/drush" || echo "******NAPAKA****** composer global require ni uspel"
echo 'export PATH="/home/co/.composer/vendor/bin:$PATH"' >> /home/co/.bashrc || echo "******NAPAKA****** razsirjen PATH z composer ni uspel"

mkdir /var/www/drupal || echo "******NAPAKA****** sudo mkdir /var/www/drupal ni uspel"
chown co:apache /var/www/drupal || echo "******NAPAKA****** sudo chown co:apache /var/www/drupal ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src ; drush make /src/dgu_d7/distro.make /var/www/drupal/dgu" || echo "******NAPAKA****** drush make distro.make ni uspel"
#za uporabo postgresa za Drupal zamenjaj mysql klice z naslednjim (beware: might cause errors running site because of incomplete support):	
#sudo -u postgres psql -U postgres -c "CREATE DATABASE dgu;" || echo "******NAPAKA****** postgres CREATE DATABASE dgu; ni uspel"
mysql -u root --execute "CREATE DATABASE dgu;"
mysql -u root --execute "CREATE USER 'co'@'localhost' IDENTIFIED BY 'pass';"
mysql -u root --execute "GRANT ALL PRIVILEGES ON *.* TO 'co'@'localhost';"
yum install php-mbstring -y || echo "******NAPAKA****** yum install php-mbstring ni uspel"
cd /var/www/drupal/dgu || echo "******NAPAKA****** cd /var/www/drupal/dgu ni uspel"
#postgres Drupal:
#sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; source /home/co/.bashrc ; drush --yes --verbose site-install dgu --db-url=pgsql://co:pass@localhost/dgu --account-name=admin --account-pass=admin  --site-name='Portal odprtih podatkov Slovenije'" || echo "******NAPAKA****** drush site-install ni uspel"
#mysql Drupal:
#naslednji ukaz javi napako, zaenkrat jo ignoriramo:
#WD cron: PDOException: SQLSTATE[42S02]: Base table or view not found: 1146 Table 'dgu.ckan_dataset_history' doesn't exist: DELETE FROM                  [error]
#{ckan_dataset_history} 
#WHERE  (timestamp < :db_condition_placeholder_0) ; Array
#(
#    [:db_condition_placeholder_0] => 1460968899
#)
# in ckan_dataset_cron() (line 348 of /var/www/drupal/dgu/profiles/dgu/modules/contrib/ckan/ckan_dataset/ckan_dataset.module).
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush --yes --verbose site-install dgu --db-url=mysql://co:pass@localhost/dgu --account-name=admin --account-pass=admin  --site-name='Portal odprtih podatkov Slovenije'" || echo "******NAPAKA****** drush site-install ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush --yes en dgu_app dgu_blog dgu_consultation dgu_data_set dgu_data_set_request dgu_footer dgu_forum dgu_glossary dgu_idea dgu_library dgu_linked_data dgu_location dgu_moderation dgu_notifications dgu_organogram dgu_print dgu_reply dgu_search dgu_services dgu_user ckan" || echo "******NAPAKA****** drush module install ni uspel"

sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_url 'http://data.gov.si/api/'" || echo "******NAPAKA****** drush vset ckan_url ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_apikey 'xxxxxxxxxxxxxxxxxxxxx'" || echo "******NAPAKA****** drush vset ckan_apikey ni uspel"

chown -R co:apache /var/www/drupal/dgu/sites/default/files || echo "******NAPAKA****** sudo chown drupal default files ni uspel"

#odpre firewall za http(s) dostop
firewall-cmd --permanent --zone=public --add-service=http || echo "******NAPAKA****** firewall add http ni uspel"
firewall-cmd --permanent --zone=public --add-service=https || echo "******NAPAKA****** firewall add https ni uspel"
firewall-cmd --reload || echo "******NAPAKA****** firewall reload ni uspel"
#brez naslednjih vrstic apache ne dekodira php-ja
echo "AddType application/x-httpd-php .php" > /etc/httpd/conf.d/php-enable.load || echo "******NAPAKA****** php enable ni uspel"

cd /var/www/drupal/dgu || echo "******NAPAKA****** cd v /var/www/drupal/dgu ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush composer-rebuild" || echo "******NAPAKA****** drush composer-rebuild ni uspel"
cd /var/www/drupal/dgu/sites/default/files/composer || echo "******NAPAKA****** cd v /var/www/drupal/dgu/sites/default/files/composer ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu/sites/default/files/composer ; composer install" || echo "******NAPAKA****** composer install ni uspel"

sudo -u apache bash -c "source /home/co/.bash_profile; /home/co/ckan/bin/paster --plugin=ckan user add frontend email=a@b.com password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1` --config=/var/ckan/ckan.ini" &> /tmp/frontend_izhod.txt || echo "******NAPAKA****** ckan user add frontend ni uspel"
APIKEY=$(cat /tmp/frontend_izhod.txt | grep apikey | awk '{print $2}' | sed -r 's/^.{2}//' | sed 's/.\{2\}$//')
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_apikey '$APIKEY'" || echo "******NAPAKA****** drush vset ckan_apikey ni uspel"
sudo -u apache bash -c "source /home/co/.bash_profile; /home/co/ckan/bin/paster --plugin=ckan sysadmin add frontend --config=/var/ckan/ckan.ini" || echo "******NAPAKA****** ckan sysadmin add frontend ni uspel"

service httpd restart || echo "******NAPAKA****** httpd restart ni uspel"


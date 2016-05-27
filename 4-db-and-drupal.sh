#!/bin/bash

echo "data.gov.si install script, part 4 (version 27.5.2016-1)"

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
exec &> >(tee -a "log-4-drupal.txt")
#exec 1>log.txt 2>&1

#Run as root when installing on fresh machine
if [ "$EUID" -ne 0 ]
  then echo "Run script as 'root' user!"
  exit 1
fi

source /home/co/.rvm/scripts/rvm  || ( echo "******ERROR*******: source /home/co/.rvm/scripts/rvm failed" && false )

sudo -u co /home/co/ckan/bin/paster --plugin=ckanext-dgu create-test-data --config=/var/ckan/ckan.ini || ( echo "******ERROR****** paster ckan create-test-data failed" && false )
sudo -u co /home/co/ckan/bin/paster --plugin=ckanext-dgu schema init --config=/var/ckan/ckan.ini || ( echo "******ERROR****** paster ckan schema init failed" && false )
sudo -u co /home/co/ckan/bin/paster --plugin=ckanext-packagezip packagezip init --config=/var/ckan/ckan.ini || ( echo "******ERROR****** paster ckan packagezip init failed" && false )
sudo -u co /home/co/ckan/bin/paster --plugin=ckan user add admin email=admin@ckan password=pass --config=/var/ckan/ckan.ini || ( echo "******ERROR****** paster ckan user failed" && false )
sudo -u co /home/co/ckan/bin/paster --plugin=ckan sysadmin add admin --config=/var/ckan/ckan.ini || ( echo "******ERROR****** paster ckan sysadmin failed" && false )

mkdir /var/www/drupal || echo "******WARNING****** mkdir /var/www/drupal failed, probably already exists"
chown co:apache /var/www/drupal || ( echo "******ERROR****** sudo chown co:apache /var/www/drupal failed" && false )
echo 'export PATH="/usr/local/bin:$PATH"' >> /home/co/.bashrc || ( echo "******ERROR****** extended PATH for /usr/local/bin failed" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src ; curl -sS https://getcomposer.org/installer | php" || ( echo "******ERROR****** get composer failed" && false )
mv /vagrant/dgu-vagrant-puppet/src/composer.phar /usr/local/bin/composer || ( echo "******ERROR****** mv composer failed" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src ; composer global require drush/drush" || ( echo "******ERROR****** composer global require failed" && false )
echo 'export PATH="/home/co/.composer/vendor/bin:$PATH"' >> /home/co/.bashrc || ( echo "******ERROR****** extended PATH for composer failed" && false )

sudo -u co bash -c "source /home/co/.bash_profile ; cd /src ; drush make /src/dgu_d7/distro.make /var/www/drupal/dgu" || ( echo "******ERROR****** drush make distro.make failed" && false )
#za uporabo postgresa za Drupal zamenjaj mysql klice z naslednjim (beware: might cause errors running site because of incomplete support):	
#sudo -u postgres psql -U postgres -c "CREATE DATABASE dgu;" || ( echo "******ERROR****** postgres CREATE DATABASE dgu; failed"
mysql -u root --execute "CREATE DATABASE dgu;" || ( echo "******ERROR****** MySQL CREATE DATABASE dgu failed" && false )
mysql -u root --execute "CREATE USER 'co'@'localhost' IDENTIFIED BY 'pass';" || ( echo "******ERROR****** MySQL CREATE USER co failed" && false )
mysql -u root --execute "GRANT ALL PRIVILEGES ON *.* TO 'co'@'localhost';" || ( echo "******ERROR****** MySQL GRANT TO co failed" && false )
cd /var/www/drupal/dgu || ( echo "******ERROR****** cd /var/www/drupal/dgu failed" && false )
#postgres Drupal:
#sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; source /home/co/.bashrc ; drush --yes --verbose site-install dgu --db-url=pgsql://co:pass@localhost/dgu --account-name=admin --account-pass=admin  --site-name='Portal odprtih podatkov Slovenije'" || ( echo "******ERROR****** drush site-install failed"
#mysql Drupal:
#naslednji ukaz javi napako, zaenkrat jo ignoriramo:
#WD cron: PDOException: SQLSTATE[42S02]: Base table or view not found: 1146 Table 'dgu.ckan_dataset_history' doesn't exist: DELETE FROM                  [error]
#{ckan_dataset_history} 
#WHERE  (timestamp < :db_condition_placeholder_0) ; Array
#(
#    [:db_condition_placeholder_0] => 1460968899
#)
# in ckan_dataset_cron() (line 348 of /var/www/drupal/dgu/profiles/dgu/modules/contrib/ckan/ckan_dataset/ckan_dataset.module).
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush --yes --verbose site-install dgu --db-url=mysql://co:pass@localhost/dgu --account-name=admin --account-pass=admin  --site-name='Portal odprtih podatkov Slovenije'" || ( echo "******ERROR****** drush site-install failed" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush --yes en dgu_app dgu_blog dgu_consultation dgu_data_set dgu_data_set_request dgu_footer dgu_forum dgu_glossary dgu_idea dgu_library dgu_linked_data dgu_location dgu_moderation dgu_notifications dgu_organogram dgu_print dgu_reply dgu_search dgu_services dgu_user ckan" || ( echo "******ERROR****** drush module install failed" && false )

sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_url 'http://data.gov.si/api/'" || ( echo "******ERROR****** drush vset ckan_url failed" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_apikey 'xxxxxxxxxxxxxxxxxxxxx'" || ( echo "******ERROR****** drush vset ckan_apikey failed" && false )

sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush composer-rebuild" || ( echo "******ERROR****** drush composer-rebuild failed" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu/sites/default/files/composer ; composer install" || ( echo "******ERROR****** composer install failed" && false )

chown -R co:apache /var/www/drupal/dgu/sites/default/files || ( echo "******ERROR****** sudo chown drupal default files failed" && false )

#odpre firewall za http(s) dostop
firewall-cmd --permanent --zone=public --add-service=http || ( echo "******ERROR****** firewall add http failed" && false )
firewall-cmd --permanent --zone=public --add-service=https || ( echo "******ERROR****** firewall add https failed" && false )
firewall-cmd --reload || ( echo "******ERROR****** firewall reload failed" && false )
#brez naslednjih vrstic apache ne dekodira php-ja
echo "AddType application/x-httpd-php .php" > /etc/httpd/conf.d/php-enable.load || ( echo "******ERROR****** php enable failed" && false )

sudo -u apache bash -c "source /home/co/.bash_profile; /home/co/ckan/bin/paster --plugin=ckan user add frontend email=a@b.com password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1` --config=/var/ckan/ckan.ini" &> /tmp/frontend_izhod.txt || ( echo "******ERROR****** ckan user add frontend failed" && false )
APIKEY=$(cat /tmp/frontend_izhod.txt | grep apikey | awk '{print $2}' | sed -r 's/^.{2}//' | sed 's/.\{2\}$//')
[[ !  -z  $APIKEY  ]] && sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_apikey '$APIKEY'" || ( echo "******ERROR****** drush vset ckan_apikey failed or key already set!" && false )
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset d3_library_source cdn" || ( echo "******ERROR****** drush vset d3_library_source failed" && false )
sudo -u apache bash -c "source /home/co/.bash_profile; /home/co/ckan/bin/paster --plugin=ckan sysadmin add frontend --config=/var/ckan/ckan.ini" || ( echo "******ERROR****** ckan sysadmin add frontend failed" && false )

service httpd restart || ( echo "******ERROR****** httpd restart failed" && false )

trap : 0

echo >&2 '
*** FINISHED WITHOUT ERRORS *** 
'
#sleep is necessary for tee to finish writing before console is shown, otherwise you do not get the prompt
sleep 1
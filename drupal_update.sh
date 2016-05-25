#Pozeni me kot root
#Posodobijo se dgu_d7, ckanext-dgu ter shared_dguk_assets

cd /src
cd ckanext-dgu
git pull
cd -
cd dgu_d7
git pull
cd -
cd shared_dguk_assets
git pull
cd -

#Dobljeno iz Puppet dgu modula
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src/ckanext-dgu ; sudo npm install" || echo "******NAPAKA****** sudo npm install v /src/ckanext-dgu ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src/ckanext-dgu ; grunt" || echo "******NAPAKA****** grunt v /src/ckanext-dgu ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src/shared_dguk_assets ; sudo npm install" || echo "******NAPAKA****** sudo npm install v /src/shared_dguk_assets ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /src/shared_dguk_assets ; grunt" || echo "******NAPAKA****** grunt v /src/shared_dguk_assets ni uspel"

sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush --yes --verbose site-install dgu --db-url=mysql://co:pass@localhost/dgu --account-name=admin --account-pass=admin  --site-name='Portal odprtih podatkov Slovenije'" || echo "******NAPAKA****** drush site-install ni uspel"
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush --yes en dgu_app dgu_blog dgu_consultation dgu_data_set dgu_data_set_request dgu_footer dgu_forum dgu_glossary dgu_idea dgu_library dgu_linked_data dgu_location dgu_moderation dgu_notifications dgu_organogram dgu_print dgu_reply dgu_search dgu_services dgu_user ckan" || echo "******NAPAKA****** drush module install ni uspel"

sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_url 'http://data.gov.si/api/'" || echo "******NAPAKA****** drush vset ckan_url ni uspel"
APIKEY=$(sudo -u co bash -c "source /home/co/.bash_profile ; paster user frontend /var/ckan/ckan.ini 2>&1 > /dev/null | tr ' ' '\n' | grep apikey | cut -c 8-")
sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset ckan_apikey '$APIKEY'" || echo "******NAPAKA****** drush vset ckan_apikey ni uspel"

sudo -u co bash -c "source /home/co/.bash_profile ; cd /var/www/drupal/dgu ; drush vset d3_library_source cdn" || echo "******NAPAKA****** drush vset d3_library_source ni uspel"

service httpd restart || echo "******NAPAKA****** httpd restart ni uspel"

#Installation
To install data.gov.si you can simply run ```install.sh``` as the 'root' user:

```
bash install.sh
```

OR you can install it in four steps, which may help avoid puppet apply errors (3rd step). You should run the scripts as the 'root' user in a directory with execution permissions for everybody:

```
bash 1-configure-system.sh
sudo -u co bash 2-configure-user-env.sh
bash 3-puppet-apply.sh
bash 4-db-and-drupal.sh
```



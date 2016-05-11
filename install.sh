echo "Skripta za namestitev data.gov.si (različica 11.5.2016-3)"

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
echo "co ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ckan-co-user || echo "******NAPAKA*******: pravilo za uporabnika co v /etc/sudoers.d ni uspešno dodano"
yum install git -y || echo "******NAPAKA*******: install git ni uspel"
sed -e '/Defaults[[:space:]]\+requiretty/ s/^#*/#/' -i /etc/sudoers || echo "******NAPAKA*******: komentiranje Defaults requiretty ni uspel"
sed -i 's/enforcing/permissive/g' /etc/selinux/config /etc/selinux/config || echo "******NAPAKA*******: SELinux nisem mogel spremeniti načina delovanja na permissive iz enforcing"
setenforce 0 || echo "******NAPAKA*******: setenforce 0 ne deluje"

cd /home/co || echo "******NAPAKA*******: cd v /home/co ni uspel"

sudo -u co bash -c "gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3" || echo "******NAPAKA*******: dodajanje gpg2 ni uspelo"
sudo -u co bash -c "curl -sSL get.rvm.io | bash -s stable" || echo "******NAPAKA*******: namestitev rvm ni uspela"
sudo -u co bash -c "echo "source ~/.profile" >> /home/co/.bash_profile" || echo "******NAPAKA*******: spreminjanje .bash_profile ni uspelo"

sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; rvm requirements" || echo "******NAPAKA*******: rvm requirements ni uspel"
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; rvm install 1.8.7" || echo "******NAPAKA*******: rvm install 1.8.7 ni uspel"
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; gem install puppet -v 2.7.19" || echo "******NAPAKA*******: gem install puppet ni uspel"
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; gem install highline -v 1.6.1" || echo "******NAPAKA*******: gem install highline ni uspel"
sudo -u co bash -c "source /home/co/.rvm/scripts/rvm ; gem install librarian-puppet -v 1.0.3" || echo "******NAPAKA*******: gem install librarian-puppet ni uspel"

mkdir /vagrant || echo "******NAPAKA*******: mkdir /vagrant ni uspel"
chown co /vagrant || echo "******NAPAKA*******: chown na /vagrant ni uspel"
chgrp co /vagrant || echo "******NAPAKA*******: chgrp na /vagrant ni uspel"
cd /vagrant || echo "******NAPAKA*******: cd na /vagrant ni uspel"
sudo -u co git clone https://github.com/zvetaM/dgu-vagrant-puppet || echo "******NAPAKA*******: git clone zvetaM/dgu-vagrant-puppet ni uspel"
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

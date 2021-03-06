Exec {
  # Set defaults for execution of commands
  path => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/ruby/bin",
}
group {"puppet":
  ensure => present,
}
group {"co":
  ensure => present,
}
class { 'sudo':
  purge               => false,
  config_file_replace => false,
}
sudo::conf { 'sudo':
  priority => 10,
  content  => "%sudo ALL=(ALL) NOPASSWD: ALL",
}
file {"/home/co":
  require => [ User["co"], Group["co"] ],
  ensure  => directory,
  owner   => "co",
  group   => "co",
}
user { "co":
  require    => [Group["co"],
                 Sudo::Conf["sudo"]],
  ensure     => present,
  managehome => true,
  uid        => "510",
  gid        => "co",
  shell      => "/bin/bash",
  home       => "/home/co",
  groups     => ["wheel","adm","apache"],
}

file { '/etc/fqdn':
  content => $::fqdn
}
file { '/etc/motd':
  content => "Hov hov hov!
              $motd\n"
}
file { '/home/co/.bashrc':
   ensure => 'link',
   target => '/vagrant/dgu-vagrant-puppet/.bashrc',
}
package { "screen":
  ensure => "installed"
}
package { "vim-enhanced":
  ensure => "installed"
}
package { "pv":
  ensure => "installed"
}
package { "unzip":
  ensure => "installed"
}
package { "curl":
  ensure => "installed"
}
package { "wget":
  ensure => "installed"
}

#NodeJS nadomestek: npm, nodejs
#package { "nodejs":
#  ensure => "installed"
#}
#package { "npm":
#  ensure => "installed"
#}

# ---------
# Drupal bits
# ---------
#prej je bil mysql 5.5 server
#package { "postgresql-server":
#  ensure => "installed"
#}

#pip package psycopg2 seems to need this
package { "postgresql-devel":
  ensure => "installed"
}

package { "mysql-community-server":
  ensure => "installed"
}

#****************************************************************

# -----------
# MySQL DB
# -----------
#****************************************************************

#TODO: max_allowed_packet=16M should be set in /etc/my.cnf to avoid warnings in Drupal
exec {"start MySQL service":
  require => [
    Package['mysql-community-server']
  ],
  command   => "systemctl start mysqld",
  path      => "/usr/bin:/bin:/usr/sbin",
  user      => root,
  logoutput => 'on_failure'
}

#****************************************************************

#package { "php5-gd":
#  ensure => "installed"
#}

package { "php-gd":
  ensure => "installed"
}

#if using postgres for Drupal, replace mysql with following:
# package { "php-pgsql":
package { "php-mysql":
  ensure => "installed"
}

#package { "php-curl":
#  ensure => "installed"
#}
package { "php-pear-Net-Curl":
  ensure => "installed"
}
package { "php-common":
  ensure => "installed"
}
file {'/var/www/api_users':
  ensure => file,
  content => template('dgu_ckan/api_users.erb'),
  owner   => "co",
  group   => "apache",
}

include dgu_ckan


group { 'puppet': ensure => 'present' }

Exec {
    path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ]
}

# update the (outdated) package list
exec { "update-package-list":
  command => "/usr/bin/sudo /usr/bin/apt-get update",
}


class java_7 {
  package { "openjdk-7-jdk":
    ensure => installed,
    require => Exec["update-package-list"],
  }
}

class tomcat_7 {
  package { "tomcat7":
    ensure => installed,
    require => Package['openjdk-7-jdk'],
  }
  
  package { "tomcat7-admin":
    ensure => installed,
    require => Package['tomcat7'],
  }
  
  service { "tomcat7":
    ensure => running,
    require => Package['tomcat7'],
    subscribe => File["mysql-connector.jar", "tomcat-users.xml"]
  }

  file { "tomcat-users.xml":
    owner => 'root',
    path => '/var/lib/tomcat7/conf/tomcat-users.xml',
    require => Package['tomcat7'],
    notify => Service['tomcat7'],
    content => template('/vagrant/templates/tomcat-users.xml.erb')
  }

  file { "mysql-connector.jar":
    require => Package['tomcat7'],
    owner => 'root',
    path => '/usr/share/tomcat7/lib/mysql-connector-java-5.1.15.jar',
    source => '/vagrant/files/mysql-connector-java-5.1.15.jar'
  }
}

class mysql_5 {
  package { "mysql-server-5.5":
    ensure => present,
    require => Exec["update-package-list"],
  }
  
  service { "mysql":
    ensure => running, 
    require => Package["mysql-server-5.5"]
  }

  exec { "create-db-schema-and-user":
    command => "/usr/bin/mysql -uroot -p -e \"drop database if exists testapp; create database testapp; create user dbuser@'%' identified by 'dbuser'; grant all on testapp.* to dbuser@'%'; flush privileges;\"",
    require => Service["mysql"]
  }

  file { "/etc/mysql/my.cnf":
    owner => 'root',
    group => 'root',
    mode => 644,
    notify => Service['mysql'],
    source => '/vagrant/files/my.cnf',
    require => Package["mysql-server-5.5"],
  }
}

class apache2{
  package { "apache2":
    ensure => installed,
    require => Exec["update-package-list"],
  }
  
  service { "apache2":
    ensure => running, 
    require => Package["apache2"]
  }
}

class phpmyadmin{
  package { "phpmyadmin":
    ensure => present,
    require => Exec["update-package-list"],
  }
    # linux way: ln -s /etc/phpmyadmin/apache.conf /etc/apache2/sites-available/phpmyadmin.conf
    file { "/etc/apache2/sites-available/phpmyadmin.conf":
      ensure => link,
      target => "/etc/phpmyadmin/apache.conf",
      require => Package["phpmyadmin"],
    }

	file { "config.inc.php":
    owner => 'root',
    group => 'root',
    mode => 644,
	path =>'/etc/phpmyadmin/config.inc.php',
    source => '/vagrant/files/config.inc.php',
    require => Package["phpmyadmin"],
  }

    exec {"enable-phpmyadmin":
      command => "sudo a2ensite phpmyadmin.conf",
      require => File["/etc/apache2/sites-available/phpmyadmin.conf"],
    }

    exec { "restart-apache":
      command => "sudo /etc/init.d/apache2 restart",
      require => Exec["enable-phpmyadmin"],
    } 
}



# set variables
$tomcat_password = 'manager'
$tomcat_user = 'manager'

include java_7
include tomcat_7
include mysql_5
include apache2
include phpmyadmin


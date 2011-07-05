class keystone::install {

  package { "keystone":
    ensure => present,
    require => Apt::Source["rcb"]
  }

  file { "/var/log/keystone":
    ensure => directory,
    owner  => "keystone",
    mode   => 0755
  }

  file { "/var/log/keystone/keystone.log":
    ensure => present,
    owner  => "keystone",
    mode   => "600",
    require => File["/var/log/keystone"]
  }

  file { "initial_data.sh":
    path => "/var/lib/keystone/initial_data.sh",
    ensure  => present,
    owner   => "keystone",
    mode    => 0700,
    content => template("keystone/initial_data.sh.erb"),
    require => Package["keystone"]
  }

  exec { "create_keystone_data":
    user => "keystone",
    command     => "/var/lib/keystone/initial_data.sh",
    path        => [ "/bin", "/usr/bin" ],
    unless      => "keystone-manage user list | grep -q admin",
    require     => [
      Package['keystone'],
      File['/var/log/keystone/keystone.log'],
      File["initial_data.sh"]
      
    ]
  }

}
  

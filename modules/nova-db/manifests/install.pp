class nova-db::install {
  # we only have to install if there isn't a nova db
  $pw = configval("passwords", $cluster_name)
  $op = configval("options", $cluster_name)

  $mysql_nova_password = $pw['mysql_nova_password']
  $mysql_root_password = $pw['mysql_root_password']
  $nova_admin_user = $pw['nova_admin']
  $nova_admin_password = $pw['nova_admin_password']
  $fixed_range = $op["fixed_range"]
  $floating_range = $op["floating_range"]
  
  exec { "create_nova_db":
    command     => "mysql -uroot -p${mysql_root_password} -e 'create database nova'",
    path        => [ "/bin", "/usr/bin" ],
    unless      => "mysql -uroot -p${mysql_root_password} -sr -e 'show databases' | grep -q nova",
    notify      => Exec["create_nova_user"]
  }
  
  exec { "create_nova_user":
    # FIXME:
    # someone really need to get db access limited to just
    # the controller nodes
    command     => "mysql -uroot -p${mysql_root_password} -e \"grant all on nova.* to 'nova'@'%' identified by '${mysql_nova_password}'\"",
    path        => [ "/bin", "/usr/bin" ],
    notify      => Exec["sync_nova_db"],
    refreshonly => true
  }

  # this is all totally brute force
  exec { "sync_nova_db":
    command     => "nova-manage db sync",
    path        => [ "/bin", "/usr/bin" ],
    refreshonly => true,
    notify      => Exec["create_admin_user"]
  }

  exec { "create_admin_user":
    command     => "nova-manage user admin ${nova_admin_user} ${nova_admin_password}",
    path        => [ "/bin", "/usr/bin" ],
    refreshonly => true,
    notify      => Exec["create_initial_network"]
  }

  exec { "create_initial_network":
    command     => "nova-manage network create ${fixed_range} 1 32",
    path        => [ "/bin", "/usr/bin" ],
    refreshonly => true
  }
}
  

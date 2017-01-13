define minecraft::service (
  $instance = $title,
  $install_dir,
  $service_ensure,
  $service_enable,
  $init_path,
  $init_template,
  $xmx,
  $xms,
  $user,
  $java_args,
  $jar,
) {

  file { "${title}_init":
    ensure  => 'present',
    path    => "${init_path}/${title}",
    owner   => 'root',
    group   => 'root',
    mode    => '0744',
    content => template($init_template),
    notify  => Service[$title],
  }

  if $::osfamily == 'FreeBSD' {
    file { "/etc/rc.conf.d/${title}":
      ensure  => 'present',
      owner   => 'root',
      group   => 'wheel',
      mode    => '0644',
      content => template('minecraft/minecraft_rc.erb'),
      notify  => Service[$title],
    }
  }

  service { $title:
    ensure    => $service_ensure,
    enable    => $service_enable,
    subscribe => File["${title}_init" ],
  }
}

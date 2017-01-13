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

  file { "minecraft_${title}_init":
    ensure  => 'present',
    path    => "${init_path}/minecraft_${title}",
    owner   => 'root',
    group   => '0',
    mode    => '0744',
    content => template($init_template),
    notify  => Service["minecraft_${title}"],
  }

  if $::osfamily == 'FreeBSD' {
    file { "/etc/rc.conf.d/minecraft_${title}":
      ensure  => 'present',
      owner   => 'root',
      group   => '0',
      mode    => '0644',
      content => template('minecraft/minecraft_rc.erb'),
      notify  => Service["minecraft_${title}"],
    }
  }

  service { "minecraft_${title}":
    ensure    => $service_ensure,
    enable    => $service_enable,
    subscribe => File["minecraft_${title}_init" ],
  }
}

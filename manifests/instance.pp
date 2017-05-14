define minecraft::instance (
  $instance             = $title,
  $user                 = $minecraft::user,
  $group                = $minecraft::group,
  $install_dir          = undef,
  $source               = '1.7.4',
  $service_ensure       = 'running',
  $service_enable       = true,
  $xmx                  = '1024M',
  $xms                  = '512M',
  $plugins              = {},
  $ops                  = [],
  $banned_players       = [],
  $banned_ips           = [],
  $white_list_players   = [],
  $mode                 = '0750',
  $init_path            = $minecraft::init_path,
  $init_template        = $minecraft::init_template,
  $plugins_defaults     = {},
  $java_args            = '',
  $jar                  = 'minecraft_server.jar',
  $server_properties    = {},
  $java_command         = 'java',
) {
  $_install_dir = $install_dir ? {
    undef => "${minecraft::install_base}/${instance}",
    default => $install_dir,
  }

  # Ensures deletion of install_dir does not break module, setup for plugins
  $dirs = [ $_install_dir, "${_install_dir}/plugins" ]

  file { $dirs:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => $mode,
  }

  minecraft::source { $title:
    source      => $source,
    install_dir => $_install_dir,
    user        => $user,
    group       => $group,
    jar         => $jar,
    require     => File[$dirs],
  }

  # These are JSON now.  If the .txt is present, Minecraft will convert it
  # upon startup and rename the .txt file to .txt.converted
  # Need to figure out how to best manage these.  Usernames in these files
  # now require a UUID as well.
  #[ 'ops.txt',
  #  'banned-players.txt',
  #  'banned-ips.txt',
  #  'white-list.txt',
  #].each |$cfg_file| {
  #  file { "${_install_dir}/${cfg_file}":
  #    ensure => 'file',
  #    content => template("minecraft/${cfg_file}.erb"),
  #    owner   => $user,
  #    group   => $group,
  #    mode    => '0660',
  #    require => Minecraft::Source[$title],
  #  }
  #}

  file { "${_install_dir}/server.properties":
    ensure  => 'file',
    owner   => $user,
    group   => $group,
    mode    => '0660',
    require => Minecraft::Source[$title],
  }
  
  # Build an array of augeas commands for the $server_properties hash. Each is 'set "<key>" "<value>"'
  $server_properties_changes = suffix(
    prefix(
      join_keys_to_values($server_properties, '" "'),
      'set "'
    ),
    '"'
  )
  augeas { "minecraft-${instance}-server-properties":
    lens    => 'Properties.lns',
    incl    => "${_install_dir}/server.properties",
    changes => $server_properties_changes,
    notify  => Minecraft::Service[$instance],
    require => File["${_install_dir}/server.properties"],
  }

  minecraft::service { $title:
    instance       => $instance,
    install_dir    => $_install_dir,
    service_ensure => $service_ensure,
    service_enable => $service_enable,
    init_path      => $init_path,
    init_template  => $init_template,
    xmx            => $xmx,
    xms            => $xms,
    user           => $user,
    group          => $group,
    java_args      => $java_args,
    jar            => $jar,
    java_command   => $java_command,
    subscribe      => Minecraft::Source[$title],
  }

  if $plugin_defaults != undef {
    $_plugin_defaults = $plugin_defaults
  } else {
    $_plugin_defaults = {
      install_dir => $_install_dir,
      user        => $user,
      group       => $group,
      ensure      => $present,
      require     => Minecraft::Source[$title],
      notify      => Minecraft::Service[$title],
    }
  }

  $_plugins = prefix($plugins, "${title}__")
  create_resources('minecraft::plugin', $_plugins, $_plugin_defaults)
}

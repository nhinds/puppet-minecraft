define minecraft::instance (
  Pattern[/^[\w]+$/]         $instance             = $title,
  Pattern[/^[\w\.]+$/]       $user                 = $minecraft::user,
  Pattern[/^[\w\.]+$/]       $group                = $minecraft::group,
  Stdlib::Absolutepath       $install_dir          = "${minecraft::install_base}/${instance}",
  String                     $source               = '1.7.4',
  Enum['running', 'stopped'] $service_ensure       = 'running',
  Boolean                    $service_enable       = true,
  Pattern[/^\d+(M|G)?$/]     $xmx                  = '1024M',
  Pattern[/^\d+(M|G)?$/]     $xms                  = '512M',
  Hash                       $plugins              = {},
  Optional[Array[String]]    $ops                  = [],
  Optional[Array[String]]    $banned_players       = [],
  Optional[Array[String]]    $banned_ips           = [],
  Optional[Array[String]]    $white_list_players   = [],
  Pattern[/^\d{3,4}$/]       $mode                 = '0750',
  Stdlib::Absolutepath       $init_path            = $minecraft::init_path,
  String                     $init_template        = $minecraft::init_template,
  Optional[Hash]             $plugins_defaults     = {},
  String                     $java_args            = '',
  String                     $jar                  = 'minecraft_server.jar',
  Hash                       $server_properties    = {},
  Optional[String]           $java_command         = 'java',
) {

  # Ensures deletion of install_dir does not break module, setup for plugins
  $dirs = [ $install_dir, "${install_dir}/plugins" ]

  file { $dirs:
    ensure  => 'directory',
    owner   => $user,
    group   => $group,
    mode    => $mode,
  }

  minecraft::source { $title:
    source      => $source,
    install_dir => $install_dir,
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
  #  file { "${install_dir}/${cfg_file}":
  #    ensure => 'file',
  #    content => template("minecraft/${cfg_file}.erb"),
  #    owner   => $user,
  #    group   => $group,
  #    mode    => '0660',
  #    require => Minecraft::Source[$title],
  #  }
  #}

  file { "${install_dir}/server.properties":
    ensure  => 'file',
    owner   => $user,
    group   => $group,
    mode    => '0660',
    require => Minecraft::Source[$title],
  }

  $server_properties.each |$_property, $_value| {
    augeas { "minecraft-${title}-${_property}":
      lens    => 'Properties.lns',
      incl    => "${install_dir}/server.properties",
      changes => [ "set \"${_property}\" \"${_value}\"" ],
      notify  => Minecraft::Service[$title],
    }
  }

  minecraft::service { $title:
    instance       => $instance,
    install_dir    => $install_dir,
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

  $_plugin_defaults = $plugin_defaults ? {
    undef   => {
      install_dir => $install_dir,
      user        => $user,
      group       => $group,
      ensure      => $present,
      require     => Minecraft::Source[$title],
      notify      => Minecraft::Service[$title],
    },
    default => $plugin_defaults,
  }

  create_resources('minecraft::plugin', $plugins, $_plugin_defaults)
}

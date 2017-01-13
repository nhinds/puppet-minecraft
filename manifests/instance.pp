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

  # The following are server.properties attributes, see
  # http://minecraft.gamepedia.com/Server.properties for information
  # Empty strings are represented as empty in templates, unlike undef
  $generator_settings   = '',
  $op_permisison_level  = 4,
  $allow_nether         = true,
  $level_name           = 'world',
  $enable_query         = false,
  $allow_flight         = false,
  $announce_achievments = true,
  $server_port          = 25565,
  $level_type           = 'DEFAULT',
  $enable_rcon          = false,
  $force_gamemode       = false,
  $level_seed           = '',
  $server_ip            = '',
  $max_build_height     = 256,
  $spawn_npcs           = true,
  $white_list           = false,
  $spawn_animals        = true,
  $snooper_enabled      = true,
  $hardcore             = false,
  $online_mode          = true,
  $resource_pack        = '',
  $pvp                  = true,
  $difficulty           = 1,
  $enable_command_block = false,
  $gamemode             = 0,
  $player_idle_timeout  = 0,
  $max_players          = 20,
  $spawn_monsters       = true,
  $gen_structures       = true,
  $view_distance        = 10,
  $spawn_protection     = 16,
  $motd                 = 'A Minecraft Server',
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
    require     => File[$dirs],
  }

  [ 'server.properties',
    'ops.txt',
    'banned-players.txt',
    'banned-ips.txt',
    'white-list.txt',
  ].each |$cfg_file| {
    file { "${install_dir}/${cfg_file}":
      ensure => 'file',
      content => template("minecraft/${cfg_file}.erb"),
      owner   => $user,
      group   => $group,
      mode    => '0660',
      require => Minecraft::Source[$title],
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
    java_args      => $java_args,
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

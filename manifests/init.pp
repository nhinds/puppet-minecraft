class minecraft(
  Stdlib::Absolutepath $install_base         = '/opt/minecraft',
  Pattern[/^[\w]+$/]   $user                 = 'minecraft',      # The user account for the Minecraft service
  Pattern[/^[\w]+$/]   $group                = 'minecraft',      # The user group for the Minecraft service
  Boolean              $manage_user          = true,
  Boolean              $manage_group         = true,
  String               $user_shell           = '/usr/sbin/nologin',
  Stdlib::Absolutepath $user_home            = $install_base,
  Boolean              $manage_home          = false,
  Boolean              $manage_install_base  = true,
  String               $mode                 = '0750',
  Optional[Hash]       $instances            = {},
  Optional[Hash]       $instance_defaults    = {},
  Stdlib::Absolutepath $init_path            = $minecraft::params::init_path,
  String               $init_template        = $minecraft::params::init_template,
) inherits minecraft::params {

  if $manage_group {
    group { $group:
      ensure => 'present',
    }
  }

  if $manage_user {
    user { $user:
      ensure => 'present',
      shell  => $user_shell,
      home   => $user_home,
      managehome => $manage_home,
    }
  }

  if $manage_install_base {
    file { $install_base:
      ensure => 'directory',
      owner  => $user,
      group  => $group,
      mode   => $mode,
    }
  }

  create_resources('minecraft::instance', $instances, $instance_defaults)
}

class minecraft::params {

  case $::osfamily {
    'FreeBSD': {
      $init_path = '/usr/local/etc/rc.d'
      $init_template = 'minecraft/minecraft.erb'
    }

    default: {
      $init_path = '/etc/init.d'
      $init_template = 'minecraft/minecraft.erb'
    }
  }
}

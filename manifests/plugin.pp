define minecraft::plugin(
  $source,
  $install_dir,
  $plugin_name  = $title,
  $ensure       = present,
  $user,
  $group,
) {

  if $plugin_name =~ /^.*\.jar$/ {
    fail("minecraft plugin title ${plugin_name} must not end in '.jar'")
  }

  archive { $plugin_name:
    ensure  => $ensure,
    source  => $source,
    path    => "${install_dir}/plugins/${plugin_name}.jar",
    user    => $user,
  }

  if $ensure == present {
    $jar_ensure = file
  } else {
    $jar_ensure = $ensure
  }

  file { "${install_dir}/plugins/${plugin_name}.jar":
    ensure  => $jar_ensure,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    require => Archive[$plugin_name],
  }
}

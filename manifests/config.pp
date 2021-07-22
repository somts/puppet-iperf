# Manage an iperf feature/service
class iperf::config(
  Integer[1-65535] $port,
  Variant[Undef,Enum['k','m','g','t','K','M','G','T']] $format,
  Integer $interval,
  Variant[Undef,Stdlib::Absolutepath] $file,
  Variant[Undef,Integer] $affinity,
  Variant[Undef,Stdlib::IP::Address] $bind,
  Boolean $verbose,
  Boolean $json,
  Variant[Undef,Stdlib::Absolutepath] $logdir,
  Variant[Undef,String] $logfilename,
  Boolean $forceflush,
  Boolean $debug,
  Variant[Undef,String] $pidfilename,
  Variant[Undef,Stdlib::Absolutepath] $piddir,
  Variant[Undef,Stdlib::Absolutepath] $one_off,
  Variant[Undef,Stdlib::Absolutepath] $rsa_private_key_path,
  Variant[Undef,Stdlib::Absolutepath] $authorized_users_path,
) {
  # VARIABLES
  $_logdir = $logdir ? {
    undef   => "/var/log/${iperf::service_name}",
    default => $logdir,
  }
  $logfile = $logfilename ? {
    undef   => "${_logdir}/${iperf::service_name}.log",
    default => "${_logdir}/${logfilename}",
  }
  $_piddir = $piddir ? {
    undef   => "/var/run/${iperf::service_name}",
    default => $piddir,
  }
  $pidfile = $pidfilename ? {
    undef   => "${_piddir}/${iperf::service_name}.pid",
    default => "${_piddir}/${pidfilename}",
  }

  # MANAGED RESOURCES
  group { $iperf::group:
    system => true,
  }

  user { $iperf::user:
    comment    => "${iperf::service_name} service role account",
    groups     => [$iperf::group],
    managehome => true,
    membership => 'minimum',
    password   => '*LK*',
    shell      => '/bin/false',
    system     => true,
  }

  file {
    $_logdir:
      ensure  => 'directory',
      owner   => $iperf::user,
      group   => $iperf::group,
      mode    => '0755',
      require => User[$iperf::user],;
    $_piddir:
      ensure  => 'directory',
      owner   => $iperf::user,
      group   => $iperf::group,
      mode    => '0755',
      require => User[$iperf::user],;
  }

  systemd::unit_file { "${iperf::service_name}.service":
    require => User[$iperf::user],
    content => epp('iperf/iperf.systemd.epp', {
      'service_name' => $iperf::service_name,
      'path'         => $iperf::_path,
      'pidfile'      => $pidfile,
      'user'         => $iperf::user,
      'group'        => $iperf::group,
      'exec_args'    => delete_undef_values({
        '--affinity'              => $affinity,
        '--authorized-users-path' => $authorized_users_path,
        '--bind'                  => $bind,
        '--daemon'                => true,
        '--debug'                 => $debug,
        '--file'                  => $file,
        '--forceflush'            => $forceflush,
        '--format'                => $format,
        '--interval'              => $interval,
        '--json'                  => $json,
        '--logfile'               => $logfile,
        '--one_off'               => $one_off,
        '--pidfile'               => $pidfile,
        '--port'                  => $port,
        '--rsa_private_key_path'  => $rsa_private_key_path,
        '--server'                => true,
        '--verbose'               => $verbose,
      }),
    }),
  }

  # TODO firewall
  #if $iperf::firewall_manage {
  #}
  # TODO logrotate
  #if $iperf::logrotate_manage {
  #}
}

# Manage an iperf feature/service
class iperf::config(
  Integer[1-65535] $port,
  Variant[Enum['k','m','g','t','K','M','G','T'], Undef] $format,
  Integer $interval,
  Variant[Stdlib::Absolutepath, Undef] $file,
  Variant[Integer, Undef] $affinity,
  Variant[Stdlib::IP::Address, Undef] $bind,
  Boolean $verbose,
  Boolean $json,
  Variant[Stdlib::Absolutepath, Undef] $logdir,
  Variant[String, Undef] $logfilename,
  Boolean $forceflush,
  Boolean $debug,
  Variant[String, Undef] $pidfilename,
  Variant[Stdlib::Absolutepath, Undef] $piddir,
  Variant[Stdlib::Absolutepath, Undef] $one_off,
  Variant[Stdlib::Absolutepath, Undef] $rsa_private_key_path,
  Variant[Stdlib::Absolutepath, Undef] $authorized_users_path,
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
  # When/if we support non-Linux platforms, such (FreeBSD/Windows/etc?)
  # this variable will need adjustment.
  $postrotate = "/bin/systemctl restart ${iperf::service_name}"

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

  if $iperf::firewall_manage {
    firewall {
      "${iperf::firewall_order} ${iperf::service_name} TCP":
        action => 'accept',
        chain  => $iperf::firewall_chain,
        dport  => $port,
        proto  => 'tcp',;
      "${iperf::firewall_order} ${iperf::service_name} UDP":
        action => 'accept',
        chain  => $iperf::firewall_chain,
        dport  => $port,
        proto  => 'udp',;
    }
  }

  if $iperf::logrotate_manage {
    logrotate::rule { $iperf::service_name :
      compress      => true,
      delaycompress => true,
      missingok     => true,
      path          => $logfile,
      postrotate    => $postrotate,
      rotate        => $iperf::logrotate_rotate,
      rotate_every  => $iperf::logrotate_rotate_every,
      su_user       => $iperf::user,
      su_group      => $iperf::group,
    }
  }
}

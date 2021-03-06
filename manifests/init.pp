# Manage an iperf installation
class iperf(
  Enum['present', 'absent'] $ensure,
  Variant[Array, String] $package,
  Boolean $package_manage,
  Enum['iperf', 'iperf3'] $service_name,
  Enum['running', 'stopped'] $service_ensure,
  Boolean $service_enable,
  Boolean $logrotate_manage,
  Integer $logrotate_rotate,
  Enum['day', 'week', 'month'] $logrotate_rotate_every,
  Boolean $firewall_manage,
  Variant[String, Undef] $firewall_chain,
  String $firewall_order,
  Variant[Stdlib::Absolutepath, Undef] $path,
  String $user,
  String $group,
) {
  # VALIDATION
  validate_re('^Linux$', $facts['kernel'], "${facts[kernel]} unsupported")

  # VARIABLES
  $_path = $path ? {
    undef   => "/usr/bin/${service_name}",
    default => $path,
  }

  # MANAGED RESOURCES
  if $ensure == 'present' {
    Class['iperf::install'] -> Class['iperf::config'] ~> Class['iperf::service']
  } else {
    Class['iperf::service'] -> Class['iperf::config'] -> Class['iperf::install']
  }
  contain iperf::install
  contain iperf::config
  contain iperf::service
}

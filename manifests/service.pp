# Manage iperf service
class iperf::service {
  service { $iperf::service_name :
    ensure => $iperf::service_ensure,
    enable => $iperf::service_enable,
  }
}

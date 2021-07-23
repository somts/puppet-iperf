# Manage installation of iperf package(s)
class iperf::install {
  if $iperf::package_manage {
    package { $iperf::package :
      ensure => $iperf::ensure,
    }
  }
}

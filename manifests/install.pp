# Manage installation of iperf package(s)
class iperf::install {
  package { $iperf::package :
    ensure => $iperf::ensure,
  }
}

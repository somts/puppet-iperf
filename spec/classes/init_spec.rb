require 'spec_helper'
describe 'iperf' do
  shared_examples 'Supported Platform' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('iperf') }

    # Install
    it {
      is_expected.to contain_class('iperf::install').that_comes_before(
        'Class[iperf::config]',
      )
    }
    it { is_expected.to contain_package('iperf3') }

    context 'with package_manage = false' do
      let :params do
        { package_manage: false }
      end

      it { is_expected.not_to contain_package('iperf3') }
    end

    # Config
    it {
      is_expected.to contain_class('iperf::config').that_notifies(
        'Class[iperf::service]',
      )
    }
    it { is_expected.to contain_group('iperf3') }
    it { is_expected.to contain_user('iperf3').with_system(true) }
    it {
      is_expected.to contain_file('/var/log/iperf3').with(
        ensure: 'directory',
        owner: 'iperf3',
      ).that_requires('User[iperf3]')
    }
    it {
      is_expected.to contain_file('/var/run/iperf3').with(
        ensure: 'directory',
        owner: 'iperf3',
      )
    }
    it {
      is_expected.to contain_systemd__unit_file('iperf3.service').with(
        content: %r{\nExecStart=/usr/bin/iperf3 --daemon --interval=1},
      )
    }
    it {
      is_expected.to contain_firewall('052 iperf3 TCP').with(
        action: 'accept',
        chain: nil,
        dport: 5201,
        proto: 'tcp',
      )
    }
    it {
      is_expected.to contain_firewall('052 iperf3 UDP').with(
        action: 'accept',
        chain: nil,
        dport: 5201,
        proto: 'udp',
      )
    }
    context 'with firewall_manage = false' do
      let :params do
        { firewall_manage: false }
      end

      it do is_expected.not_to contain_firewall('052 iperf3 TCP') end
      it do is_expected.not_to contain_firewall('052 iperf3 UDP') end
    end

    it do
      is_expected.to contain_logrotate__rule('iperf3').with(
        compress: true,
        delaycompress: true,
        missingok: true,
        path: '/var/log/iperf3/iperf3.log',
        postrotate: '/bin/systemctl restart iperf3',
        rotate: 7,
        rotate_every: 'day',
        su_group: 'iperf3',
        su_user: 'iperf3',
      )
    end

    context 'with logrotate_manage = false' do
      let :params do
        { logrotate_manage: false }
      end

      it do is_expected.not_to contain_logrotate__rule('iperf3') end
    end

    context 'with logrotate tunes' do
      let :params do
        { logrotate_rotate: 30, logrotate_rotate_every: 'week' }
      end

      it do
        is_expected.to contain_logrotate__rule('iperf3').with(
          rotate: 30,
          rotate_every: 'week',
        )
      end
    end

    # Service
    it { is_expected.to contain_class('iperf::service') }
    it {
      is_expected.to contain_service('iperf3').with(
        ensure: 'running',
        enable: true,
      )
    }
    context 'with service_ensure = stopped and service_enable = stopped' do
      let :params do
        { service_ensure: 'stopped', service_enable: false }
      end

      it do
        is_expected.to contain_service('iperf3').with(
          ensure: 'stopped',
          enable: false,
        )
      end
    end
  end

  shared_examples 'Linux' do
    it_behaves_like 'Supported Platform'
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let :facts do
        os_facts
      end

      case os_facts[:kernel]
      when 'Linux' then it_behaves_like 'Linux'
      else it_behaves_like 'Unsupported Platform'
      end
    end
  end
end

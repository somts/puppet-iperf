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

    # Service
    it { is_expected.to contain_class('iperf::service') }
    it {
      is_expected.to contain_service('iperf3').with(
        ensure: 'running',
        enable: true,
      )
    }
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

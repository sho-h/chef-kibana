# Encoding: utf-8

require_relative 'spec_helper'

describe 'kibana_lwrp::install' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::ServerRunner.new(::UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) do
      # runner.node.default['logstash'] ...
      runner.node.default['kibana']['user'] = 'kibanana'
      runner.node.default['kibana']['install_dir'] = '/opt/kibanana'
      runner.node.default['kibana']['install_type'] = 'file'
      runner.node.default['kibana']['config_template'] = 'config.js.erb'
      runner.node.default['kibana']['config_cookbook'] = 'kibana'
      runner.node.default['kibana']['webserver'] = 'nginx'
      runner.node.default['kibana']['es_server'] = '127.0.0.1'
      runner.node.default['kibana']['nginx']['template'] = 'kibana-nginx.conf.erb'
      runner.node.default['kibana']['nginx']['template_cookbook'] = 'kibana'
      runner.node.default['kibana']['nginx']['enable_default_site'] = false
      runner.node.default['kibana']['nginx']['install_method'] = 'package'
      runner.node.default['kibana']['service']['options']['sv_timeout'] = 42
      runner.node.automatic['memory']['total'] = '1024kB'
      runner.converge(described_recipe)
    end
    include_context 'stubs-common'

    it 'creates kibana user' do
      expect(chef_run).to create_kibana_user('kibanana').with(
        user: 'kibanana',
        group: 'kibanana',
        home: '/opt/kibanana'
      )
    end

    it 'installs kibana' do
      expect(chef_run).to create_kibana_install('kibana').with(
        user: 'kibanana',
        group: 'kibanana',
        install_dir: '/opt/kibanana',
        install_type: 'file'
      )
    end

    it 'creates kibana config from template' do
      expect(chef_run).to create_template('/opt/kibanana/current/config/kibana.yml').with(
        source: 'kibana.yml.erb',
        cookbook: 'kibana_lwrp',
        mode: '0644',
        user: 'kibanana'
      )
    end

    it 'installs and configures a webserver' do
      expect(chef_run).to create_kibana_web('kibana').with(
        type: 'nginx',
        docroot: '/opt/kibanana/current/kibana',
        es_server: '127.0.0.1'
      )
    end

    it 'creates a runit service for kibana' do
      expect(chef_run).to enable_runit_service('kibana').with(sv_timeout: 42)
    end
  end
end

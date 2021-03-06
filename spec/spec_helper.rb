# frozen_string_literal: true

require "net/ssh"
require "serverspec"

set :backend, :ssh

options = Net::SSH::Config.for(host)
options = {}
ssh_config = ""
Bundler.with_unbundled_env do
  ENV.delete("GEM_HOME")
  ssh_config = `vagrant ssh-config #{ENV.fetch("HOST", nil)}`
end

ssh_config.each_line do |line|
  if (match = /HostName (.*)/.match(line))
    options[:host_name] = match[1]
  elsif (match = /User (.*)/.match(line))
    options[:user] = match[1]
  elsif (match = /IdentityFile (.*)/.match(line))
    options[:keys] = [match[1].delete('"')]
  elsif (match = /Port (.*)/.match(line))
    options[:port] = match[1]
  end
end

set :host, options[:host_name]
set :ssh_options, options

PROVIDER = ENV["HOST"].split("-").last

def qemu?
  PROVIDER == "libvirt"
end

def virtualbox?
  PROVIDER == "virtualbox"
end

def vmware?
  %w[vmware_desktop vmware_fusion vmware_workstation].include?(PROVIDER)
end

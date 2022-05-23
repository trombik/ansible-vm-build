# frozen_string_literal: true

require "rspec/core/rake_task"
require "shellwords"

name = File.basename(Dir.pwd)

task default: ["build"]

desc "build box (default)"
task "build" do
  sh "packer build -only virtualbox-iso.default box.pkr.hcl"
end

desc "Run the VM"
task "up" do
  Bundler.with_unbundled_env do
    ENV.delete("GEM_HOME")
    sh "vagrant up"
  end
end

def box_version
  Time.new.strftime("%Y%m%d.%H%M")
end

def box_name
  Pathname.pwd.basename.to_s.split("-").first.downcase
end

def box_os_version
  Pathname.pwd.basename.to_s.split("-").last
end

def box_user
  ENV.fetch("VAGRANT_CLOUD_USER", nil) || ENV.fetch("USER", nil)
end

def publish_command
  "vagrant cloud publish --force --release " \
    "#{box_user.shellescape}/ansible-#{box_name.shellescape}-#{box_os_version.shellescape}-amd64 " \
    "#{box_version.shellescape} virtualbox virtualbox.box"
end

desc "Run rspec"
task "test" do
  ENV["HOST"] = "virtualbox"
  sh "rspec -f d --pattern '../spec/**/*_spec.rb'"
  puts "Test succeeded. To upload run:"
  puts
  puts publish_command.to_s
  puts
  puts "Or run:"
  puts
  puts "rake publish"
end

desc "Publish the box"
task "publish" do
  unless ENV["VAGRANT_CLOUD_TOKEN"]
    raise "VAGRANT_CLOUD_TOKEN environtment variable is not defined. " \
          "Set the variable with your API token, and try again"
  end

  Bundler.with_unbundled_env do
    ENV.delete("GEM_HOME")
    sh publish_command.to_s
  end
end

desc "Destroy VM, remove output"
task "clean" do
  Bundler.with_unbundled_env do
    ENV.delete("GEM_HOME")
    sh "vagrant destroy -f || true"
    sh "vagrant box remove test/#{name.shellescape} || true"
  end
  sh "rm -rf output"
end

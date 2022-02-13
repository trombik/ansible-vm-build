# frozen_string_literal: true

require_relative "spec_helper"

case os[:family]
when "openbsd"
  describe command("mount -t ffs") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    its(:stdout) do
      should match(/^#{Regexp.escape("/dev/wd0")}/)
    end
  end
when "redhat"
  describe command("mount -t xfs") do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    its(:stdout) { should match(/^#{Regexp.escape("/dev/sda")}/) }
  end
when "freebsd"
  describe command("mount -t ufs") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^#{Regexp.escape("/dev/")}(?:a?da0|vtbd0s1a)/) }
    its(:stderr) { should eq "" }
  end
when "ubuntu"
  describe command("mount -t ext4") do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match(/^#{Regexp.escape("/dev/sda")}/) }
    its(:stderr) { should eq "" }
  end
end

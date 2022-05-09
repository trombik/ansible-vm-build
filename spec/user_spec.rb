# frozen_string_literal: true

require_relative "spec_helper"

describe group "ansible" do
  it { should exist }
end

describe user "vagrant" do
  it { should exist }
  it { should belong_to_group "ansible" }
end

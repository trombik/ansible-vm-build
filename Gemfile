# frozen_string_literal: true

source "https://rubygems.org"

gem "pry"
gem "rake"
gem "rspec"
gem "rubocop"
gem "serverspec"
gem "vagrant_cloud"

# ed25519 support required for recent OpenSSH
gem "bcrypt_pbkdf"
gem "ed25519"

# install the latest mime-types. failed in ubuntu-latest GitHub runner.
#
# SyntaxError:
# /opt/hostedtoolcache/Ruby/3.0.1/x64/lib/ruby/gems/3.0.0/gems/mime-types-3.2.2/lib/mime/types/logger.rb:
# 30: _1 is reserved for numbered parameter
gem "mime-types", ">= 3.3.1"

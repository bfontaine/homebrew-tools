#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

if ARGV.length != 2
  puts "Usage: brew pypi-resource <package name> <version>"
  exit 1
end

pkg, version = *ARGV

url = "https://pypi.python.org/packages/source/#{pkg[0]}/#{pkg}/#{pkg.gsub("-", "_")}-#{version}.tar.gz"

# I'm just lazy here. Note that this doesn't check HTTP errors
sha256 = `curl -sL #{url} |shasum -a 256`.split(/ +/)[0]

puts <<-EOS
  resource "#{pkg}" do
    url "#{url}"
    sha256 "#{sha256}"
  end
EOS

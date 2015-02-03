#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

# brew
require "formula"

if ARGV.empty?
  system "brew", "--version"
else
  ARGV.each do |arg|
    f = Formula[arg]
    puts "#{f.name} #{f.version}"
  end
end

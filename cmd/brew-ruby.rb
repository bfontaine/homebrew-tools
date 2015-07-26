# -*- coding: UTF-8 -*-

# get the class extensions from the "irb" command
require "cmd/irb"

unless ARGV.empty?
  require ARGV.first
else
  puts "Usage:\n\t\tbrew ruby <filename>"
end

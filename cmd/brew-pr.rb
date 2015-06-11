# -*- coding: UTF-8 -*-

ARGV.named.each do |n|
  next unless n =~ /^#?\d+$/
  system "open", "https://github.com/Homebrew/homebrew/pull/#{n.sub(/^#/, "")}"
end

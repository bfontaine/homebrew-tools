# -*- coding: UTF-8 -*-

require "formula"
system "git", "blame", *(ARGV.map { |arg| Formula[arg].path rescue arg })

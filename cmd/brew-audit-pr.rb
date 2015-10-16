# -*- coding: UTF-8 -*-

require "json"

ARGV.named do |arg|
  unless arg.start_with? "https://github.com/Homebrew/homebrew/pull/"
    onoe "'#{arg}' doesn't seem like a pull-request URL"
    exit 1
  end

  pr = arg[%r{pull/(\d+)}]
  url = "https://api.github.com/repos/Homebrew/homebrew/pulls/#{pr}/files"
  has_formula = false

  JSON.parse(`curl #{HOMEBREW_CURL_ARGS} #{url}`).each do |file|
    next unless file["raw_url"] =~ %r{/Library/Formula/[-\w]+\.rb}
    has_formula = true

    # TODO
  end

  unless has_formula
    opoo "The pull-request ##{pr} doesn't include any formula file"
    next
  end


end

# https://github.com/Homebrew/homebrew/pull/44712

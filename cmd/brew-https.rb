# -*- coding: UTF-8 -*-
#
# Experimental script to convert HTTP URLs into HTTPS one if possible. Note
# that there are still a lot of false positives so you have to double-check
# each URL.
#
# It modifies each formula in-place.

require "formula"

CURL_ARGS = %(#{HOMEBREW_CURL_ARGS} "#{HOMEBREW_USER_AGENT}" --connect-timeout 4)

def https_urls urls
  fixed = {}

  urls.each do |http|
    next unless http.start_with? "http://"

    # let's avoid git URLs for now since `curl` might succeed but not `git`
    next if http.end_with? ".git"

    https = http.sub(%r{^http://}, "https://")

    http_sha = `curl #{CURL_ARGS} #{http} | shasum -a 256`
    https_sha = `curl #{CURL_ARGS} #{https} | shasum -a 256`

    fixed[http] = https if http_sha == https_sha
  end

  fixed
end

ff = if ARGV.named.empty?
       Formula
     else
       ARGV.resolved_formulae
     end

ff.each do |f|
  next if f.tap?

  urls = [f.homepage]
  urls << f.stable.url if f.stable
  urls << f.devel.url if f.devel
  urls << f.head.url if f.head

  urls += f.resources.map(&:url)
  urls += f.patchlist.select(&:external?).map { |p| p.resource.url }

  fixed_urls = https_urls(urls)
  next if fixed_urls.empty?

  content = f.path.read

  fixed_urls.each_pair do |http, https|
    content.gsub!(/"#{Regexp.escape http}"/, %("#{https}"))
  end

  ohai "Fixed #{fixed_urls.size} URLs on formula '#{f.name}'"

  f.path.open("w") { |p| p.write content }

  sleep 0.5
end

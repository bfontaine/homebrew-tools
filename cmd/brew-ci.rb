#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-
#
# brew-ci
# =======
#
# Usage:
#
#   brew ci <command> [options] [args]
#
# Commands:
#
#   brew ci bottle-elcap <formula> [<formula> ...]
#     Trigger an "El Capitan Testing" job for the given formula.
#
require "shellwords"

module HomebrewCI
  class << self
    ROOT_URL = "http://bot.brew.sh"

    def bottle_el_capitan(formulae)
      formulae.each do |f|
        trigger_job("Homebrew El Capitan Testing", {:BOT_PARAMS => f.full_name})
      end
    end

    private

    def curl(*args)
      `/usr/bin/curl -sfL #{Shellwords.join args}`
    end

    def curl_with_auth(*args)
      if ENV["HOMEBREW_CI_AUTH"]
        args << "--user" << ENV["HOMEBREW_CI_AUTH"]
      else
        args << "--netrc"
      end

      curl(*args)
    end

    def job_url(name)
      "#{ROOT_URL}/job/#{URI.escape name}"
    end

    def trigger_job(name, params={})
      url = job_url(name)
      if params.empty?
        url << "/build"
      else
        url << "/buildWithParameters?#{URI.encode_www_form params}"
      end

      curl_with_auth "-XPOST", url
    end
  end
end

case ARGV.shift
  when "bottle-elcap"
    HomebrewCI.bottle_el_capitan ARGV.formulae
  when nil, "help", "-h", /--?help/
    puts <<-EOS.undent
      Usage:
        brew ci <command> [options] [args]
      Commands:
        bottle-elcap <formulae...> -- Trigger El Capitan bottle builds
        help                       -- Print this help
    EOS
    exit 1 if ARGV.empty?
end

#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require "open-uri"
require "net/ftp"

# brew
require "formula"
require "version"

# need to be installed with "gem"
require "nokogiri"

module GnuFTP
  class << self
    @@ftp = nil

    attr_reader :ftp

    def connection(force=false)
      if force || @@ftp.nil?
        @@ftp = Net::FTP.open("ftp.gnu.org")
        @@ftp.login
      end
      @@ftp
    end
  end
end

module BrewCheckUpdates

  class Checker

    def initialize(checks, **flags)
      @prefix = "#{HOMEBREW_PREFIX}/Library/Formula"
      @checks = checks.map { |c| [c.name, c.new] }
      @flags = flags
    end

    def check(formulae=[])
      pattern = formulae.empty? ? "*" : "{#{formulae * ","}}"
      Dir["#{@prefix}/#{pattern}.rb"].each { |p| check_formula p }
    end

    private

    def check_formula path
      return if File.symlink? path # no tap for now
      formula = Formula[path]

      for name, ch in @checks
        if ch.can_check formula
          version = formula.version
          #puts "checking #{basename} (v#{version}) with #{name}"
          result = ch.check formula
          if result
            latest, url = result
            puts "(#{name}) #{formula.name} #{version} -> #{latest}: #{url}"
          end
          return
        end
      end
    end

  end

  module CheckDSL
    def name s=nil
      @name = s || @name
    end

    def pattern p=nil
      @pattern = p || @pattern
    end
  end

  class Check
    extend CheckDSL

    def can_check formula
      pattern && formula.stable.url =~ pattern
    end

    def check formula; end

    def pattern;self.class.pattern;end

    def get_page url
      begin
        Nokogiri::HTML(open(url))
      rescue
      end
    end

    class << self
      def inherited child
        @checks ||= []
        @checks << child
      end

      def all
        @checks || []
      end
    end
  end

  class GitHubCheck < Check
    name "GitHub"
    pattern %r(^https?://github\.com/.+?/.+?/)

    def check formula
      repo = formula.stable.url[pattern]
      page = get_page "#{repo}releases"

      return if page.nil?

      tags = [".tag-name", ".tag-references .css-truncate-target"].map do |t|
        page.css(t).first
      end.compact.map { |t| Version::parse(t.text) }.compact

      current = formula.version
      latest = tags.select { |v| v > current }.sort.last

      unless latest.nil?
        latest_url = "#{repo}archive/#{latest}.tar.gz"
        [latest, latest_url]
      end
    end
  end

  class GnuFtp < Check
    name "GNU FTP"
    pattern %r(^http://ftpmirror\.gnu\.org/)

    def check formula
      name = formula.name.downcase
      version = formula.version
      url = URI::parse(formula.stable.url)
      co = GnuFTP.connection

      dir = url.path.split("/")[1]

      co.chdir("/gnu/#{dir}")

      files = co.list("#{name}*").map { |l| l.split(/\s+/).last }.select do |s|
        # add more checks here if there are false positives
        [/\.sig$/, /\.asc$/, /\.diff/, /\.patch/].all? { |r| s !~ r }
      end

      candidates = files.map { |s| [s, Version::parse(s)] }
      candidates.select! do |_, v|
        !v.nil? && v > version
      end
      candidate = candidates.sort_by!(&:last).last

      if candidate
        archive, version = candidate
        new_url = "#{url.scheme}://#{url.host}/#{dir}/#{archive}"

        [version, new_url]
      end
    end
  end

  # Since Google Code doesn't allow new code uploads we can't find new
  # versions. This class is an empty trap for the Google Code formulae.
  class GoogleCodeCheck < Check
    name "Google Code"
    pattern %r(googlecode\.com)
  end

  class << self
    def run(formulae=nil)
      Checker.new(Check.all).check formulae
    end
  end
end

# run
BrewCheckUpdates.run ARGV

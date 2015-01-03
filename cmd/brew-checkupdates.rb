#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'pathname'
require 'open-uri'

# need to be installed with 'gem'
require 'nokogiri'

module BrewCheckUpdates

  class Checker

    def initialize(checks, **flags)
      homebrew_prefix = Object.const_defined?('HOMEBREW_PREFIX') \
                          ? HOMEBREW_PREFIX : '/usr/local'

      @prefix = "#{homebrew_prefix}/Library/Formula"
      @checks = checks.map { |c| [c.name, c.new] }
      @flags = flags
    end

    def check
      Dir["#{@prefix}/*.rb"].each { |p| check_formula p }
    end

    private

    def check_formula path
      return if File.symlink? path # no tap for now
      basename = Pathname.new(path).basename.to_s.sub(/\.rb$/, '')
      name = basename.capitalize.gsub(/[-_\.](.)/) { $1.upcase } \
                                .gsub(/\+/, 'x')

      require path
      formula = Object.const_get(name)

      # just checking
      for name, ch in @checks
        if ch.can_check formula
          version = formula.version
          puts "checking #{basename} (v#{version})"
          result = ch.check formula
          return unless result
          latest, url = result
          puts "--> found #{latest}: #{url}"
          return
        end
      end
    end

  end

  class Version
    include Comparable

    attr_reader :major, :minor, :patch

    def initialize(s)
      @major, @minor, @patch = 0, 0, 0
      @s = s.to_s

      if @s =~ /(\d+)[-\.](\d+)(?:[-\.]r?(\d+))?/i
        @major, @minor, @patch = $1.to_i, $2.to_i, $3.to_i
      elsif @s =~ /v?(\d+)/
        @major = $1.to_i
      elsif @s =~ /(?:\w+_)?(\d+)_(\d+)/
        @major, @minor = $1.to_i, $2.to_i
      elsif @s =~ /(?:[rv]|rel|release-v|snapshot-)(\d+)/i
        @major = $1.to_i
      #else
      #  puts "Couldn't parse #{s.inspect}"
      end
    end

    def <=>(other)
      r = self.major <=> other.major
      if r == 0
        r = self.minor <=> other.minor
        if r == 0
          r = self.patch <=> other.patch
        end
      end
      r
    end

    def to_s
      @s
    end
  end

  module CheckDSL
    def name s=nil
      @name = s || @name
    end
  end

  class Check
    extend CheckDSL

    def can_check formula; end
    def check formula; end

    def get_page url
      begin
        Nokogiri::HTML(open(url))
      rescue
      end
    end

    def latest_version versions
      versions.map { |v| Version.new(v) }.sort[-1]
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
    name 'GitHub'

    @@gh_re = %r(^(https?://github\.com/.+?/.+?/))

    def can_check formula
      formula.stable.url =~ @@gh_re
    end

    def check formula
      url = formula.stable.url
      return unless url =~ @@gh_re
      repo = $1
      page = get_page "#{repo}releases"

      return if page.nil?

      # take only the first tag/release in the page
      tags = ['.tag-name', '.tag-references .css-truncate-target'].map do |t|
        page.css(t).first
      end.compact.map(&:text)

      current = Version.new formula.version
      latest = latest_version tags

      latest_url = "#{repo}archive/#{latest}.tar.gz"

      return if current == latest or latest_url == url or latest.nil? or
        url =~ %r(^#{repo}releases/download/#{latest}/)

      [latest, latest_url]
    end
  end

  class SourceForgeCheck < Check
    name 'SourceForge'

    def can_check formula
      formula.stable.url =~ %r(^https?://downloads\.sourceforge\.net/)
    end

    def check formula
      # TODO
    end
  end

  class GoogleCodeCheck < Check
    name 'Google Code'

    def can_check formula
      formula.stable.url =~ %r(^https?://code\.google\.com/) or
        formula.stable.url =~ %r(^https?://[-\w]+\.googlecode\.com/)
    end

    def check formula
      # TODO
    end
  end

  class BitBucketCheck < Check
    name 'BitBucket'

    def can_check formula
      formula.stable.url =~ %r(^https?://bitbucket\.org/)
    end

    def check formula
      # TODO
    end
  end

  class GnomeFtp < Check
    name 'GNOME FTP'

    def can_check formula
      formula.stable.url =~ %r(^http://ftp\.gnome\.org/)
    end

    def check formula
      # TODO
    end
  end

  class << self
    def run
      Checker.new(Check.all).check
    end
  end
end

BrewCheckUpdates.run

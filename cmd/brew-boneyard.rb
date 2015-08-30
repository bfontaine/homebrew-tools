#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

github_user = `git config github.user`.chomp
fail "github.user is not set" if github_user == ""

core_repo = "#{github_user}/homebrew"
core_remote = "git@github.com:#{core_repo}.git"

boneyard_repo = "#{github_user}/homebrew-boneyard"
boneyard_remote = "git@github.com:#{boneyard_repo}.git"

migrations = "#{HOMEBREW_PREFIX}/Library/Homebrew/tap_migrations.rb"

ARGV.named.each do |name|
  source_dir = "#{HOMEBREW_PREFIX}/Library/Formula"
  target_dir = "#{HOMEBREW_PREFIX}/Library/Taps/homebrew/homebrew-boneyard"
  branch = "#{name}-boneyard"
  file = "#{name}.rb"

  source = "#{source_dir}/#{file}"
  target = "#{target_dir}/#{file}"

  fail "Source file #{source} doesn't exist" unless File.exist? source
  fail "Target file #{target} already exists" if File.exist? target

  FileUtils::Verbose.mv source, target

  # hacky way to add a line in the tap_migrations.rb file
  mlines = File.read(migrations).lines
  first_line = mlines[0]
  last_line = mlines[-1]
  File.open(migrations, "w") do |f|
    f.write first_line
    m = mlines.slice(1..-2)
    m << "  \"#{name}\" => \"homebrew/boneyard\",\n"
    m.sort.each do |line|
      f.write line
    end
    f.write last_line
  end

  FileUtils::Verbose.cd source_dir do
    system "git", "checkout", "master"
    system "git", "checkout", "-b", branch
    system "git", "add", file, migrations
    system "git", "commit", "-m", "#{name}: migrate to boneyard"
    system "git", "push", "-u", core_remote, branch
    system "git", "checkout", "master"
  end

  FileUtils::Verbose.cd target_dir do
    system "git", "checkout", "master"
    system "git", "checkout", "-b", branch
    system "git", "add", file
    system "git", "commit", "-m", "#{name}: migrate from core"
    system "git", "push", "-u", boneyard_remote, branch
    system "git", "checkout", "master"
  end

  sleep 0.2 # wait for GitHub to process the new stuff
  system "open", "https://github.com/#{core_repo}/compare/#{branch}?expand=1"
  system "open", "https://github.com/#{boneyard_repo}/compare/#{branch}?expand=1"
end

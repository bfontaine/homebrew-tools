tap_name = ARGV.value "tap"
tap = tap_name ? Tap.fetch(tap_name) : CoreTap.instance
args = ARGV.delete_if { |arg| arg.start_with? "--tap=" }
args << "-R"

# Shorten the paths in grep's output
args << tap.formula_dir.relative_path_from(Tap::TAP_DIRECTORY).to_s

FileUtils.cd Tap::TAP_DIRECTORY do
  system "/usr/bin/grep", *args
end

# This is based on an original idea by Jack Nagel:
#   https://github.com/jacknagel/dotfiles/blob/ed7bccff/bin/brew-for-each-formula.rb

require "formula"
if ARGV.size < 2
  puts <<-EOS.undent
    Usage:
      brew formula-eval <code> <formulae ...>

    This `eval`s <code> on each formula using `f` as its object. Each non-empty
    result is printed on its own line.

    Examples:

      $ brew formula-eval f.full_name ski
      homebrew/games/ski

      $ brew formula-eval "f.name if f.head" zsh git
      git

    Remember that the <code> part is executed as plain Ruby, so be careful with
    what you put here.
  EOS
  exit 1
end

code = ARGV.shift
ARGV.named.each do |name|
  f = Formula[name]
  res = eval(code)
  next if res.nil?

  if res.is_a? String
    next if res.empty?
    puts res
  else
    puts res.inspect
  end

  # silence rubocop
  _ = f
end

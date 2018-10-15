#:  * `old-formulas` [--top=20] [--max-commits=30000]:
#:    Find the top N oldest formulae in Homebrew's core tap by last
#:    modification date.

top_size = ARGV.value("top")&.to_i || 20
max_commits = ARGV.value("max-commits")&.to_i || 30000

(Tap.new("homebrew", "core").path/"Formula").cd do
  r, io = IO.pipe

  fork do
    system("git", "log", "--name-only", "--pretty=format:%aI", "-n #{max_commits}",
           out: io)
  end
  io.close

  curr_day = nil
  last_updates = {}

  r.each_line do |line|
    if curr_day.nil?
      curr_day = line.strip.split("T", 2)[0]
      next
    end

    if line.strip.empty?
      curr_day = nil
      next
    end

    next unless line.start_with? "Formula/"
    formula = line.strip.sub "Formula/", ""
    last_updates[formula] ||= curr_day
  end

  top = last_updates.sort_by(&:last).slice(0, top_size+1)
  max_size = top.map(&:first).map(&:length).max
  # "YYYY-MM-DD:".length = 11
  line_format = "%11s %-#{max_size}s"

  prev_day = nil

  top.each do |(formula, day)|
    if day == prev_day
      day = ""
    else
      prev_day = day
      day = "#{day}:"
    end

    puts format(line_format, day, formula)
  end
end

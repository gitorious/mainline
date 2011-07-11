require File.join(File.dirname(__FILE__), "../gitorious")

def each_version
  pattern = /^v(\d+\.\d+\.\d+)/

  `#{ENV["GIT"] || "git"} tag -n`.split("\n").reverse.each do |line|
    next unless line =~ pattern
    nothing, version, *description = line.split(pattern)
    yield version, description.join
  end
end

def list_versions
  puts "\nAvailable versions"
  newest = true

  each_version do |version, description|
    color = newest ? "32" : "31"
    newest = false

    if Gitorious::VERSION == version
      print "-> \033[1m\033[#{color}mv#{version}\033[0m"
    else
      print "   v#{version}"
    end

    puts "    #{description}"
  end
end

def describe_version(version)
  puts "\nChanges between v#{Gitorious::VERSION} and v#{version}:"

  each_version do |v, description|
    next if v <= Gitorious::VERSION || v > version
    puts v
    puts `#{ENV['GIT'] || 'git'} tag -l v#{v} -n9999`.split("\n")[2..-1].join("\n")
  end
end

desc "Show current and available Gitorious versions and details about individual versions"
task :changelog do
  system("#{ENV['GIT'] || 'git'} fetch git://gitorious.org/gitorious/mainline.git 2> /dev/null")

  if ENV["VERSION"]
    describe_version(ENV["VERSION"])
  else
    list_versions
  end
end

def rm_f(path)
  raise 'aa'
  Dir.glob(Rails.root + path).each do |file|
    puts file if ENV["VERBOSE"]
    `rm -f #{file}`
  end
end

namespace :assets do
  desc "Clear cached assets"
  task :clear do
    rm_f("public/stylesheets/gts-*.css")
    rm_f("public/stylesheets/all.css")
    rm_f("public/javascripts/gts-*.js")
    rm_f("public/javascripts/all.js")
    rm_f("public/**/*/gts-*.*")
    puts "Removed generated stylesheets and javascripts"
  end
end

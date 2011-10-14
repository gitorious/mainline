namespace :assets do
  desc "Clear cached assets"
  task :clear do
    glob = File.expand_path(RAILS_ROOT + "/public/stylesheets/gts-*.css")
    `rm -f #{glob}`
    glob = File.expand_path(RAILS_ROOT + "/public/javascripts/gts-*.js")
    `rm -f #{glob}`
    puts "Removed generated stylesheets and javascripts"
  end
end

namespace :stylesheets do
  desc "Clear cached stylesheets"
  task :clear_cache do
    glob = File.expand_path(RAILS_ROOT + "/public/stylesheets/gts-*.css")
    `rm -f #{glob}`
    puts "Removed generated CSS files"
  end
end

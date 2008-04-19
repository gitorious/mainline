
current_dir = File.expand_path(File.dirname(__FILE__))
app_root = File.join(current_dir, "../../")

print "=> Wait... "
$stdout.flush
ENV["RAILS_ENV"] ||= "production"
require File.join(app_root,"/config/environment")

puts "[OK]"

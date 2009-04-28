# There is a bug in Rack causing multipart form posts to fail under Ruby 1.9
# Discussion on the Rack mailing list:
#   http://groups.google.com/group/rack-devel/browse_thread/thread/099628ed37ac5f5b
# Discussion on the Rails lighthouse:
#   https://rails.lighthouseapp.com/projects/8994-ruby-on-rails/tickets/2497
# 
# If we are on 1.9, let's load up the patch from lib. Since this patch has to replace an entire class from 
# Rack, we will explode if the Rack version isn't 1.0 - which is what it's intended for
# 
# If this happens to you, please verify that the code is in fact correct
if RUBY_VERSION >= '1.9'
  if Rack.version > '1.0'
    raise "Gitorious bundles a patch to Rack which has not been tested on Rack after version 1.0. Please consult RAILS_ROOT/config/intitalizers/rack_patch.rb and verify if the patch is needed"
  end
  require 'rack_multipart_patch'
end
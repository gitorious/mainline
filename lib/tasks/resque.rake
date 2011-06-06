begin
  $: << File.join(File.expand_path(File.dirname(__FILE__)), "app")
  require 'resque/tasks'
rescue LoadError => err
  # Ignore in case not using Resque
end

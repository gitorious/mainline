require "gitorious/on_config"

Gitorious.on_config("resque.yml") do |settings|
  require "resque"
  Resque.redis = settings
end

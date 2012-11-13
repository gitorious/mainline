require "resque"
config_file = Rails.root + "config/resque.yml"
if config_file.exist?
  Resque.redis = YAML::load_file(config_file)[Rails.env]
end

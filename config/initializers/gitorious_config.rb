GitoriousConfig = YAML::load_file(File.join(Rails.root, 
  ENV['RAILS_ENV'] == 'test' ? "config/gitorious.sample.yml" : "config/gitorious.yml"))
if GitoriousConfig['gitorious_public_registration'].nil?
  # make the default be publicly open
  GitoriousConfig['gitorious_public_registration'] = true
end
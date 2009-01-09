GitoriousConfig = YAML::load_file(File.join(Rails.root, 
  ENV['RAILS_ENV'] == 'test' ? "config/gitorious.sample.yml" : "config/gitorious.yml"))
if GitoriousConfig['public_mode'].nil?
  # make the default be publicly open
  GitoriousConfig['public_mode'] = true
end
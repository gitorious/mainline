class CustomCallbacks
  def self.valid_user?(user)
    $stderr.puts "File"
    auth_configuration_path = Rails.root + "config/authentication.yml"
    return true unless File.exist?(auth_configuration_path)

    $stderr.puts "Read"
    auth_config = YAML::load_file(auth_configuration_path)
    return true unless auth_config["custom_user_check_callback"]

    $stderr.puts "Constantize"
    klass = auth_config["custom_user_check_callback"].constantize
    return true unless klass.respond_to?(:valid_user?)
    
    $stderr.puts "Check valid"
    return true if klass.valid_user?(user)
    
    return false
  end
end

require "action_controller/resources"

module ResourcePaths
  def self.included(base)
    base.alias_method_chain :initialize, :path_name
  end
      
  def initialize_with_path_name(*args)
    initialize_without_path_name(*args)
    set_path_name
  end
  
  protected
  def set_path_name
    @path = options[:path_name] ? "#{path_prefix}/#{options[:path_name]}" : nil
  end
end

ActionController::Resources::Resource.send(:include, ResourcePaths)
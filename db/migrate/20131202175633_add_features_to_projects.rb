class AddFeaturesToProjects < ActiveRecord::Migration
  def change
    default_value = [].to_yaml
    add_column :projects, :features, :string, :default => default_value, :null => false
    execute "UPDATE projects SET features = '#{default_value}'"
  end
end

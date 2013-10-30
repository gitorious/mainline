class AddTypeAndDataToWebHooks < ActiveRecord::Migration
  def up
    add_column :hooks, :service_type, :string, null: false, default: 'web_hook'
    add_column :hooks, :data, :text, null: false

    data_template = {url: "<URL>"}.to_yaml
    execute <<-SQL
      UPDATE hooks SET data = REPLACE(#{data_template.inspect}, "<URL>", url);
    SQL

    remove_column :hooks, :url
    rename_table :hooks, :services
  end

  def down
    rename_table :services, :hooks
    add_column :hooks, :url, :string
    remove_column :hooks, :service_type
    remove_column :hooks, :data
  end
end

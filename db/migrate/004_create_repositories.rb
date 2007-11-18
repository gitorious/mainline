class CreateRepositories < ActiveRecord::Migration
  def self.up
    create_table :repositories do |t|
      t.string  :name
      t.integer :project_id
      t.integer :user_id

      t.timestamps
    end
    add_index :repositories, :name
    add_index :repositories, :project_id
    add_index :repositories, :user_id
  end

  def self.down
    drop_table :repositories
  end
end

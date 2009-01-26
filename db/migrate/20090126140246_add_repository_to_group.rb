class AddRepositoryToGroup < ActiveRecord::Migration
  def self.up
    transaction do
      add_column :repositories, :owner_type, :string
      add_column :repositories, :owner_id, :integer
      add_index :repositories, [:owner_type, :owner_id]
    end
  end

  def self.down
    transaction do
      remove_column :repositories, :owner_type
      remove_column :repositories, :owner_id
    end
  end
end

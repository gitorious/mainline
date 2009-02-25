class CreateEmails < ActiveRecord::Migration
  def self.up
    create_table :emails do |t|
      t.integer :user_id
      t.string :address
      t.string :aasm_state
      t.string :confirmation_code
      t.timestamps
    end
    add_index :emails, :user_id
    add_index :emails, :address
  end

  def self.down
    drop_table :emails
  end
end

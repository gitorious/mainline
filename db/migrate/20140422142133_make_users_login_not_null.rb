class MakeUsersLoginNotNull < ActiveRecord::Migration
  def up
    execute "UPDATE users SET login = CONCAT('user-', id) WHERE login = '' OR login IS NULL"
    change_column :users, :login, :string, null: false
  end

  def down
    change_column :users, :login, :string, null: true
  end
end

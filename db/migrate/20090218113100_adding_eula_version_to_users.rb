class AddingEulaVersionToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :accepted_license_agreement_version, :string
  end

  def self.down
    remove_column :users, :accepted_license_agreement_version
  end
end

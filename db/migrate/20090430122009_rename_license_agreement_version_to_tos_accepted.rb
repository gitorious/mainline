class RenameLicenseAgreementVersionToTosAccepted < ActiveRecord::Migration
  def self.up
    remove_column :users, :accepted_license_agreement_version
    add_column :users, :terms_of_use, :boolean, :default => false
  end

  def self.down
    rename_column :users, :terms_of_use, :accepted_license_agreement_version
    change_column :users, :accepted_license_agreement_version, :string
  end
end

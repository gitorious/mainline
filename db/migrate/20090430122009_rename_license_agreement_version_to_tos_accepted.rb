class RenameLicenseAgreementVersionToTosAccepted < ActiveRecord::Migration
  def self.up
    rename_column :users, :accepted_license_agreement_version, :terms_of_use
    change_column :users, :terms_of_use, :boolean
    User.update_all(["terms_of_use = ?", false])
  end

  def self.down
    rename_column :users, :terms_of_use, :accepted_license_agreement_version
    change_column :users, :accepted_license_agreement_version, :string
  end
end

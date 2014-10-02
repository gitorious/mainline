unless Role.count > 0
  Role.create!(:name => Role::ADMIN, :kind => Role::KIND_ADMIN)
  Role.create!(:name => Role::MEMBER, :kind => Role::KIND_MEMBER)
end

unless User.count > 0
  hostname = ENV["GITORIOUS_HOSTNAME"] || `hostname`.strip

  user = User.create!(
    login: "admin",
    password: "g1torious",
    password_confirmation: "g1torious",
    email: "admin@#{hostname}",
    is_admin: true,
    terms_of_use: true,
    activated_at: Time.now,
    activation_code: nil
  )
  user.accept_terms!
end

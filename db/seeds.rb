# NOTE: all operations below *HAVE TO* be idempotent to allow re-seeding existing databases

Role.where(kind: Role::KIND_ADMIN).first_or_create!(name: Role::ADMIN)
Role.where(kind: Role::KIND_MEMBER).first_or_create!(name: Role::MEMBER)

hostname = ENV["GITORIOUS_HOSTNAME"] || `hostname`.strip
admin = User.where(login: "admin").first_or_create!(
  login: "admin",
  password: "g1torious",
  password_confirmation: "g1torious",
  email: "admin@#{hostname}",
  is_admin: true,
  terms_of_use: true,
  activated_at: Time.now,
  activation_code: nil
)
admin.accept_terms!
